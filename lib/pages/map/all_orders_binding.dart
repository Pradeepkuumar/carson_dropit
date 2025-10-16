import 'package:carson_zyppy/pages/map/controller/all_orders_map_controller.dart';
import 'package:get/get.dart';

class AllOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllOrdersMapController>(
          () => AllOrdersMapController(),
    );
  }
}
