import 'package:carson_zyppy/pages/auth/auth_binding.dart';
import 'package:carson_zyppy/pages/auth/login_screen.dart';
import 'package:carson_zyppy/pages/dashboard/view/rider_dashboard.dart';
import 'package:carson_zyppy/pages/dashboard/view/rider_dashboard_binding.dart';
import 'package:carson_zyppy/pages/my_orders/placed_orders/view/placed_orders_list_view.dart';
import 'package:get/get.dart';
import '../pages/my_orders/orders/orders_binding.dart';
import '../pages/my_orders/orders/view/orders_tab_container.dart';
import '../pages/my_orders/placed_orders/binding/placed_orders_binding.dart';


class AppPages {
  AppPages._();
  static const INITIAL = Routes.auth;

  static final routes = [
    GetPage(
      name: _Paths.auth,
      page: () => LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.riderDashbord,
      page: () => RiderDashboard(),
      binding: RiderDashboardBinding(),
    ),
    GetPage(
      name: _Paths.ordersScreen,
      page: () => OrdersTabContainer(),
      binding: OrdersBinding(),
    ),
    GetPage(
      name: _Paths.placedOrders,
      page: () => PlacedOrdersListView(),
      binding: PlacedOrdersBinding(),
    ),
  ];
}


abstract class Routes {
  Routes._();
  static const auth = _Paths.auth;
  static const riderDashBord = _Paths.riderDashbord;
  static const ordersScreen = _Paths.ordersScreen;
  static const signatureImageScreen = _Paths.signatureImageScreen;
  static const placedOrders = _Paths.placedOrders;
}

abstract class _Paths {
  _Paths._();
  static const auth = '/auth_screen';
  static const riderDashbord = '/rider_dashbord';
  static const ordersScreen = '/orders_screen';
  static const signatureImageScreen = '/signature_image_screen';
  static const placedOrders = '/placed_orders';
}