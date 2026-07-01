import 'package:carson_zyppy/pages/b2c_pickup_delivery_orders/controller/all_orders_map_controller.dart';
import 'package:get/get.dart';

class AllOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllOrdersMapController>(
          () => AllOrdersMapController(),
    );
  }
}
