part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  //Common Screens
  static const auth = _Paths.auth;
  static const riderDashBord = _Paths.riderDashbord;
  static const ordersScreen = _Paths.ordersScreen;
  static const signatureImageScreen = _Paths.signatureImageScreen;


}

abstract class _Paths {
  _Paths._();
  static const auth = '/auth_screen';
  static const riderDashbord = '/rider_dashbord';
  static const ordersScreen = '/orders_screen';
  static const signatureImageScreen = '/signature_image_screen';




}
