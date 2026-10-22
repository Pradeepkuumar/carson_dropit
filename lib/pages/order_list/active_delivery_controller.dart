import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart'
    hide Marker;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signature/signature.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../apis/base_api_response.dart';
import '../../app_pages/app_pages.dart';
import '../../firebase_notifications/firebase_notifiction_controller.dart';
import '../../global/cancelled_orders.dart';
import '../../global/consts.dart';
import '../../global/global.dart';
import '../../global/order_delivered_dialog.dart';
import '../../local_db/entity/UserData.dart';
import '../../utils/colors.dart';
import '../dashboard/controller/rider_dashboard_controller.dart';
import '../my_orders/orders/models/orders_model.dart';
import '../my_orders/orders/models/reason_data.dart';

// A status update is only allowed once the rider is physically close to
// the relevant pickup/drop-off location - same rule the older multi-order
// map screen (AllOrdersMapController) enforces.
const double kMaxUpdateDistanceMeters = 300;

class ActiveDeliveryController extends GetxController {
  late OrdersData order;
  var user = UserData();
  GoogleMapViewController? mapViewController;
  StreamSubscription<Position>? _riderSubscription;

  // All of the rider's other currently-assigned orders (same statuses the
  // dashboard/order-list already fetch), as returned by the API - kept in
  // that original sequence so "next order" below has a stable order to
  // advance through, independent of whatever screen the rider arrived from.
  List<OrdersData> _allAssignedOrders = [];

  // Other assigned orders to suggest alongside the one on screen: orders
  // within kMaxUpdateDistanceMeters of this order's pickup if any exist,
  // otherwise every other assigned order (so the strip still helps the
  // rider jump around when nothing happens to be nearby). Index 0 is
  // always the order currently on screen. Empty when this is the rider's
  // only assigned order.
  List<OrdersData> pickupSuggestions = [];
  bool pickupSuggestionsAreNearby = false;

  // Set when this screen is opened without a specific order (the bottom
  // nav's "Active Order" tab no longer looks one up itself) - true until the
  // assigned-orders fetch below resolves and picks the first one.
  bool isLoadingOrder = false;
  bool noOrdersAvailable = false;
  // After a finished order's result dialog: true while the assigned-orders
  // list is re-fetched to pick the next one.
  bool isLoadingNextOrder = false;
  // noOrdersAvailable reached by finishing the last order (shows "All done")
  // rather than by opening the screen with nothing assigned.
  bool finishedAllOrders = false;

  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  File? packagePhoto;
  File? deliveryPhoto;
  File? signatureFile;
  File? undeliveredPhoto;
  var isSubmitting = false.obs;

  var reasonsList = <CancelReason>[].obs;
  var selectedReasonId = Rxn<int>();
  String? _selectedUndeliveredReason;

  // Call tracking - mirrors AllOrdersMapController's hasOngoingCall/callType
  // split (the timer itself is owned by the view, same as there).
  bool hasOngoingCall = false;
  String? callType; // 'pickup' or 'consignee'

  // Buffer wait after arriving at pickup - same rule AllOrdersMapController
  // enforces via the server-given pickup_buffer_time_in_minutes.
  bool bufferWaitActive = false;

  // Payment link flow - set once the rider opens or shares the link, so the
  // order is re-checked when the app comes back to the foreground.
  bool paymentLinkSent = false;
  bool isCheckingPayment = false;
  bool _awaitingPaymentReturn = false;

  // Order-cancelled handling - a foreground OrderCancelled push for the
  // order on screen, or the order found cancelled when the app resumes.
  Worker? _cancelWorker;
  // Key of the order the cancelled dialog was already shown for, so the
  // push and the resume check never show it twice.
  String? _cancelHandledKey;
  // A cancel that arrived mid status update - handled once it finishes, so
  // the update's loading-dialog close can't pop the cancelled dialog.
  String? _pendingCancelReason;
  bool _hasPendingCancel = false;
  bool _isCheckingCancelled = false;

