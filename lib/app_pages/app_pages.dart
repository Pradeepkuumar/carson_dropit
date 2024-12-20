import 'package:carson_zyppy/pages/auth/auth_binding.dart';
import 'package:carson_zyppy/pages/auth/login_screen.dart';
import 'package:carson_zyppy/pages/dashboard/rider_dashboard.dart';
import 'package:carson_zyppy/pages/dashboard/rider_dashboard_binding.dart';
import 'package:get/get.dart';

import '../pages/orders/orders_binding.dart';
import '../pages/orders/orders_tab_container.dart';

part 'app_routes.dart';

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
  ];
}
