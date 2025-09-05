import 'package:get/get.dart';

import '../controller/placed_orders_controller.dart';



class PlacedOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlacedOrdersController>(
      () => PlacedOrdersController(),
    );
  }
}