  @override
  void onInit() {
    final passedOrder = Get.arguments is OrdersData
        ? Get.arguments as OrdersData
        : null;
    order = passedOrder ?? OrdersData();
    isLoadingOrder = passedOrder == null;
    if (passedOrder != null &&
        order.status == REACHED &&
        pickupBufferSeconds > 0) {
      bufferWaitActive = true;
    }
    getReasons();
    userRepository.getUser().then((value) {
      if (value != null) user = value;
      _fetchAssignedOrders(autoSelectFirst: passedOrder == null);
    });
    if (Get.isRegistered<FirebaseMessagingController>()) {
      _cancelWorker = ever(
        Get.find<FirebaseMessagingController>().onOrderCancelled,
        (Map<String, dynamic>? data) {
          if (data != null) _onOrderCancelledPush(data);
        },
      );
    }
    super.onInit();
  }

  @override
  void onClose() {
    _cancelWorker?.dispose();
    _riderSubscription?.cancel();
    signatureController.dispose();
    super.onClose();
  }

  bool get isCod => (order.paymentType ?? "").toLowerCase() == "cod" || (order.paymentType ?? "").toLowerCase() == "split_payment";

  // Split payment: half is prepaid, the other half is collected as COD.
  bool get isSplitPayment =>
      (order.paymentType ?? "").toLowerCase() == "split_payment";

  // Amount the rider collects from the customer - the full order amount for
  // COD, half of it for split payment. Whole numbers render without decimals.
  String get codAmountToCollect {
    final total = double.tryParse(order.orderAmount ?? "") ?? 0;
    final amount = isSplitPayment ? total  : total;
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  // The customer paid this COD/split order online through the payment link.
  bool get isPaymentCompleted => order.paymentCompleted == true;

  // Payment link options are offered on a COD/split order that has a link
  // and hasn't been paid yet.
  bool get hasPaymentLink =>
      isCod &&
      !isTerminal &&
      !isPaymentCompleted &&
      (order.paymentLink ?? "").trim().isNotEmpty;

  // Step 4 primary button is locked after the link was sent until the
  // payment is confirmed (cash is still reachable from the payment sheet).
  bool get isDeliveryLockedForPayment =>
      currentStep == 4 && hasPaymentLink && paymentLinkSent;

  Future<void> openPaymentLink() async {
    final uri = Uri.tryParse((order.paymentLink ?? "").trim());
    if (uri == null) return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception();
      _markPaymentLinkSent();
    } catch (_) {
      utils.errorSnackBar("Link error", "Could not open the payment link.");
    }
  }

