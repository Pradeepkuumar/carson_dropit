import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:get/get.dart';

class RiderDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RiderDashboardController>(
          () => RiderDashboardController(),
    );
  }
}