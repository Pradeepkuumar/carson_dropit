import 'dart:math' as Log;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app_pages/app_pages.dart';
import '../../apis/base_api_response.dart';
import '../../global/consts.dart';
import '../../global/global.dart';
import '../../global/location_service.dart';
import '../../local_db/entity/UserData.dart';
import '../../utils/calculate_sla.dart';
import '../dashboard/controller/rider_dashboard_controller.dart';
import '../my_orders/orders/models/orders_model.dart';
import 'models/driver_config_model.dart';

class OrderListController extends GetxController {
  var user = UserData();
  final locationUtils = LocationUtils();

  // "b2c" | "c2c" | "whatsapp" - which of these are shown as tabs, driven by
  // the driver config API's allowed_channels. Defaults to all three so the
  // screen behaves as before if that call hasn't returned yet or fails.
  var allowedChannels = <String>["b2c", "c2c", "whatsapp"].obs;

  // "b2c" | "c2c" | "whatsapp"
  var typeTab = "b2c".obs;
  // "assigned" | "available" | "completed"
  var statusTab = "assigned".obs;
  // "all" | "ppd" | "cod" | "risk"
  var paymentFilter = "all".obs;
  // "all" | "b2c" | "c2c" | "whatsapp"
  var serviceTypeFilter = "all".obs;
  var filterMenuOpen = false.obs;
  var searchOpen = false.obs;
  var searchQuery = "".obs;
  final searchController = TextEditingController();

  var isLoading = false.obs;

  var assignedOrders = <OrdersData>[].obs;
  var availableOrders = <OrdersData>[].obs;
  var completedOrders = <OrdersData>[].obs;

  // Set when this screen is opened from a "NearByOrders" notification tap -
  // once the available list loads, the matching order is opened automatically.
  String? _focusOrderRef;

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
    getUser();
    super.onInit();
  }

  Future<void> getUser() async {
    final value = await userRepository.getUser();
    if (value != null) {
      user = value;
    }
    await getDriverConfig();
    await refreshCurrentTab();
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
    refreshCurrentTab();
  }

  void switchStatus(String status) {
    if (statusTab.value == status) return;
    statusTab.value = status;
    refreshCurrentTab();
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
    searchController.dispose();
    super.onClose();
  }

  // Only B2C is backed by a real order list today - C2C uses its own
  // model/endpoint and WhatsApp has no order-list endpoint yet, only the
  // dashboard's summary counts. Those two tabs show an empty state instead
  // of fabricated data until a data source exists for them.
  Future<void> refreshCurrentTab() async {
    if (typeTab.value != "b2c") return;
    switch (statusTab.value) {
      case "assigned":
        await fetchAssigned();
        break;
      case "available":
        await fetchAvailable();
        break;
      case "completed":
        await fetchCompleted();
        break;
    }
  }

  Future<void> fetchAssigned() async {
    isLoading.value = true;
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
        apiKeys.status: [ASSIGNED, RE_ASSIGNED, PICKED, OFD],
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
      } else {
        assignedOrders.value = [];
      }
    } catch (ex, stackTrace) {
      print("❌ FetchAvailable Exception: $ex");
      print("❌ StackTrace: $stackTrace");
      assignedOrders.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCompleted() async {
    isLoading.value = true;
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
        apiKeys.status: [DELIVERED, UNDELIVERED],
      };
      var response = await apiProvider.postRequest(
        apiEndPoints.driverFetchOrderList,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200 && result.data != null) {
        completedOrders.value = (result.data as List)
            .map((json) => OrdersData.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        completedOrders.value = [];
      }
    } catch (ex, stackTrace) {
      print("❌ FetchAvailable Exception: $ex");
      print("❌ StackTrace: $stackTrace");
      completedOrders.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAvailable() async {
    isLoading.value = true;
    try {
      final location = await locationUtils.getCurrentLocation();
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
        apiKeys.latitude: location?.latitude,
        apiKeys.longitude: location?.longitude,
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
      isLoading.value = false;
      _resolveFocusedOrder();
    }
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
        arguments: match,
      )?.then((_) => refreshCurrentTab());
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
        await fetchAvailable();
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

  List<OrdersData> get currentOrders {
    List<OrdersData> source;
    switch (statusTab.value) {
      case "available":
        source = availableOrders;
        break;
      case "completed":
        source = completedOrders;
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
        filtered = source.where(isAtRisk).toList();
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

  bool isAtRisk(OrdersData order) =>
      statusTab.value != "completed" && remainingSecondsFor(order) < 1800;

  int remainingSecondsFor(OrdersData order) {
    final slaHours = int.tryParse(order.sla_in_hours ?? "") ?? 0;
    final createdAt = order.createdAt;
    if (createdAt == null || createdAt.isEmpty) return slaHours * 3600;
    try {
      final elapsed = getSecondsDifference(parseUtcTime(createdAt));
      return (slaHours * 3600) - elapsed;
    } catch (_) {
      return slaHours * 3600;
    }
  }
}