  Future<void> sharePaymentLink() async {
    final link = (order.paymentLink ?? "").trim();
    if (link.isEmpty) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text:
              "Your Zyppy order ${order.awbNo ?? ""} is out for delivery. "
              "Pay QAR $codAmountToCollect here: $link",
        ),
      );
      _markPaymentLinkSent();
    } catch (_) {
      utils.errorSnackBar("Share error", "Could not share the payment link.");
    }
  }

  // Payment sheet closed after showing the scan-to-pay QR. The rider never
  // left the app, so there's no foreground-return re-check to arm.
  void markPaymentLinkShown() {
    if (paymentLinkSent) return;
    paymentLinkSent = true;
    update();
  }

  void _markPaymentLinkSent() {
    paymentLinkSent = true;
    _awaitingPaymentReturn = true;
    update();
  }

  // Called by the screen when the app returns to the foreground.
  void onAppResumed() {
    _checkOrderCancelledOnResume();
    if (!_awaitingPaymentReturn) return;
    _awaitingPaymentReturn = false;
    refreshPaymentStatus();
  }

  // Re-fetches the assigned orders and copies this order's payment fields
  // across, keeping the captured evidence on screen.
  Future<void> refreshPaymentStatus() async {
    if (isCheckingPayment) return;
    isCheckingPayment = true;
    update();
    try {
      final orders = await _requestAssignedOrders();
      final key = _orderKey(order);
      final match = orders?.where((o) => _orderKey(o) == key);
      if (match == null || match.isEmpty) {
        utils.errorSnackBar(
          "Payment status",
          "Could not check the payment status. Try again.",
        );
        return;
      }
      final fresh = match.first;
      order.paymentLink = fresh.paymentLink;
      order.paymentCompleted = fresh.paymentCompleted;
      if (isPaymentCompleted) {
        utils.successSnackBar(
          "Payment received",
          "You can deliver the order.",
        );
      } else {
        utils.errorSnackBar(
          "Payment pending",
          "Payment not received yet. Ask the customer to finish paying, then refresh.",
        );
      }
    } catch (_) {
      utils.errorSnackBar(
        "Payment status",
        "Could not check the payment status. Try again.",
      );
    } finally {
      isCheckingPayment = false;
      update();
    }
  }

  // 1 = confirm arrival at pickup, 2 = confirm pickup collected,
  // 3 = start delivery, 4 = confirm delivery, 5 = delivered/terminal.
  int get currentStep {
    switch (order.status) {
      case ASSIGNED:
      case RE_ASSIGNED:
        return 1;
      case REACHED:
        return 2;
      case PICKED:
      // Failed at pickup - the step tracker marks "Collected" as failed.
      case NOT_PICKED:
        return 3;
      case OFD:
        return 4;
      default:
        return 5;
    }
  }

  bool get isPickupPhase => currentStep <= 2;
  bool get isDelivered => order.status == DELIVERED;
  bool get isUndelivered => order.status == UNDELIVERED;
  bool get isNotPicked => order.status == NOT_PICKED;
  // Any failed end state - undelivered at drop-off or not picked at pickup.
  bool get isFailed => isUndelivered || isNotPicked;
  bool get isTerminal => isDelivered || isFailed;

  String get nextStopName => isPickupPhase
      ? (order.merchantName ?? "-")
      : (order.consigneeName ?? "-");

  String get nextStopAddress => isPickupPhase
      ? (order.pickupLocationName ?? order.pickupAddress ?? "-")
      : (order.consigneeAddress ?? "-");

  String get nextStopDistance =>
      (isPickupPhase
          ? (order.current_pickup_distance ?? order.distance)
          : (order.current_dropoff_distance ?? order.distance)) ??
      "-";

  String get nextStopEta =>
      (isPickupPhase
          ? (order.current_pickup_duration ?? order.duration)
          : (order.current_dropoff_duration ?? order.duration)) ??
      "-";

  int get pickupBufferSeconds =>
      (int.tryParse(order.pickup_buffer_time_in_minutes ?? '') ?? 0) * 60;

  bool get showPickupBuffer =>
      currentStep == 2 && bufferWaitActive && pickupBufferSeconds > 0;

  void onPickupBufferComplete() {
    bufferWaitActive = false;
    update();
  }

  double? get _destLat => double.tryParse(
    (isPickupPhase ? order.pickupLatitude : order.dropoffLatitude) ?? "",
  );
  double? get _destLng => double.tryParse(
    (isPickupPhase ? order.pickupLongitude : order.dropoffLongitude) ?? "",
  );

  LatLng? get destLatLng {
    final lat = _destLat, lng = _destLng;
    if (lat == null || lng == null) return null;
    return LatLng(latitude: lat, longitude: lng);
  }

  LatLng? get pickupLatLng =>
      utils.parseLatLng(order.pickupLatitude, order.pickupLongitude);

  LatLng? get dropoffLatLng =>
      utils.parseLatLng(order.dropoffLatitude, order.dropoffLongitude);

  Future<void> onMapViewCreated(GoogleMapViewController controller) async {
    mapViewController = controller;
    final pickup = pickupLatLng;
    final dropoff = dropoffLatLng;

    final markerOptions = <MarkerOptions>[
      if (pickup != null)
        MarkerOptions(
          position: pickup,
          icon: await utils.mapDotMarker(AppColors.red),
        ),
      if (dropoff != null)
        MarkerOptions(
          position: dropoff,
          icon: await utils.mapDotMarker(AppColors.greenLight),
        ),
    ];
    if (markerOptions.isNotEmpty) {
      await controller.addMarkers(markerOptions);
    }

    if (pickup != null && dropoff != null) {
      await utils.drawMapRoute(controller, pickup, dropoff);
    }

    // Rider's live position as the bike marker (replaces the blue dot).
    await _riderSubscription?.cancel();
    final rider = await utils.showRiderBikeOnMap(controller);
    _riderSubscription = rider.subscription;

    if (pickup != null && dropoff != null) {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          utils.mapBoundsFor([pickup, dropoff, ?rider.position]),
          padding: 60,
        ),
      );
    } else if (destLatLng != null) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(destLatLng!, 15),
      );
    }
  }

  // Opens full in-app turn-by-turn guidance (Google Navigation SDK) instead
  // of handing off to the external Google Maps app. On arrival (or manual
  // exit), TurnByTurnNavigationScreen pops back with whether the rider
  // actually arrived - if so, nudge them toward the next step rather than
  // auto-advancing it ourselves.
  Future<void> openNavigation() async {
    final lat = _destLat, lng = _destLng;
    if (lat == null || lng == null) return;
    final arrived = await Get.toNamed(
      Routes.turnByTurnNavigation,
      arguments: {
        'title': nextStopName,
        'destination': LatLng(latitude: lat, longitude: lng),
      },
    );
    if (arrived == true) {
      utils.successSnackBar(
        "You've arrived",
        "Tap the button below to continue.",
      );
    }
  }

  void startCall(String type) {
    hasOngoingCall = true;
    callType = type;
    update();
  }

  void endCall() {
    hasOngoingCall = false;
    callType = null;
    update();
  }

  Future<void> logCall({
    required String status,
    required String duration,
  }) async {
    try {
      await apiProvider.postRequest(apiEndPoints.driverCallLog, {
        'fe_code': order.feCode,
        'awb_no': order.awbNo,
        'call_type': callType,
        'customer_phone': callType == 'pickup'
            ? order.pickupPhoneNo
            : order.consigneeMobileNo,
        'status': status,
        'duration': duration,
      });
    } catch (e) {
      debugPrint('Error logging call: $e');
    }
  }

  Future<void> capturePackagePhoto() async {
    final file = await utils.pickImage(ImageSource.camera);
    if (file != null) packagePhoto = file;
    update();
  }

  Future<void> captureDeliveryPhoto() async {
    final file = await utils.pickImage(ImageSource.camera);
    if (file != null) deliveryPhoto = file;
    update();
  }

  Future<void> captureUndeliveredPhoto() async {
    final file = await utils.pickImage(ImageSource.camera);
    if (file != null) undeliveredPhoto = file;
    update();
  }

  Future<void> captureSignature() async {
    if (signatureController.isEmpty) return;
    final bytes = await signatureController.toPngBytes(width: 500, height: 500);
    if (bytes == null) return;
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/signature_${order.awbNo}.png');
    await file.writeAsBytes(bytes);
    // Same path on every save - drop the cached image so a re-signed
    // signature shows instead of the old one.
    await FileImage(file).evict();
    signatureFile = file;
    update();
  }

  void clearSignature() {
    signatureController.clear();
    signatureFile = null;
    update();
  }

  bool get evidenceComplete =>
      packagePhoto != null && deliveryPhoto != null && signatureFile != null;

  String get primaryActionLabel {
    switch (currentStep) {
      case 1:
        return "Confirm arrival at pickup";
      case 2:
        return "Confirm pickup";
      case 3:
        return "Start delivery";
      case 4:
        return hasPaymentLink && !paymentLinkSent
            ? "Collect payment"
            : "Confirm delivery";
      default:
        return "";
    }
  }

  IconData get primaryActionIcon {
    switch (currentStep) {
      case 1:
        return Icons.location_on_outlined;
      case 2:
        return Icons.inventory_2_outlined;
      case 3:
        return Icons.local_shipping_outlined;
      case 4:
        if (isDeliveryLockedForPayment) return Icons.lock_outline;
        return hasPaymentLink ? Icons.payments_outlined : Icons.check_circle_outline;
      default:
        return Icons.check_circle_outline;
    }
  }

  // cashCollected: the rider confirmed cash from the payment sheet, which
  // bypasses the payment-link lock.
  Future<void> confirmPrimaryAction({bool cashCollected = false}) async {
    if (isDeliveryLockedForPayment && !cashCollected) {
      utils.errorSnackBar(
        "Payment pending",
        "Refresh the payment status once the customer has paid.",
      );
      return;
    }
    switch (currentStep) {
      case 1:
        if (!await _isWithinUpdateRange()) return;
        final reached = await _updateStatus(REACHED);
        if (reached && pickupBufferSeconds > 0) {
          bufferWaitActive = true;
          update();
        }
        break;
      case 2:
        if (!await _isWithinUpdateRange()) return;
        await _updateStatus(PICKED);
        break;
      case 3:
        await _updateStatus(OFD);
        break;
      case 4:
        if (!await _isWithinUpdateRange()) return;
        if (!evidenceComplete) {
          utils.errorSnackBar(
            "Evidence required",
            "Capture package photo, delivery photo and signature first.",
          );
          return;
        }
        await _updateStatus(DELIVERED);
        break;
    }
  }

  // ---------------------------------------------------------------------
  // Nearby-pickup suggestions + switching between assigned orders without
  // leaving this screen, so a rider collecting several orders from the
  // same/nearby merchant doesn't have to back out to the order list and
  // reopen each one individually.
  // ---------------------------------------------------------------------
  String _orderKey(OrdersData model) =>
      model.awbNo ?? model.orderRefNumber ?? model.id?.toString() ?? '';

  // First order flagged is_active_priority in a list, if any - the rider
  // must clear a priority order before touching anything else, so this
  // gates both which order is shown and whether switching is offered.
  OrdersData? _priorityOrderIn(List<OrdersData> orders) {
    for (final o in orders) {
      if (o.isPriorityOrder) return o;
    }
    return null;
  }

  // autoSelectFirst is true when this screen was opened without a specific
  // order - once the fetch resolves, `order` becomes the first one returned
  // (or noOrdersAvailable is set if the rider has none assigned at all).
  // The rider's currently-active orders from the API, in API order, or null
  // if the request failed.
  Future<List<OrdersData>?> _requestAssignedOrders() async {
    final model = <String, dynamic>{
      apiKeys.feCode: order.feCode ?? user.code,
      apiKeys.status: [ASSIGNED, RE_ASSIGNED, PICKED, OFD, REACHED],
    };
    final response = await apiProvider.postRequest(
      apiEndPoints.driverFetchOrderList,
      model,
    );
    final result = BaseApiResponse.fromJson(response);
    if (result.status_code == 200 && result.data != null) {
      return (result.data as List)
          .map((json) => OrdersData.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  Future<void> _fetchAssignedOrders({bool autoSelectFirst = false}) async {
    try {
      final orders = await _requestAssignedOrders();
      if (orders != null) {
        _allAssignedOrders = orders;
        final priorityOrder = _priorityOrderIn(_allAssignedOrders);
        if (autoSelectFirst) {
          final initial =
              priorityOrder ??
              (_allAssignedOrders.isNotEmpty ? _allAssignedOrders.first : null);
          if (initial != null) {
            order = initial;
            if (order.status == REACHED && pickupBufferSeconds > 0) {
              bufferWaitActive = true;
            }
          } else {
            noOrdersAvailable = true;
          }
          isLoadingOrder = false;
          _recomputePickupSuggestions();
          update();
        } else {
          _recomputePickupSuggestions();
          update();
          // A specific order was opened directly, but a different one is
          // flagged priority - jump to the priority order instead of
          // leaving the rider on a lower-priority one.
          if (priorityOrder != null &&
              _orderKey(priorityOrder) != _orderKey(order)) {
            await switchToOrder(priorityOrder);
          }
        }
      } else if (autoSelectFirst) {
        noOrdersAvailable = true;
        isLoadingOrder = false;
        update();
      }
    } catch (_) {
      // Leave pickupSuggestions empty - the strip just doesn't show.
      if (autoSelectFirst) {
        noOrdersAvailable = true;
        isLoadingOrder = false;
        update();
      }
    }
  }

  void _recomputePickupSuggestions() {
    if (_priorityOrderIn(_allAssignedOrders) != null) {
      // A priority order exists somewhere in the assigned list - hide the
      // switcher entirely (nothing else should be selectable) until it's
      // cleared, rather than just excluding it from the choices.
      pickupSuggestions = [order];
      pickupSuggestionsAreNearby = false;
      return;
    }
    final currentKey = _orderKey(order);
    final others = _allAssignedOrders
        .where((o) => _orderKey(o) != currentKey)
        .toList();
    if (others.isEmpty) {
      pickupSuggestions = [];
      pickupSuggestionsAreNearby = false;
      return;
    }

    final originLat = double.tryParse(order.pickupLatitude ?? '');
    final originLng = double.tryParse(order.pickupLongitude ?? '');
    final nearby = <MapEntry<OrdersData, double>>[];
    if (originLat != null && originLng != null) {
      for (final o in others) {
        final lat = double.tryParse(o.pickupLatitude ?? '');
        final lng = double.tryParse(o.pickupLongitude ?? '');
        if (lat == null || lng == null) continue;
        final distance = Geolocator.distanceBetween(
          originLat,
          originLng,
          lat,
          lng,
        );
        if (distance <= kMaxUpdateDistanceMeters) {
          nearby.add(MapEntry(o, distance));
        }
      }
    }

    if (nearby.isNotEmpty) {
      nearby.sort((a, b) => a.value.compareTo(b.value));
      pickupSuggestions = [order, ...nearby.map((e) => e.key)];
      pickupSuggestionsAreNearby = true;
    } else {
      // Nothing within range - fall back to every other assigned order so
      // the strip still helps instead of just disappearing.
      pickupSuggestions = [order, ...others];
      pickupSuggestionsAreNearby = false;
    }
  }

  // Label shown on each chip in the strip (not the current order, which
  // always just reads "Viewing").
  String pickupSuggestionTag(OrdersData o) {
    if (_orderKey(o) == _orderKey(order)) return "Viewing";
    if (pickupSuggestionsAreNearby) {
      final originLat = double.tryParse(order.pickupLatitude ?? '');
      final originLng = double.tryParse(order.pickupLongitude ?? '');
      final lat = double.tryParse(o.pickupLatitude ?? '');
      final lng = double.tryParse(o.pickupLongitude ?? '');
      if (originLat != null &&
          originLng != null &&
          lat != null &&
          lng != null) {
        final distance = Geolocator.distanceBetween(
          originLat,
          originLng,
          lat,
          lng,
        );
        return "${distance.round()}m away";
      }
    }
    return o.pickupLocationName ?? o.pickupAddress ?? "Nearby";
  }

  // Swaps the order this screen is driven by, resetting the per-order
  // capture/call state and redrawing the map, without navigating away.
  Future<void> switchToOrder(OrdersData next) async {
    if (_orderKey(next) == _orderKey(order)) return;
    order = next;
    _resetPerOrderState();
    update();

    final mapController = mapViewController;
    if (mapController != null) {
      await mapController.clearMarkers();
      await mapController.clearPolylines();
      await onMapViewCreated(mapController);
    }
  }

  // Per-order capture/call state - cleared whenever a different order takes
  // over the screen.
  void _resetPerOrderState() {
    packagePhoto = null;
    deliveryPhoto = null;
    signatureFile = null;
    undeliveredPhoto = null;
    signatureController.clear();
    selectedReasonId.value = null;
    hasOngoingCall = false;
    callType = null;
    paymentLinkSent = false;
    isCheckingPayment = false;
    _awaitingPaymentReturn = false;
    bufferWaitActive = order.status == REACHED && pickupBufferSeconds > 0;
  }

  // Called from the result dialog's "Continue" after an order is delivered,
  // undelivered or not picked: re-fetches the assigned-orders list from the
  // API (so it reflects the server, not the list cached when the screen
  // opened) and opens the next order - a priority order first, otherwise the
  // one after the finished order in API sequence. With nothing left, shows
  // the "All done" state instead of closing the screen.
  Future<void> loadNextOrder() async {
    final completedKey = _orderKey(order);
    final previousKeys = _allAssignedOrders.map(_orderKey).toList();
    isLoadingNextOrder = true;
    // The loading state replaces the map, disposing its platform view - the
    // next order's map registers a fresh controller via onMapViewCreated.
    mapViewController = null;
    update();

    List<OrdersData>? fresh;
    try {
      fresh = await _requestAssignedOrders();
    } catch (_) {
      fresh = null;
    }
    // On a failed request, fall back to the cached list minus this order.
    _allAssignedOrders = (fresh ?? _allAssignedOrders)
        .where((o) => _orderKey(o) != completedKey)
        .toList();
    isLoadingNextOrder = false;

    if (_allAssignedOrders.isEmpty) {
      noOrdersAvailable = true;
      finishedAllOrders = true;
      pickupSuggestions = [];
      update();
      return;
    }

    OrdersData? next = _priorityOrderIn(_allAssignedOrders);
    if (next == null) {
      final completedIndex = previousKeys.indexOf(completedKey);
      if (completedIndex != -1) {
        for (final key in previousKeys.skip(completedIndex + 1)) {
          final match = _allAssignedOrders.where((o) => _orderKey(o) == key);
          if (match.isNotEmpty) {
            next = match.first;
            break;
          }
        }
      }
    }
    order = next ?? _allAssignedOrders.first;
    _resetPerOrderState();
    _recomputePickupSuggestions();
    update();
  }

  // "Refresh" on the empty / all-done state - asks the API again in case a
  // new order has been assigned since.
  Future<void> refreshAssignedOrders() async {
    isLoadingOrder = true;
    noOrdersAvailable = false;
    finishedAllOrders = false;
    mapViewController = null;
    update();
    await _fetchAssignedOrders(autoSelectFirst: true);
    if (!noOrdersAvailable) {
      _resetPerOrderState();
      update();
    }
  }

  // ---------------------------------------------------------------------
  // Order cancelled while the rider is on it
  // ---------------------------------------------------------------------
  // The order on screen is one the rider is still working through - not
  // loading, not the empty state, and not already finished.
  bool get _hasLiveOrder =>
      !isLoadingOrder &&
      !isLoadingNextOrder &&
      !noOrdersAvailable &&
      !isTerminal &&
      _orderKey(order).isNotEmpty;

  void _onOrderCancelledPush(Map<String, dynamic> data) {
    final ref = (data['awb_number'] ?? data['awb_no'] ?? '').toString();
    if (ref.isEmpty) return;
    final reason = (data['reason'] ?? data['cancel_reason'])?.toString();

    if (_hasLiveOrder && ref == (order.awbNo ?? _orderKey(order))) {
      _handleCurrentOrderCancelled(reason);
      return;
    }

    // One of the rider's other assigned orders - just drop it from the
    // switcher, no popup.
    final before = _allAssignedOrders.length;
    _allAssignedOrders = _allAssignedOrders
        .where((o) => (o.awbNo ?? _orderKey(o)) != ref)
        .toList();
    if (_allAssignedOrders.length != before) {
      _recomputePickupSuggestions();
      update();
    }
  }

  // App back in the foreground - a cancel push that arrived while it was in
  // the background never reached _onOrderCancelledPush, so ask the API.
  Future<void> _checkOrderCancelledOnResume() async {
    if (_isCheckingCancelled || !_hasLiveOrder) return;
    final awb = order.awbNo ?? '';
    if (awb.isEmpty || _cancelHandledKey == _orderKey(order)) return;
    _isCheckingCancelled = true;
    try {
      final fresh = await fetchDriverOrder(awb, user.code ?? "");
      // The rider may have moved on to another order while this ran.
      if (fresh?.status == CANCELED && _hasLiveOrder && order.awbNo == awb) {
        _handleCurrentOrderCancelled(fresh!.reason);
      }
    } finally {
      _isCheckingCancelled = false;
    }
  }

  void _handleCurrentOrderCancelled(String? reason) {
    final key = _orderKey(order);
    if (_cancelHandledKey == key) return;
    if (isSubmitting.value) {
      _hasPendingCancel = true;
      _pendingCancelReason = reason;
      return;
    }
    _cancelHandledKey = key;
    markCancellationNotified(order.awbNo ?? key);
    order.status = CANCELED;
    if ((reason ?? '').trim().isNotEmpty) order.reason = reason;
    hasOngoingCall = false;
    callType = null;
    _awaitingPaymentReturn = false;

    // Close whatever is on top of this screen - bottom sheets, dialogs and
    // the turn-by-turn navigation route - so the dialog lands here.
    Get.until(
      (route) =>
          route.settings.name == Routes.activeDeliveryScreen || route.isFirst,
    );
    update();
    showOrderCancelledDialog(
      order: order,
      reason: reason,
      onContinue: loadNextOrder,
    );
  }

  // ---------------------------------------------------------------------
  // 300m proximity gate - same rule AllOrdersMapController enforces, so a
  // status update can't be sent from far away from the actual stop.
  // ---------------------------------------------------------------------
  Future<bool> _isWithinUpdateRange() async {
    final dest = destLatLng;
    if (dest == null) return true; // no coordinates to check against

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        !await Geolocator.isLocationServiceEnabled()) {
      utils.errorSnackBar(
        "Location required",
        "Enable location access to update this order.",
      );
      return false;
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      utils.errorSnackBar(
        "Location required",
        "Could not get your current location.",
      );
      return false;
    }

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      dest.latitude,
      dest.longitude,
    );
    if (distance > kMaxUpdateDistanceMeters) {
      utils.errorSnackBar(
        "Too far away",
        "You need to be within ${kMaxUpdateDistanceMeters.toInt()}m of the "
            "${isPickupPhase ? 'pickup' : 'drop-off'} location to update this order.",
      );
      return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------
  // Undelivered flow
  // ---------------------------------------------------------------------
  Future<void> getReasons() async {
    try {
      final response = await apiProvider.getRequest(apiEndPoints.getReasons);
      final result = BaseApiResponse.fromJson(response);
      if (result.data != null) {
        reasonsList.value = (result.data as List)
            .map((json) => CancelReason.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (ex,stackTrace) {
      print("❌ FetchAvailable Exception: $ex");
      print("❌ StackTrace: $stackTrace");
      // leave the list empty; the sheet just shows nothing to pick from
    }
  }

  void ensureReasonsLoaded() {
    if (reasonsList.isEmpty) getReasons();
  }

  void selectReason(CancelReason reason) => selectedReasonId.value = reason.id;

  Future<void> confirmUndelivered() async {
    CancelReason? reason;
    for (final r in reasonsList) {
      if (r.id == selectedReasonId.value) {
        reason = r;
        break;
      }
    }
    if (reason == null) return;
    if (undeliveredPhoto == null) return;
    if (!await _isWithinUpdateRange()) return;
    _selectedUndeliveredReason = reason.reason;
    // Step 2 (arrived at pickup) means the parcel was never collected.
    await _updateStatus(currentStep == 2 ? NOT_PICKED : UNDELIVERED);
  }

  // Short green toast confirming a step update (the order stays on screen).
  void _showStepSuccess(String status) {
    switch (status) {
      case REACHED:
        utils.successSnackBar(
          "Arrived at pickup",
          "Collect the package from the merchant",
        );
        break;
      case PICKED:
        utils.successSnackBar(
          "Package collected",
          "Start the delivery when you're ready",
        );
        break;
      case OFD:
        utils.successSnackBar(
          "Out for delivery",
          "Head to the customer's address",
        );
        break;
    }
  }

  // Failed outcomes share the issue sheet's reason + attempt photo.
  bool _isFailureStatus(String status) =>
      status == UNDELIVERED || status == NOT_PICKED;

  Future<bool> _updateStatus(String status) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    utils.showLoadingDialog("Updating...");
    try {
      final images = <Map<String, dynamic>>[
        if (status == DELIVERED && packagePhoto != null)
          {'key': 'delivery_proof', 'file': packagePhoto},
        if (status == DELIVERED && deliveryPhoto != null)
          {'key': 'delivery_proof_image_2', 'file': deliveryPhoto},
        if (status == DELIVERED && signatureFile != null)
          {'key': 'signature', 'file': signatureFile},
        if (_isFailureStatus(status) && undeliveredPhoto != null)
          {'key': 'failed_delivery_proof', 'file': undeliveredPhoto},
      ];
      print(images);
      final data = <String, dynamic>{
        'status': status,
        'fe_code': user.code ?? "",
        'awb_no': order.awbNo ?? "",
        if (_isFailureStatus(status))
          'reason': _selectedUndeliveredReason ?? "",
      };
      print(data);
      final response = await apiProvider.postRequestWithImagesDio(
        apiEndPoints.updateOrderStatus,
        data,
        images,
      );
      final result = BaseApiResponse.fromJson(response);
      utils.closeLoadingDialog();
      if (result.status_code == 200) {
        order.status = status;
        if (_isFailureStatus(status)) {
          order.reason = _selectedUndeliveredReason;
        }
        if (Get.isRegistered<RiderDashboardController>()) {
          Get.find<RiderDashboardController>().getDashBoardData();
        }
        update();
        if (status == DELIVERED) {
          showOrderDeliveredDialog(
            order: order,
            // Paid through the link - no cash was collected.
            isCod: isCod && !isPaymentCompleted,
            cashCollected: codAmountToCollect,
            onContinue: loadNextOrder,
          );
        } else if (_isFailureStatus(status)) {
          showOrderFailedDialog(
            order: order,
            notPicked: status == NOT_PICKED,
            onContinue: loadNextOrder,
          );
        } else {
          _showStepSuccess(status);
        }
        return true;
      } else {
        utils.errorSnackBar("Error", result.message.toString());
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      utils.errorSnackBar("Exception", e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
      if (_hasPendingCancel) {
        _hasPendingCancel = false;
        // Skipped if the update finished the order first - its result
        // dialog is already showing.
        if (_hasLiveOrder) _handleCurrentOrderCancelled(_pendingCancelReason);
        _pendingCancelReason = null;
      }
    }
  }
}
