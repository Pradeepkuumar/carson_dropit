import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart'
    hide Marker;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import '../../apis/base_api_response.dart';
import '../../app_pages/app_pages.dart';
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

  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  File? packagePhoto;
  File? deliveryPhoto;
  File? signatureFile;
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
    super.onInit();
  }

  @override
  void onClose() {
    signatureController.dispose();
    super.onClose();
  }

  bool get isCod => (order.paymentType ?? "").toLowerCase() == "cod";

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
  bool get isTerminal => isDelivered || isUndelivered;

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

    await _enableMyLocation(controller);

    if (pickup != null && dropoff != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          latitude: pickup.latitude < dropoff.latitude
              ? pickup.latitude
              : dropoff.latitude,
          longitude: pickup.longitude < dropoff.longitude
              ? pickup.longitude
              : dropoff.longitude,
        ),
        northeast: LatLng(
          latitude: pickup.latitude > dropoff.latitude
              ? pickup.latitude
              : dropoff.latitude,
          longitude: pickup.longitude > dropoff.longitude
              ? pickup.longitude
              : dropoff.longitude,
        ),
      );
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, padding: 60),
      );
    } else if (destLatLng != null) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(destLatLng!, 15),
      );
    }
  }

  // Shows the rider's live position as the map's native blue dot - needs
  // location permission granted (already requested elsewhere for the
  // proximity gate below), so this is a no-op if it's denied.
  Future<void> _enableMyLocation(GoogleMapViewController controller) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      await controller.setMyLocationEnabled(true);
    } catch (_) {
      // leave the map without a live location dot if this fails
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

  Future<void> captureSignature() async {
    if (signatureController.isEmpty) return;
    final bytes = await signatureController.toPngBytes(width: 500, height: 500);
    if (bytes == null) return;
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/signature_${order.awbNo}.png');
    await file.writeAsBytes(bytes);
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
        return "Confirm pickup collected";
      case 3:
        return "Start delivery";
      case 4:
        return "Confirm delivery";
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
      default:
        return Icons.check_circle_outline;
    }
  }

  Future<void> confirmPrimaryAction() async {
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

  // autoSelectFirst is true when this screen was opened without a specific
  // order - once the fetch resolves, `order` becomes the first one returned
  // (or noOrdersAvailable is set if the rider has none assigned at all).
  Future<void> _fetchAssignedOrders({bool autoSelectFirst = false}) async {
    try {
      final model = <String, dynamic>{
        apiKeys.feCode: order.feCode ?? user.code,
        apiKeys.status: [ASSIGNED, RE_ASSIGNED, PICKED, OFD],
      };
      final response = await apiProvider.postRequest(
        apiEndPoints.driverFetchOrderList,
        model,
      );
      final result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200 && result.data != null) {
        _allAssignedOrders = (result.data as List)
            .map((json) => OrdersData.fromJson(json as Map<String, dynamic>))
            .toList();
        if (autoSelectFirst) {
          if (_allAssignedOrders.isNotEmpty) {
            order = _allAssignedOrders.first;
            if (order.status == REACHED && pickupBufferSeconds > 0) {
              bufferWaitActive = true;
            }
          } else {
            noOrdersAvailable = true;
          }
          isLoadingOrder = false;
        }
        _recomputePickupSuggestions();
        update();
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
    packagePhoto = null;
    deliveryPhoto = null;
    signatureFile = null;
    signatureController.clear();
    hasOngoingCall = false;
    callType = null;
    bufferWaitActive = order.status == REACHED && pickupBufferSeconds > 0;
    update();

    final mapController = mapViewController;
    if (mapController != null) {
      await mapController.clearMarkers();
      await mapController.clearPolylines();
      await onMapViewCreated(mapController);
    }
  }

  // Called after an order is marked delivered/undelivered - moves on to the
  // next order in the original API response sequence (wrapping back to the
  // first remaining one if the completed order was last), instead of
  // leaving the rider sitting on a finished order's terminal card.
  void _advanceToNextOrderIfAny() {
    if (_allAssignedOrders.isEmpty) return;
    final completedKey = _orderKey(order);
    final remaining = _allAssignedOrders
        .where((o) => _orderKey(o) != completedKey)
        .toList();
    if (remaining.isEmpty) {
      Get.back();
      return;
    }
    final completedIndex = _allAssignedOrders.indexWhere(
      (o) => _orderKey(o) == completedKey,
    );
    OrdersData? next;
    if (completedIndex != -1) {
      for (var i = completedIndex + 1; i < _allAssignedOrders.length; i++) {
        final candidate = _allAssignedOrders[i];
        if (_orderKey(candidate) != completedKey) {
          next = candidate;
          break;
        }
      }
    }
    next ??= remaining.first;
    switchToOrder(next);
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
    } catch (_) {
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
    if (!await _isWithinUpdateRange()) return;
    _selectedUndeliveredReason = reason.reason;
    await _updateStatus(UNDELIVERED);
  }

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
      ];
      final data = <String, dynamic>{
        'status': status,
        'fe_code': user.code ?? "",
        'awb_no': order.awbNo ?? "",
        if (status == UNDELIVERED) 'reason': _selectedUndeliveredReason ?? "",
      };
      final response = await apiProvider.postRequestWithImagesDio(
        apiEndPoints.updateOrderStatus,
        data,
        images,
      );
      final result = BaseApiResponse.fromJson(response);
      utils.closeLoadingDialog();
      if (result.status_code == 200) {
        order.status = status;
        if (status == UNDELIVERED) order.reason = _selectedUndeliveredReason;
        if (Get.isRegistered<RiderDashboardController>()) {
          Get.find<RiderDashboardController>().getDashBoardData();
        }
        update();
        if (status == DELIVERED) {
          showOrderDeliveredDialog(
            order: order,
            isCod: isCod,
            onContinue: _advanceToNextOrderIfAny,
          );
        } else if (status == UNDELIVERED) {
          _advanceToNextOrderIfAny();
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
    }
  }
}
