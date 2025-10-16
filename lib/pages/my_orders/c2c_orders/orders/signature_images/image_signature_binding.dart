import 'package:carson_zyppy/pages/my_orders/c2c_orders/orders/c2c_orders_screens/c2c_controller.dart';
import 'package:get/get.dart';

class C2cImageSignatureBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<C2COrdersController>(
          () => C2COrdersController(),
      fenix: true
    );
  }

}