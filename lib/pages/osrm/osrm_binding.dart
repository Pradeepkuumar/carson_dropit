import 'package:carson_zyppy/pages/map/controller/all_orders_map_controller.dart';
import 'package:carson_zyppy/pages/osrm/OSMMapController.dart';
import 'package:get/get.dart';

class MapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllOrdersMapController>(() => AllOrdersMapController());
    Get.lazyPut<OSMMapController>(() => OSMMapController());
  }
}