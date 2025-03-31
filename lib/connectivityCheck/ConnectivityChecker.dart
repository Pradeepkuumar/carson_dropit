// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class ConnectivityService extends GetxService {
//   final Connectivity _connectivity = Connectivity();
//   late StreamSubscription<ConnectivityResult> _subscription;
//   final RxBool isConnected = true.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
//     _checkInitialConnection();
//   }
//
//   Future<void> _checkInitialConnection() async {
//     final result = await _connectivity.checkConnectivity();
//     _updateConnectionStatus(result);
//   }
//
//   void _updateConnectionStatus(ConnectivityResult result) {
//     if (result == ConnectivityResult.none) {
//       isConnected.value = false;
//       Get.snackbar(
//         'No Internet',
//         'Please check your internet connection.',
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Get.theme.colorScheme.error,
//         colorText: Colors.white,
//       );
//     } else {
//       isConnected.value = true;
//     }
//   }
//
//   @override
//   void onClose() {
//     _subscription.cancel();
//     super.onClose();
//   }
// }
