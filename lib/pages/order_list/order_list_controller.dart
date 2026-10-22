import 'dart:io';
import 'dart:math' as Log;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import '../../app_pages/app_pages.dart';
import '../../apis/base_api_response.dart';
import '../../firebase_notifications/firebase_notifiction_controller.dart';
import '../../global/cancelled_orders.dart';
import '../../global/consts.dart';
import '../../global/global.dart';
import '../../global/location_service.dart';
import '../../global/order_delivered_dialog.dart';
import '../../local_db/entity/UserData.dart';
import '../../utils/calculate_sla.dart';
import '../dashboard/controller/rider_dashboard_controller.dart';
import '../my_orders/orders/models/orders_model.dart';
import 'models/driver_config_model.dart';

class OrderListController extends GetxController
    with GetSingleTickerProviderStateMixin {
  var user = UserData();
  final locationUtils = LocationUtils();

  // "b2c" | "c2c" | "whatsapp" - which of these are shown as tabs, driven by
  // the driver config API's allowed_channels. Defaults to all three so the
  // screen behaves as before if that call hasn't returned yet or fails.
  var allowedChannels = <String>["b2c", "c2c", "whatsapp"].obs;

  // "b2c" | "c2c" | "whatsapp"
  var typeTab = "b2c".obs;
  // "assigned" | "available" | "completed" | "undelivered" - kept in sync
  // with tabController.
  static const statuses = ["assigned", "available", "completed", "undelivered"];
  var statusTab = "assigned".obs;
  late final TabController tabController;
  // "all" | "ppd" | "cod" | "risk"
  var paymentFilter = "all".obs;
  // "all" | "b2c" | "c2c" | "whatsapp"
  var serviceTypeFilter = "all".obs;
  var filterMenuOpen = false.obs;
  var searchOpen = false.obs;
  var searchQuery = "".obs;
  final searchController = TextEditingController();

  // One loading flag per status tab, so a slow list doesn't spin the others.
  var isLoadingAssigned = false.obs;
  var isLoadingAvailable = false.obs;
  var isLoadingCompleted = false.obs;
  // True when no location could be found for the Available fetch - that
  // API rejects a request without latitude/longitude, so it isn't called.
  var availableNeedsLocation = false.obs;

  var assignedOrders = <OrdersData>[].obs;
  var availableOrders = <OrdersData>[].obs;
  var completedOrders = <OrdersData>[].obs;
  // Undelivered / not picked / cancelled - fetched with completedOrders in
  // one call and split out, since they still need to be dropped back.
  var undeliveredOrders = <OrdersData>[].obs;

  // Capture state for the "back to warehouse" (dropback) sheet on an
  // undelivered order in the Undelivered tab - same shape as the photo/
  // signature capture on ActiveDeliveryController, kept separate since this
  // screen isn't driven by a single "current" order.
  File? dropbackPhoto;
  final SignatureController dropbackSignatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  File? dropbackSignatureFile;
  var isSubmittingDropback = false.obs;
  // "merchant" | "warehouse" - where the undelivered order is being returned.
  // Merchant is the default each time the sheet opens.
  String dropbackTarget = "merchant";
  bool get isDropbackToMerchant => dropbackTarget == "merchant";

  // Set when this screen is opened from a "NearByOrders" notification tap -
  // once the available list loads, the matching order is opened automatically.
  String? _focusOrderRef;

  Worker? _cancelWorker;
  AppLifecycleListener? _lifecycleListener;

  @override
  void onInit() {
    final args = Get.arguments;
    if (args is Map) {
      final initialStatusTab = args["initialStatusTab"] as String?;
      if (initialStatusTab != null && initialStatusTab.isNotEmpty) {
        statusTab.value = initialStatusTab;
      }
      final focusOrderRef = args["focusOrderRef"] as String?;
      if (focusOrderRef != null && focusOrderRef.isNotEmpty) {
        _focusOrderRef = focusOrderRef;
      }
    }
    final initialIndex = statuses.indexOf(statusTab.value);
    tabController = TabController(
      length: statuses.length,
      vsync: this,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
    );
    // Tapping or swiping only switches which cached list is shown - all
    // three lists are fetched up front, so no API call here.
    tabController.addListener(() {
      statusTab.value = statuses[tabController.index];
    });
    if (Get.isRegistered<FirebaseMessagingController>()) {
      _cancelWorker = ever(
        Get.find<FirebaseMessagingController>().onOrderCancelled,
        (Map<String, dynamic>? data) {
          if (data != null) _onOrderCancelledPush(data);
        },
      );
    }
    // A cancel push received while the app was in the background never
    // reaches the worker above - re-sync the lists on return instead.
    _lifecycleListener = AppLifecycleListener(onResume: _onAppResumed);
    getUser();
    super.onInit();
  }

  void _onAppResumed() {
    // Skip while a sheet/dialog is up (e.g. back from the camera in the
    // dropback sheet) or another screen is on top of this one.
    if (Get.currentRoute != Routes.orderListScreen ||
        Get.isDialogOpen == true ||
        Get.isBottomSheetOpen == true) {
      return;
    }
    _refreshAndAnnounceCancelled();
    refreshTab("undelivered");
  }

  // Orders that drop out of Assigned on the re-fetch are checked one by one
  // and any now CANCELLED get the cancelled dialog.
  Future<void> _refreshAndAnnounceCancelled() async {
    if (typeTab.value != "b2c") return;
    final before = assignedOrders.toList();
    if (!await fetchAssigned()) return;
    final nowKeys = assignedOrders.map((o) => o.awbNo).toSet();
    final gone = before.where((o) => !nowKeys.contains(o.awbNo)).toList();
    await showCancelledOrdersAmong(
      gone,
      user.code ?? "",
      isStillOnTop: () => Get.currentRoute == Routes.orderListScreen,
    );
  }

  // Cancelled orders leave Assigned and show up under Undelivered, so both
  // lists are re-fetched. The dialog only shows while this screen is the
  // one on top - the active delivery screen handles its own.
  void _onOrderCancelledPush(Map<String, dynamic> data) {
    final ref = (data['awb_number'] ?? data['awb_no'] ?? '').toString();
    if (ref.isEmpty) return;
    final reason = (data['reason'] ?? data['cancel_reason'])?.toString();
    final match = assignedOrders.firstWhereOrNull((o) => o.awbNo == ref);
    assignedOrders.removeWhere((o) => o.awbNo == ref);
    refreshTab("assigned");
    refreshTab("undelivered");
    if (Get.currentRoute != Routes.orderListScreen) return;
    if (!markCancellationNotified(ref)) return;
    showOrderCancelledDialog(
      order: match ?? OrdersData(awbNo: ref),
      reason: reason,
      buttonLabel: "Got it",
      onContinue: () {},
    );
  }

  Future<void> getUser() async {
    final value = await userRepository.getUser();
    if (value != null) {
      user = value;
    }
    await getDriverConfig();
    await refreshAllTabs();
  }

  static const _knownChannels = {"b2c", "c2c", "whatsapp"};

  Future<void> getDriverConfig() async {
    try {
      Map<String, dynamic> model = {apiKeys.feCode: user.code};
      var response = await apiProvider.getRequestWithQueryParams(
        apiEndPoints.driverConfig,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200 && result.data != null) {
        final config = DriverConfigData.fromJson(
          result.data as Map<String, dynamic>,
        );
        final channels = (config.allowedChannels ?? [])
            .map((c) => c.toLowerCase())
            .where(_knownChannels.contains)
            .toList();
        if (channels.isNotEmpty) {
          allowedChannels.value = channels;
          if (!channels.contains(typeTab.value)) {
            typeTab.value = channels.first;
          }
        }
      }
    } catch (_) {
      // Keep the default allowedChannels (all tabs) on failure.
    }
  }

  void switchType(String type) {
    if (typeTab.value == type) return;
    typeTab.value = type;
    refreshAllTabs();
  }

  // Type and Payment are independent filter groups shown side by side in the
  // same dropdown, so picking one no longer auto-closes the menu - the user
  // can set both before dismissing it by tapping outside.
  void switchFilter(String filter) => paymentFilter.value = filter;

  void switchServiceTypeFilter(String type) => serviceTypeFilter.value = type;

  void openFilterMenu() => filterMenuOpen.value = true;

  void closeFilterMenu() => filterMenuOpen.value = false;

  void openSearch() => searchOpen.value = true;

  void closeSearch() {
    searchOpen.value = false;
    searchQuery.value = "";
    searchController.clear();
  }

  void updateSearchQuery(String query) => searchQuery.value = query;

  @override
  void onClose() {
    _cancelWorker?.dispose();
    _lifecycleListener?.dispose();
    tabController.dispose();
    searchController.dispose();
    dropbackSignatureController.dispose();
    super.onClose();
  }

  Future<void> captureDropbackPhoto() async {
    final file = await utils.pickImage(ImageSource.camera);
    if (file != null) dropbackPhoto = file;
    update();
  }

  Future<void> captureDropbackSignature() async {
    if (dropbackSignatureController.isEmpty) return;
    final bytes = await dropbackSignatureController.toPngBytes(
      width: 500,
      height: 500,
    );
    if (bytes == null) return;
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/dropback_signature_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    dropbackSignatureFile = file;
    update();
  }

  void clearDropbackSignature() {
    dropbackSignatureController.clear();
    dropbackSignatureFile = null;
    update();
  }

  void resetDropbackState() {
    dropbackTarget = "merchant";
    dropbackPhoto = null;
    dropbackSignatureFile = null;
    dropbackSignatureController.clear();
    update();
  }

  // Switching destination keeps any photo/signature already captured.
  void selectDropbackTarget(String target) {
    if (dropbackTarget == target) return;
    dropbackTarget = target;
    update();
  }

  Future<bool> confirmDropback(OrdersData order) async {
    if (dropbackPhoto == null) return false;
    if (isSubmittingDropback.value) return false;
    isSubmittingDropback.value = true;
    utils.showLoadingDialog("Updating...");
    try {
      final images = <Map<String, dynamic>>[
        {'key': 'dropback_proof', 'file': dropbackPhoto},
        if (dropbackSignatureFile != null)
          {'key': 'signature', 'file': dropbackSignatureFile},
      ];
      final data = <String, dynamic>{
        // DROPBACK_ML = returned to merchant, DROPBACK_CLW = dropped at
        // warehouse.
        'status': isDropbackToMerchant ? DROPBACK_ML : DROPBACK_CLW,
        'fe_code': user.code ?? "",
        'awb_no': order.awbNo ?? "",
      };
      final response = await apiProvider.postRequestWithImagesDio(
        apiEndPoints.updateOrderStatus,
        data,
        images,
      );
      final result = BaseApiResponse.fromJson(response);
      utils.closeLoadingDialog();
      if (result.status_code == 200) {
        undeliveredOrders.removeWhere((o) => o.awbNo == order.awbNo);
        if (Get.isRegistered<RiderDashboardController>()) {
          Get.find<RiderDashboardController>().getDashBoardData();
        }
        resetDropbackState();
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
      isSubmittingDropback.value = false;
    }
  }

  // Only B2C is backed by a real order list today - C2C uses its own
  // model/endpoint and WhatsApp has no order-list endpoint yet, only the
  // dashboard's summary counts. Those two tabs show an empty state instead
  // of fabricated data until a data source exists for them.
  Future<void> refreshAllTabs() async {
    if (typeTab.value != "b2c") return;
    await Future.wait([fetchAssigned(), fetchAvailable(), fetchCompleted()]);
  }

  Future<void> refreshTab(String status) async {
    if (typeTab.value != "b2c") return;
    switch (status) {
      case "assigned":
        await fetchAssigned();
        break;
      case "available":
        await fetchAvailable();
        break;
      case "completed":
      case "undelivered":
        await fetchCompleted();
        break;
    }
  }

  // True when the list came back from the API (an empty list included).
  Future<bool> fetchAssigned() async {
    isLoadingAssigned.value = true;
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
        apiKeys.status: [ASSIGNED, RE_ASSIGNED, PICKED, OFD,REACHED],
      };
      var response = await apiProvider.postRequest(
        apiEndPoints.driverFetchOrderList,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200 && result.data != null) {
        assignedOrders.value = (result.data as List)
            .map((json) => OrdersData.fromJson(json as Map<String, dynamic>))
            .toList();
        return true;
      } else {
        assignedOrders.value = [];
        return false;
      }
    } catch (ex, stackTrace) {
      print("❌ FetchAvailable Exception: $ex");
      print("❌ StackTrace: $stackTrace");
      assignedOrders.value = [];
      return false;
    } finally {
      isLoadingAssigned.value = false;
    }
  }

  Future<void> fetchCompleted() async {
    isLoadingCompleted.value = true;
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
        apiKeys.status: [DELIVERED, UNDELIVERED, NOT_PICKED,CANCELED],
      };
      var response = await apiProvider.postRequest(
        apiEndPoints.driverFetchOrderList,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200 && result.data != null) {
        final orders = (result.data as List)
            .map((json) => OrdersData.fromJson(json as Map<String, dynamic>))
            .toList();
        completedOrders.value =
            orders.where((o) => o.status == DELIVERED).toList();
        undeliveredOrders.value =
            orders.where((o) => o.status != DELIVERED).toList();
      } else {
        completedOrders.value = [];
        undeliveredOrders.value = [];
      }
    } catch (ex, stackTrace) {
      print("❌ FetchAvailable Exception: $ex");
      print("❌ StackTrace: $stackTrace");
      completedOrders.value = [];
      undeliveredOrders.value = [];
    } finally {
      isLoadingCompleted.value = false;
    }
  }

  Future<void> fetchAvailable() async {
    isLoadingAvailable.value = true;
    try {
      final location = await _availableFetchLocation();
      availableNeedsLocation.value = location == null;
      if (location == null) {
        availableOrders.value = [];
        return;
      }
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
        apiKeys.latitude: location.latitude,
        apiKeys.longitude: location.longitude,
      };
      var response = await apiProvider.postRequest(
        apiEndPoints.fetchPlacedOrders,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200 && result.data != null) {
        availableOrders.value = (result.data as List)
            .map((json) => OrdersData.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        availableOrders.value = [];
      }
    } catch (ex, stackTrace) {
      print("❌ FetchAvailable Exception: $ex");
      print("❌ StackTrace: $stackTrace");
      availableOrders.value = [];
    } finally {
      isLoadingAvailable.value = false;
      _resolveFocusedOrder();
    }
  }

  // The dashboard's continuously-updated position first (instant), then a
  // fresh fix, then the phone's last known position.
  Future<({double latitude, double longitude})?>
      _availableFetchLocation() async {
    if (Get.isRegistered<RiderDashboardController>()) {
      final cached = Get.find<RiderDashboardController>().currentLocation;
      if (cached?.latitude != null && cached?.longitude != null) {
        return (latitude: cached!.latitude!, longitude: cached.longitude!);
      }
    }
    final fresh = await locationUtils.getCurrentLocation();
    if (fresh?.latitude != null && fresh?.longitude != null) {
      return (latitude: fresh!.latitude!, longitude: fresh.longitude!);
    }
    try {
      final last = await geo.Geolocator.getLastKnownPosition();
      if (last != null) {
        return (latitude: last.latitude, longitude: last.longitude);
      }
    } catch (_) {}
    return null;
  }

  void _resolveFocusedOrder() {
    final orderRef = _focusOrderRef;
    if (orderRef == null) return;
    _focusOrderRef = null;
    OrdersData? match;
    for (final model in availableOrders) {
      if (model.orderRefNumber == orderRef || model.awbNo == orderRef) {
        match = model;
        break;
      }
    }
    if (match != null) {
      Get.toNamed(
        Routes.orderDetailScreen,
        arguments: match.awbNo,
      )?.then((_) => refreshAllTabs());







































    } else {
      utils.errorSnackBar("Order unavailable", "Order no longer available");
    }
  }

  Future<bool> acceptRejectOrder(String type, String awbNo) async {
    utils.showLoadingDialog(
      type == acceptOrder ? "Accepting order..." : "Rejecting order...",
    );
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
        apiKeys.status: type,
        apiKeys.awbNo: awbNo,
      };
      var response = await apiProvider.postRequest(
        apiEndPoints.acceptRejectOrder,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      utils.closeLoadingDialog();
      if (result.status_code == 200) {
        availableOrders.removeWhere((o) => o.awbNo == awbNo);
        if (Get.isRegistered<RiderDashboardController>()) {
          Get.find<RiderDashboardController>().getDashBoardData();
        }
        if (type == acceptOrder) {
          utils.successSnackBar(
            "Order Accepted",
            "Please find the accepted order under Assigned",
          );
        } else {
          utils.errorSnackBar(
            "Order Rejected",
            "This order no longer belongs to you",
          );
        }
        // Tabs are cached, so pull the accepted order into Assigned now
        // rather than relying on a refetch when that tab is opened.
        await Future.wait([
          fetchAvailable(),
          if (type == acceptOrder) fetchAssigned(),
        ]);
        return true;
      } else {
        utils.errorSnackBar("Error", result.message.toString());
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      utils.errorSnackBar("Exception", e.toString());
      return false;
    }
  }

  RxBool loadingFor(String status) {
    switch (status) {
      case "available":
        return isLoadingAvailable;
      case "completed":
      case "undelivered":
        return isLoadingCompleted;
      default:
        return isLoadingAssigned;
    }
  }

  List<OrdersData> ordersFor(String status) {
    List<OrdersData> source;
    switch (status) {
      case "available":
        source = availableOrders;
        break;
      case "completed":
        source = completedOrders;
        break;
      case "undelivered":
        source = undeliveredOrders;
        break;
      default:
        source = assignedOrders;
    }
    List<OrdersData> filtered;
    switch (paymentFilter.value) {
      case "ppd":
        filtered = source.where((o) => !isCod(o)).toList();
        break;
      case "cod":
        filtered = source.where(isCod).toList();
        break;
      case "risk":
        filtered = source.where((o) => isAtRisk(o, status)).toList();
        break;
      default:
        filtered = source;
    }

    final typeFilter = serviceTypeFilter.value;
    if (typeFilter != "all") {
      filtered = filtered
          .where((o) => (o.serviceType ?? "").toLowerCase() == typeFilter)
          .toList();
    }

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return filtered;
    return filtered.where((o) {
      return (o.awbNo ?? "").toLowerCase().contains(query) ||
          (o.consigneeName ?? "").toLowerCase().contains(query) ||
          (o.merchantName ?? "").toLowerCase().contains(query);
    }).toList();
  }

  bool isCod(OrdersData order) =>
      (order.paymentType ?? "").toLowerCase() == "cod";

  bool isAtRisk(OrdersData order, String status) =>
      status != "completed" &&
      status != "undelivered" &&
      (order.is_at_risk ?? false);

  // int remainingSecondsFor(OrdersData order) {
  //   final slaHours = int.tryParse(order.sla_in_hours ?? "") ?? 0;
  //   final createdAt = order.createdAt;
  //   if (createdAt == null || createdAt.isEmpty) return slaHours * 3600;
  //   try {
  //     final elapsed = getSecondsDifference(parseUtcTime(createdAt));
  //     return (slaHours * 3600) - elapsed;
  //   } catch (_) {
  //     return slaHours * 3600;
  //   }
  // }
}
