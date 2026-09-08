import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../apis/base_api_response.dart';
import '../../global/consts.dart';
import '../../global/global.dart';
import '../../global/location_service.dart';
import '../../local_db/entity/UserData.dart';
import '../../utils/calculate_sla.dart';
import '../dashboard/controller/rider_dashboard_controller.dart';
import '../my_orders/orders/models/orders_model.dart';

class OrderListController extends GetxController {
  var user = UserData();
  final locationUtils = LocationUtils();

  // "b2c" | "c2c" | "whatsapp"
  var typeTab = "b2c".obs;
  // "assigned" | "available" | "completed"
  var statusTab = "assigned".obs;
  // "all" | "ppd" | "cod" | "risk"
  var paymentFilter = "all".obs;
  var filterMenuOpen = false.obs;
  var searchOpen = false.obs;
  var searchQuery = "".obs;
  final searchController = TextEditingController();

  var isLoading = false.obs;

  var assignedOrders = <OrdersData>[].obs;
  var availableOrders = <OrdersData>[].obs;
  var completedOrders = <OrdersData>[].obs;

  @override
  void onInit() {
    getUser();
    super.onInit();
  }

  Future<void> getUser() async {
    final value = await userRepository.getUser();
    if (value != null) {
      user = value;
    }
    await refreshCurrentTab();
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

  void switchFilter(String filter) {
    paymentFilter.value = filter;
    filterMenuOpen.value = false;
  }

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
          apiEndPoints.driverFetchOrderList, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200 && result.data != null) {
        assignedOrders.value = (result.data as List)
            .map((json) => OrdersData.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        assignedOrders.value = [];
      }
    } catch (_) {
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
          apiEndPoints.driverFetchOrderList, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200 && result.data != null) {
        completedOrders.value = (result.data as List)
            .map((json) => OrdersData.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        completedOrders.value = [];
      }
    } catch (_) {
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
          apiEndPoints.fetchPlacedOrders, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200 && result.data != null) {
        availableOrders.value = (result.data as List)
            .map((json) => OrdersData.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        availableOrders.value = [];
      }
    } catch (_) {
      availableOrders.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> acceptRejectOrder(String type, String awbNo) async {
    utils.showLoadingDialog(
        type == acceptOrder ? "Accepting order..." : "Rejecting order...");
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
        apiKeys.status: type,
        apiKeys.awbNo: awbNo,
      };
      var response = await apiProvider.postRequest(
          apiEndPoints.acceptRejectOrder, model);
      var result = BaseApiResponse.fromJson(response);
      utils.closeLoadingDialog();
      if (result.status_code == 200) {
        availableOrders.removeWhere((o) => o.awbNo == awbNo);
        if (Get.isRegistered<RiderDashboardController>()) {
          Get.find<RiderDashboardController>().getDashBoardData();
        }
        if (type == acceptOrder) {
          utils.successSnackBar("Order Accepted",
              "Please find the accepted order under Assigned");
        } else {
          utils.errorSnackBar(
              "Order Rejected", "This order no longer belongs to you");
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
