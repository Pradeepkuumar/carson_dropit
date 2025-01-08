import 'package:carson_zyppy/pages/orders/orders_controller.dart';
import 'package:get/get.dart';

class ImageSignatureBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrdersController>(
          () => OrdersController(),
      fenix: true
    );
  }

}