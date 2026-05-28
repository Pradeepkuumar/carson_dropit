import 'dart:async';
import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/pages/map/controller/all_orders_map_controller.dart';
import 'package:carson_zyppy/pages/my_orders/orders/models/orders_model.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:signature/signature.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../global/consts.dart';
import '../../utils/calculate_sla.dart';
import 'orderItem/clickedOrderItem.dart';

class AllOrdersMapPage extends StatefulWidget {
  const AllOrdersMapPage({super.key});

  @override
  State<AllOrdersMapPage> createState() => _AllOrdersMapPageState();
}

class _AllOrdersMapPageState extends State<AllOrdersMapPage> with WidgetsBindingObserver {
  final controller = Get.put(AllOrdersMapController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final menuShowcaseKey = GlobalKey();
  bool _showcaseShown = false;

  StreamSubscription<RemainingTimeOrDistanceChangedEvent>?
      remainingTimeOrDistanceChangedSubscription;

  var enableMapLiveCamera = false.obs;
  var enableMapType = false.obs;
  var enableNavigation = false.obs;
  var showNotificationView = false.obs;
  late LatLng pickUpLocation;
  late LatLng deliveryLocation;

  var orderDurationByGoogle = "".obs;
  var orderDistanceByGoogle = "".obs;

  // Call tracking
  Stopwatch? _callTimer;
  bool _isCallInitiated = false;
  bool _callLoggedOnBackground = false;
  Timer? _callDurationTimer;
  String _currentCallDuration = "00:00";


  @override
  void initState() {
    super.initState();
    ever(controller.isUpdateCardVisibleForUpdate, (visible) {
      if (visible && !_showcaseShown &&  (controller.selectedOrder.value.status == OFD || controller.selectedOrder.value.status == ASSIGNED || controller.selectedOrder.value.status == RE_ASSIGNED)) {
        _showcaseShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ShowcaseView.get().startShowCase([menuShowcaseKey]);
        });
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  String formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;

    String formattedMinutes = minutes.toString().padLeft(2, '0');
    String formattedSeconds = seconds.toString().padLeft(2, '0');

    return '$formattedMinutes min $formattedSeconds sec';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callTimer?.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached && _isCallInitiated) {
      _handleAppTermination();
    }
  }


  void _handleAppTermination() async {
    if (_isCallInitiated && _callTimer != null && _callTimer!.isRunning) {
      _callTimer!.stop();
      _callDurationTimer?.cancel();
      int duration = _callTimer!.elapsed.inSeconds;
      String formattedDuration = formatDuration(duration);
      final order = controller.selectedCallOrder.value;

      try {
        await apiProvider.postRequest('driver/call-log', {
          'fe_code': order.feCode,
          'awb_no': order.awbNo,
          'call_type': controller.callType,
          'customer_phone': controller.callType == "pickup" ? order.pickupPhoneNo : order.consigneeMobileNo,
          'status': 'call disconnected',
          'duration': formattedDuration,
        });
      } catch (e) {
        debugPrint('Error logging call on termination: $e');
      }

      controller.endCall();
      _isCallInitiated = false;
    }
  }

  void _startCall(String phoneNumber, String type, OrdersData order) {
    if (controller.hasOngoingCall.value) {
      utils.errorSnackBar("Ongoing Call", "Cannot initiate another call while a call is in progress");
      return;
    }
    controller.callType = type;
    _isCallInitiated = true;
    _callLoggedOnBackground = false;
    _callTimer = Stopwatch()..start();
    controller.startCall(order.awbNo ?? "");
    utils.openDialPad(phoneNumber);
    controller.selectedCallOrder.value = order;
    _startCallDurationTimer();
  }

  void _startCallDurationTimer() {
    _callDurationTimer?.cancel();
    _currentCallDuration = "00:00";
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_callTimer != null && _callTimer!.isRunning) {
        int totalSeconds = _callTimer!.elapsed.inSeconds;
        int minutes = totalSeconds ~/ 60;
        int seconds = totalSeconds % 60;
        _currentCallDuration = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        setState(() {});
      }
    });
  }

  void _handleCallEnd() {
  if (_callTimer != null && _callTimer!.isRunning) {
    _callTimer!.stop();
    _callDurationTimer?.cancel();
    _isCallInitiated = false;
    int duration = _callTimer!.elapsed.inSeconds;
    String formattedDuration = formatDuration(duration);
    controller.callDuration.value = formattedDuration;
    controller.showCallConfirmation.value = true;
     setState(() {});
  }
}



  void _submitCallResult(String result, String duration) {
    final order = controller.selectedCallOrder.value;
    apiProvider.postRequest('driver/call-log', {
      'fe_code': order.feCode,
      'awb_no': order.awbNo,
      'call_type': controller.callType,
      'customer_phone': controller.callType == "pickup" ? order.pickupPhoneNo : order.consigneeMobileNo,
      'status': result,
      'duration': duration,
    }).then((response) {
      debugPrint('Call logged: $response');
      controller.showCallConfirmation.value = false;
      controller.endCall();
    }).catchError((error) {
      debugPrint('Error logging call: $error');
    });
    _resetCallState();
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }

  void _resetCallState() {
    _isCallInitiated = false;
    _callLoggedOnBackground = false;
    controller.callType = null;
    _callTimer = null;
    _callDurationTimer?.cancel();
    _currentCallDuration = "00:00";
  }

  void _showNonCancellableCallConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.black.withValues(alpha: 0.6),
      builder: (context) => PopScope(
        canPop: false,
        child: Scaffold(
           body:  Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: Get.width - 64,
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryThemeColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_callback,
                            size: 32,
                            color: AppColors.primaryThemeColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        utils.tvCustom("Call Completed", AppColors.black, 16),
                        const SizedBox(height: 16),
                        utils.tvCustom("Order No. ${controller.selectedCallOrder.value.awbNo}", AppColors.black, 12),
                        utils.tvCustom("Contact No. ${controller.callType == "pickup" ?controller.selectedCallOrder.value.pickupPhoneNo :controller.selectedCallOrder.value.consigneeMobileNo}", AppColors.black, 12),
                      
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryThemeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: AppColors.primaryThemeColor),
                              const SizedBox(width: 4),
                              Text(
                                "Duration: ${controller.callDuration.value}",
                                style: const TextStyle(
                                  color: AppColors.primaryThemeColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        utils.tvCustom("How was the last call?", AppColors.greyColor5, 12),
                        const SizedBox(height: 16),
                        _buildOptionButton(
                          icon: Icons.person,
                          label: "Talked to customer",
                          color: Colors.green,
                          onTap: () {
                            Navigator.pop(context);
                            _submitCallResult("talked to customer", controller.callDuration.value);
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildOptionButton(
                          icon: Icons.call_missed,
                          label: "Customer Missed Call",
                          color: Colors.redAccent,
                          onTap: () {
                            Navigator.pop(context);
                            _submitCallResult("customer missed call", controller.callDuration.value);
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildOptionButton(
                          icon: Icons.cancel_outlined,
                          label: "Call Not Connected",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pop(context);
                            _submitCallResult("Not Connected", controller.callDuration.value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onViewCreated(GoogleNavigationViewController mapController) async {
    WidgetsFlutterBinding.ensureInitialized();
    WakelockPlus.enable();
    controller.navigationViewController = mapController;
    await mapController.setMyLocationEnabled(true);
    for (var marker in controller.markers) {
      // google_navigation_flutter expects List<MarkerOptions>.
      mapController.addMarkers([marker.options]);
    }
    await GoogleMapsNavigator.setDestinations(Destinations(
      waypoints: controller.waypoints,
      displayOptions: NavigationDisplayOptions(
        showDestinationMarkers: false,
        showStopSigns: true,
        showTrafficLights: true,
      ),
      routingOptions: RoutingOptions(travelMode: NavigationTravelMode.driving),
    ));
    await controller.navigationViewController?.setNavigationUIEnabled(true);
    await controller.navigationViewController?.setSpeedometerEnabled(true);
    await controller.navigationViewController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: controller.currentLocation!,
          zoom: 14,
        ),
      ),
    );
    await controller.startGuidedNavigation();
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () { _showcaseShown = false;
        _scaffoldKey.currentState?.openEndDrawer();
       },
      builder: (context) => Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            backgroundColor: AppColors.primaryThemeColor,
            title: const Text("My Orders"),
            centerTitle: true,
            elevation: 0,
            actions: [
              Showcase(
                key: menuShowcaseKey,
                description: 'Update order from right panel',
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
              ),
            ],
          ),
          endDrawer: Drawer(
  backgroundColor: AppColors.primaryThemeColor,
  child: SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Obx(
        () => ListView(
          children: [
           
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    utils.tvCustom("Order Details", AppColors.white, 20),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      height: 2,
                      width: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.white, size: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
             Obx(
               ()=> Visibility(
                visible: _isCallInitiated,
                 child: Card(child: Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: Column(
                     children: [
                        utils.tvCustom("Ongoing Call",AppColors.primaryThemeColor,15),
                         const SizedBox(height: 5,),
                        utils.tvCustom("Contact No. ${controller.callType == "pickup" ?controller.selectedCallOrder.value.pickupPhoneNo :controller.selectedCallOrder.value.consigneeMobileNo}", AppColors.black, 12),
                        const SizedBox(height: 10,),
                       Row(
                                      children: [
                                        Expanded(
                                          child: _callActionButton(
                                            "End Call",
                                            Icons.phone,
                                            AppColors.red,
                                            () => _handleCallEnd(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.green.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.timer_outlined, size: 16, color: AppColors.green),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    _currentCallDuration,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.green,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                     ],
                   ),
                 ),),
               ),
             ),
            Obx(() {
              final bool hasCurrent =
                  controller.currentLocationOrders.isNotEmpty;
              final order = hasCurrent
                  ? controller.currentLocationOrders.firstWhere((e)=> e.awbNo == controller.selectedOrderAwbId.value)
                  : controller.ordersList.firstWhere((e)=> e.awbNo == controller.selectedOrderAwbId.value);
              final bool isPicked = order.status == PICKED;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryThemeColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            "Current Order",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryThemeColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPicked
                                ? Colors.green.withOpacity(0.12)
                                : Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            order.status ?? "",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isPicked ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("AWB No.",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500)),
                              const SizedBox(height: 2),
                              Text(
                                order.awbNo.toString(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        slaTimer(
                          60.sp,
                          60.sp,
                          order.createdAt.toString(),
                          int.tryParse(order.sla_in_hours.toString()) ?? 0,
                          10,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 14),

                    // Location info chips
                    _modernInfoRow(
                        Icons.my_location_rounded, "Zone", order.consigneeZone ?? ""),
                    const SizedBox(height: 8),
                    _modernInfoRow(
                        Icons.signpost_rounded, "Street", order.consigneeStreetNumber ?? ""),
                    const SizedBox(height: 8),
                    _modernInfoRow(
                        Icons.apartment_rounded, "Building", order.consigneeBuildingNo ?? ""),

                   
                    Visibility(
                      visible: isPicked,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          Divider(color: Colors.grey.shade200, height: 1),
                          const SizedBox(height: 14),

                          // Distance + Time pills
                          Row(
                            children: [
                              _statPill(
                                Icons.route_rounded,
                                order.distance ?? "-",
                                Colors.blue.shade50,
                                Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              _statPill(
                                Icons.access_time_rounded,
                                order.duration ?? "-",
                                Colors.purple.shade50,
                                Colors.purple.shade700,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          _modernInfoRow(Icons.timer_outlined, "SLA",
                              "${order.sla_in_hours} Hrs"),
                          const SizedBox(height: 8),
                          _modernInfoRow(Icons.currency_rupee_rounded,
                              "Amount", order.orderAmount ?? ""),
                          const SizedBox(height: 8),
                          _modernInfoRow(Icons.scale_rounded, "Weight",
                              order.weight ?? ""),
                          const SizedBox(height: 8),
                          _modernInfoRow(Icons.person_rounded,
                              "Consignee", order.consigneeName ?? ""),

                          const SizedBox(height: 14),
                          Divider(color: Colors.grey.shade200, height: 1),
                          const SizedBox(height: 14),

                          _addressBlock(Icons.radio_button_checked_rounded,
                              "Pick-Up", order.pickupAddress ?? "",
                              Colors.green),
                          const SizedBox(height: 10),
                          _addressBlock(Icons.location_on_rounded,
                              "Drop-Off", order.consigneeAddress ?? "",
                              Colors.red),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Call buttons row
                    Obx(() => controller.hasOngoingCall.value
                        ? Row(
                            children: [
                              Expanded(
                                child: _callActionButton(
                                  "Call Active",
                                  Icons.phone,
                                  AppColors.greyColor2,
                                  () => _handleCallEnd(),
                                ),
                              ),
                              
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _callActionButton(
                                  "Pickup",
                                  Icons.phone,
                                  AppColors.lightBlue,
                                  () => _startCall(order.pickupPhoneNo.toString(), 'pickup', order),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _callActionButton(
                                  "Consignee ",
                                  Icons.phone,
                                  AppColors.blue,
                                  () => _startCall(order.consigneeMobileNo.toString(), 'consignee', order),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _callActionButton(
                                  "WhatsApp ",
                                  Icons.chat,
                                  Colors.green,
                                  () => utils.openWhtsApp(isPicked
                                      ? order.consigneeMobileNo.toString()
                                      : order.pickupPhoneNo.toString()),
                                ),
                              ),
                            ],
                          ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              controller.viewAcceptView.value = true;
                              controller.minimizeOrderView.value = true;
                              controller.bottomBarListType.value = 1;
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.primaryThemeColor,
                                    width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "Update Order",
                                style: TextStyle(
                                  color: AppColors.primaryThemeColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: isPicked,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                controller.selectedOrder.value = hasCurrent
                                    ? controller.currentLocationOrders.first
                                    : controller.ordersList.first;
                                bool isUpdated =
                                    await controller.updateOrder(OFD);
                                if (isUpdated) {
                                  controller.startGuidedNavigation();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 11, horizontal: 18),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryThemeColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryThemeColor
                                          .withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "Mark OFD",
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // ── All Orders header ────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                utils.tvCustom("All Orders", AppColors.white, 16),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${controller.ordersList.length}",
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Orders list ──────────────────────────────────────────
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.ordersList.length,
              itemBuilder: (context, index) {
                var order = controller.ordersList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      controller.selectedOrder.value = order;
                      await controller.setMarkers();
                      controller.viewAcceptView.value = false;
                      controller.bottomBarListType.value = 0;
                      controller.minimizeOrderView.value = true;
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors
                                        .primaryThemeColor
                                        .withOpacity(0.12),
                                    child: Text(
                                      (order.consigneeName ?? "?")
                                          .isNotEmpty
                                          ? order.consigneeName![0]
                                              .toUpperCase()
                                          : "?",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryThemeColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${order.consigneeName}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${order.sla_in_hours}h",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          Divider(color: Colors.grey.shade100, height: 1),
                          const SizedBox(height: 10),

                          // AWB + Ref row
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children:[ Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 189, 95, 0).withOpacity(1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${order.status}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),]
                              ),
                               const SizedBox(width: 8),
                              customRow("Awb", "${order.awbNo}"),
                              const SizedBox(width: 8),
                              customRow("Ref", "${order.orderRefNumber}"),
                              const SizedBox(width: 8),
                              customRow("Item", "${order.itemName}"),
                              customRow("Qty.", "${order.quantity}"),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Distance + Time modern pills
                          Row(
                            children: [
                              _statPill(
                                Icons.route_rounded,
                                order.distance ?? "-",
                                Colors.blue.shade50,
                                Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              _statPill(
                                Icons.access_time_filled_rounded,
                                order.duration ?? "-",
                                Colors.purple.shade50,
                                Colors.purple.shade700,
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Call buttons row for list item
                          Obx(() {
                            bool isThisOrderOnCall = controller.hasOngoingCall.value &&
                                controller.ongoingCallAwbNo.value == order.awbNo;
                            return Row(
                              children: [
                                if (isThisOrderOnCall)
                                  Expanded(
                                    child: _callActionButton(
                                      "End Call",
                                      Icons.phone,
                                      AppColors.red,
                                      () => _handleCallEnd(),
                                    ),
                                  )
                                else if (controller.hasOngoingCall.value)
                                  Expanded(
                                    child: _callActionButton(
                                      "Call Active",
                                      Icons.phone,
                                      AppColors.greyColor4,
                                      () => utils.errorSnackBar("Ongoing Call", "Cannot initiate another call"),
                                    ),
                                  )
                                else ...[
                                  Expanded(
                                    child: _callActionButton(
                                      "Pickup",
                                      Icons.phone,
                                      AppColors.lightBlue,
                                      () => _startCall(order.pickupPhoneNo.toString(), 'pickup', order),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _callActionButton(
                                      "Consignee",
                                      Icons.phone,
                                      AppColors.blue,
                                      () => _startCall(order.consigneeMobileNo.toString(), 'consignee', order),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _callActionButton(
                                      "WhatsApp",
                                      Icons.chat,
                                      Colors.green,
                                      () => utils.openWhtsApp(order.pickupPhoneNo.toString()),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  ),
),

        body: SafeArea(
          child: Obx(() =>
          controller.isLoading.value ?
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    height: 150,
                    width: Get.width - 50,
                    child: Image.asset(appLogo, color: Get.isDarkMode
                        ? AppColors.primaryThemeColor
                        : null,)),
                utils.iosProgressIndicator(AppColors.primaryThemeColor,
                    "Loading Maps Please wait..."),
                const SizedBox(
                  height: 20,
                ),
                Obx(() {
                  return utils.tvCustom(controller.currentHintText,
                      AppColors.primaryThemeColor, 15);
                }),
              
              ],
            ),
          )
              : Container(
            child: controller.ordersList.isEmpty ? Center(
              child: utils.noDataFoundWidget("No Order For Pickup/Delivery"),
            ) : Stack(children: [

              controller.initializeNavigation.value
                  ?
                   GoogleMapsNavigationView(
                key: ValueKey(controller.mapType),
                gestureRecognizers: Set()
                  ..add(Factory<PanGestureRecognizer>(
                          () => PanGestureRecognizer()))..add(
                      Factory<ScaleGestureRecognizer>(
                              () => ScaleGestureRecognizer())),
                onViewCreated: _onViewCreated,
                initialMapType: controller.mapType,
                initialNavigationUIEnabledPreference:
                NavigationUIEnabledPreference.automatic,
                initialCameraPosition: CameraPosition(
                  target: controller.currentLocation!,
                  zoom: 14,
                ),
                onMarkerClicked: (value) async {
                  if (value != "current_location") {
                    Get.defaultDialog(
                      title: "Confirm Destination",
                      middleText: "Do you want to set this order as your current active destination?",
                      textConfirm: "Yes",
                      textCancel: "No",
                      confirmTextColor: Colors.white,
                      buttonColor: AppColors.primaryThemeColor,
                      onConfirm: () async {
                        Get.back(); 
                        controller.selectedOrderAwbId.value = value;
                        await controller.selectedLocationOrders();
                        controller.viewAcceptView.value = true;
                        controller.bottomBarListType.value = 0;
                      },
                    );
                  } else {
                    if (kDebugMode) {
                      print("Marker not found in map.");
                    }
                  }
                },
                
              )
                  : Center(
                child: utils.iosProgressIndicator(
                    AppColors.primaryThemeColor,
                    "Loading maps please wait..."),

              ),
              
              Obx(() {
                return Visibility(
                  visible: controller.currentLocationOrders.isNotEmpty
                      ? controller.currentLocationOrders.first.status ==
                      REACHED || controller
                      .markUnDelivered.value || controller
                      .markDelivered.value : controller.ordersList.first
                      .status == REACHED || controller
                      .markUnDelivered.value || controller
                      .markDelivered.value,
                  child: Positioned(
                      top: 100,
                      left: 10,
                      child: Container(
                          decoration: utils.boxDecorationWhite(),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Obx(() {
                                  return CircularCountDownTimer(
                                    duration: int.tryParse(
                                        controller.currentLocationOrders.isNotEmpty ? controller.currentLocationOrders.first.status == REACHED ? controller.currentLocationOrders.first.pickup_buffer_time_in_minutes! : controller.currentLocationOrders.first.dropoff_buffer_time_in_minutes!
                                            : controller.ordersList.first.status == REACHED ? controller.ordersList.first.pickup_buffer_time_in_minutes! :
                                        controller.ordersList.first.dropoff_buffer_time_in_minutes!)! *
                                        60,
                                    initialDuration: 0,
                                    controller: CountDownController(),
                                    width: 80,
                                    height: 80,
                                    ringColor: Get.isDarkMode
                                        ? AppColors.white
                                        : Colors.grey[300]!,
                                    fillColor: AppColors.green,
                                    backgroundColor: Get.isDarkMode ? AppColors
                                        .greyColor10 : Colors.white,
                                    isReverseAnimation: true,
                                    isReverse: true,
                                    autoStart: true,
                                    strokeWidth: 5.0,
                                    textAlign: TextAlign.center,
                                    textStyle: TextStyle(
                                        fontSize: 12,
                                        color: Get.isDarkMode
                                            ? AppColors.white
                                            : Colors.black),
                                    timeFormatterFunction: (
                                        defaultFormatterFunction, duration) {
                                      if (duration.inSeconds == 0) {
                                        return "00:00";
                                      } else {
                                        return Function.apply(
                                            defaultFormatterFunction,
                                            [duration]);
                                      }
                                    },
                                  );
                                }),
                                const SizedBox(height: 5,),
                                Text("Buffer Time", style: TextStyle(
                                    color: Get.isDarkMode
                                        ? AppColors.white
                                        : Colors.black,
                                    fontSize: Get.context!.isPhone ? 10 : 13
                                ),
                                  textAlign: TextAlign.center,)
                              ],
                            ),
                          )
                      )
                  ),
                );
              }),

           
            Positioned(
                  bottom: 1,
                  right: 10,
                  child: Row(
                    children: [
                      Visibility(
                        visible: true,
                       // visible: !controller.isNavigationRunning.value,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: InkWell(
                            onTap: () {
                              controller.startGuidedNavigation();
                            },
                            child: Container(
                              height: GetPlatform.isMobile ? 60 : 100,
                              width: GetPlatform.isMobile  ? 60 : 100,
                              decoration: utils.boxDecorationWhite(),
                              child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Column(
                                    children: [
                                      Icon(Icons.navigation,
                                          size: enableMapType.value
                                              ? GetPlatform.isMobile 
                                              ? 30
                                              : 50
                                              : GetPlatform.isMobile 
                                              ? 35
                                              : 50,
                                          color: AppColors.selectedBlue),
                                      Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          enableMapType.value
                                              ? "Start"
                                              : "Start",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize:
                                              context.isPhone ? 10 : 20),
                                        ),
                                      )
                                    ],
                                  )),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          controller.mapType =
                          (controller.mapType == MapType.normal)
                              ? MapType.hybrid
                              : MapType.normal;
                          enableMapType.toggle();
                        },
                        child: Obx(() {
                          return Container(
                              height: context.isPhone ? 60 : 100,
                              width: context.isPhone ? 60 : 100,
                              decoration: utils.boxDecorationWhite(),
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Column(
                                  children: [
                                    Icon(Icons.map,
                                        size: enableMapType.value
                                            ? context.isPhone
                                            ? 30
                                            : 50
                                            : context.isPhone
                                            ? 35
                                            : 55,
                                        color: enableMapType.value
                                            ? AppColors.greyColor4
                                            : AppColors.selectedBlue),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        enableMapType.value
                                            ? "Normal"
                                            : "Satellite",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize:
                                            context.isPhone ? 10 : 20),
                                      ),
                                    )
                                  ],
                                ),
                              ));
                        }),
                      ),
                      
                    ],
                  )),
              
            Obx(() {
                return Visibility(
                  visible: controller.viewAcceptView.value,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    
                    child: Visibility(
                      visible: controller.minimizeOrderView.value,
                      child: Container(
                        decoration: utils.boxDecorationCustomColor(AppColors.white),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Wrap(
                            
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  utils.tvCustom(
                                      '${controller.currentIndex.value}/${controller.ordersList.length.toString()}',
                                      AppColors.primaryThemeColor,
                                      14),
                                      const SizedBox(width: 10,),
                                  Visibility(
                                    visible: controller
                                        .bottomBarListType
                                        .value == 0,
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: InkWell(
                                          onTap: () {
                                            controller.viewAcceptView.value = false;
                                          },
                                          child: const Icon(
                                            Icons.cancel,
                                            color: AppColors.red,
                                            size: 20,
                                          )),
                                    ),
                                  ),
                                  Visibility(
                                    visible: controller
                                        .bottomBarListType
                                        .value == 1,
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: InkWell(
                                          onTap: () {
                                            controller.minimizeOrderView.value = false;
                                          },
                                          child: utils.tvCustom( "Hide", AppColors.primaryThemeColor, 15)),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: InkWell(
                                      onTap: () {
                                        if (controller.selectedOrderIndex.value >
                                            0) {
                                          controller.selectedOrderIndex.value--;
                                          controller.pageController.animateToPage(
                                            controller.selectedOrderIndex.value,
                                            duration:
                                            const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      },
                                      child: const Icon(
                                        Icons.arrow_back_ios,
                                        color: AppColors.primaryThemeColor,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 10,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 440,
                                        minHeight: 350
                                        ),
                                      child: Center(
                                        child: controller.currentLocationOrders.isNotEmpty ?  PageView.builder(
                                            scrollDirection: Axis.horizontal,
                                            controller: controller.pageController,
                                            itemCount: controller.bottomBarListType.value == 0
                                                ? controller.ordersList.length
                                                : controller.currentLocationOrders.length,
                                            itemBuilder: (context, position) {
                                              return SingleChildScrollView(
                                                child: ClickedOrderItem(
                                                  orderData: controller.bottomBarListType
                                                      .value == 0
                                                      ? controller
                                                      .ordersList[position]
                                                      : controller
                                                      .currentLocationOrders[
                                                  position],
                                                  onClick: (clickedOrder, type) async {
                                                    controller.selectedOrder.value =
                                                        clickedOrder;
                                                    await controller.setMarkers();
                                                    if (type == updateStatus) {
                                                      if (clickedOrder.status ==
                                                          REACHED) {
                                                        bool isTrue = await controller
                                                            .calculateBufferTime(
                                                            DateTime.now(),
                                                            PICKED);
                                                          controller.updateOrder(
                                                              PICKED);
                                                        
                                                      } else
                                                      if (clickedOrder.status ==
                                                          ASSIGNED ||
                                                          clickedOrder.status ==
                                                              RE_ASSIGNED) {
                                                        controller.updateOrder(
                                                            REACHED);
                                                        controller.startTime =
                                                            DateTime.now();
                                                      } else
                                                      if (clickedOrder.status ==
                                                          PICKED) {
                                                        controller.updateOrder(
                                                            OFD);
                                                      }
                                                    } else
                                                    if (type == updateOrder) {
                                                      controller.viewAcceptView
                                                          .value = false;
                                                      controller
                                                          .isUpdateCardVisibleForUpdate
                                                          .value = true;
                                                    }
                                                  },
                                                  listType: controller.bottomBarListType
                                                      .value ==
                                                      0
                                                      ? 0
                                                      : 1) 
                                                      );
                                            }): Center(child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                        utils.tvCustom("No nearby orders available to update. Please move closer to the pick-up or delivery location. Orders can only be updated when you are within a 300-meter radius of the location.", AppColors.black, 18)
                                                      ],),),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: InkWell(
                                      onTap: () {
                                        if (controller
                                            .selectedOrderIndex.value <
                                            controller.ordersList.length -
                                                1) {
                                          controller
                                              .selectedOrderIndex.value++;
                                          controller.pageController
                                              .animateToPage(
                                            controller
                                                .selectedOrderIndex.value,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      },
                                      child: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: AppColors.primaryThemeColor,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
          
            Obx(() {
                return Visibility(
                  visible: controller.isUpdateCardVisibleForUpdate.value,
                  child: SafeArea(
                    child: Center(
                      child: Container(
                        height: 700,
                        child: Stack(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0,vertical: 80),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Obx(() {
                                    //   return AnimatedContainer(
                                    //       width: showNotificationView.value
                                    //           ? 250.0
                                    //           : 50.0,
                                    //       height: showNotificationView.value
                                    //           ? 350.0
                                    //           : 50.0,
                                    //       decoration: utils.boxDecorationWhite(),
                                    //       alignment: showNotificationView.value
                                    //           ? Alignment.center
                                    //           : AlignmentDirectional.topCenter,
                                    //       duration: const Duration(seconds: 1),
                                    //       curve: Curves.fastOutSlowIn,
                                    //       child: Padding(
                                    //           padding: const EdgeInsets.all(8.0),
                                    //           child: showNotificationView.value
                                    //               ? Column(
                                    //                   children: [
                                    //                     Row(
                                    //                       mainAxisAlignment:
                                    //                           MainAxisAlignment
                                    //                               .spaceBetween,
                                    //                       children: [
                                    //                         utils.tvCustom(
                                    //                             "Order Notifications",
                                    //                             AppColors
                                    //                                 .primaryThemeColor,
                                    //                             13),
                                    //                         InkWell(
                                    //                           onTap: () {
                                    //                             setState(() {
                                    //                               controller.getNotification();
                                    //                               showNotificationView
                                    //                                   .toggle();
                                    //                             });
                                    //                           },
                                    //                           child: const Icon(
                                    //                             Icons.close,
                                    //                             color: AppColors.red,
                                    //                           ),
                                    //                         )
                                    //                       ],
                                    //                     ),
                                    //                     utils.dividerBlack(),
                                    //                     Expanded(
                                    //                       child: ListView.builder(
                                    //                           itemCount: controller.notificationList.length,
                                    //                           itemBuilder: (context, pos) {
                                    //                             return ItemMapNotifications(
                                    //                                 controller.notificationList[pos]);
                                    //                           }),
                                    //                     )
                                    //                   ],
                                    //                 )
                                    //               : InkWell(
                                    //                   onTap: () {
                                    //                     setState(() {
                                    //                       showNotificationView
                                    //                           .toggle();
                                    //                     });
                                    //                   },
                                    //                   child: const Center(
                                    //                     child: Icon(
                                    //                       Icons.notifications,
                                    //                       color: AppColors
                                    //                           .primaryThemeColor,
                                    //                     ),
                                    //                   ))));
                                    // }),
                                    // InkWell(
                                    //   onTap: () {
                                    //     enableMapLiveCamera.toggle();
                                    //   },
                                    //   child: Obx(() {
                                    //     return Container(
                                    //       height: 50,
                                    //       width: 50,
                                    //       decoration: utils.boxDecorationWhite(),
                                    //       child: Icon(Icons.share_location_sharp,
                                    //           size:
                                    //               enableMapLiveCamera.value ? 36 : 30,
                                    //           color: enableMapLiveCamera.value
                                    //               ? AppColors.selectedBlue
                                    //               : AppColors.greyColor4),
                                    //     );
                                    //   }),
                                    // ),
                                  ]),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    bottom:
                                    controller.markDelivered.value ? 10 : 100),
                                child: Container(
                                  decoration: utils.boxDecorationWhite(),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Obx(() {
                                        return Column(
                                          children: [
                                            Column(
                                              children: [
                                                Visibility(
                                                  visible: controller
                                                      .markDelivered.value ||
                                                      controller
                                                          .markUnDelivered.value,
                                                  child: Align(
                                                      alignment: Alignment.topRight,
                                                      child: InkWell(
                                                          onTap: () {
                                                            controller.markDelivered
                                                                .value = false;
                                                            controller
                                                                .markUnDelivered
                                                                .value = false;
                                                          },
                                                          child: const Icon(
                                                              Icons.cancel,
                                                              color:
                                                              AppColors.red))),
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                                // Row(
                                                //   mainAxisAlignment:
                                                //       MainAxisAlignment
                                                //           .spaceBetween,
                                                //   children: [
                                                //     utils.tvMedium(
                                                //         "Pickup to Delivery Distance"),
                                                //     utils.tvCustom(
                                                //         orderDistanceByGoogle.value,
                                                //         AppColors.blue,
                                                //         10),
                                                //   ],
                                                // ),
                                                // Row(
                                                //   mainAxisAlignment:
                                                //       MainAxisAlignment
                                                //           .spaceBetween,
                                                //   children: [
                                                //     utils.tvMedium(
                                                //         "Estimated Time By Google"),
                                                //     utils.tvCustom(
                                                //         orderDurationByGoogle.value,
                                                //         AppColors.primaryThemeColor,
                                                //         10),
                                                //   ],
                                                // ),
                                                Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    utils.tvMedium("Order Number"),
                                                    utils.tvMedium(controller
                                                        .selectedOrder
                                                        .value
                                                        .awbNo ??
                                                        ""),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    utils.tvMedium("status"),
                                                    utils.tvCustom(
                                                        controller.selectedOrder
                                                            .value.status ??
                                                            "",
                                                        AppColors.green,
                                                        10),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    utils.tvMedium("Item"),
                                                    utils.tvCustom(
                                                        "${controller.selectedOrder
                                                            .value
                                                            .itemName}(${controller
                                                            .selectedOrder.value
                                                            .quantity})",
                                                        AppColors.black,
                                                        10),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    utils.tvMedium("Order Amount"),
                                                    utils.tvCustom(
                                                        "${controller.selectedOrder
                                                            .value.orderAmount}(Qar)",
                                                        AppColors.black,
                                                        10),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    utils.tvMedium("Merchant Name"),
                                                    utils.tvCustom(
                                                        controller
                                                            .selectedOrder
                                                            .value
                                                            .merchantName ??
                                                            "",
                                                        AppColors.black,
                                                        10),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Obx(() {
                                                  return Visibility(
                                                      visible: controller
                                                          .markDelivered
                                                          .value ||
                                                          controller.markUnDelivered
                                                              .value,
                                                      child: Column(
                                                        children: [
                                                          Padding(
                                                            padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 5),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                              children: [
                                                                utils.tvCustom(
                                                                    "Image Proof",
                                                                    AppColors
                                                                        .primaryThemeColor,
                                                                    10),
                                                                InkWell(
                                                                    onTap: () {
                                                                      controller
                                                                          .captureImage(
                                                                          ImageSource
                                                                              .camera,
                                                                          imageOne);
                                                                    },
                                                                    child:
                                                                    const Icon(
                                                                      Icons.refresh,
                                                                      color:
                                                                      AppColors
                                                                          .blue,
                                                                      size: 20,
                                                                    ))
                                                              ],
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                            const EdgeInsets
                                                                .all(5),
                                                            child: Container(
                                                              height: 200,
                                                              width:
                                                              double.infinity,
                                                              decoration: utils
                                                                  .roundedBorder(
                                                                  AppColors
                                                                      .primaryThemeColor,
                                                                  5),
                                                              child: controller
                                                                  .image
                                                                  .value !=
                                                                  null
                                                                  ? Image.file(
                                                                controller
                                                                    .image
                                                                    .value!,
                                                                fit: BoxFit
                                                                    .fill,
                                                              )
                                                                  : InkWell(
                                                                onTap: () {
                                                                  controller
                                                                      .captureImage(
                                                                      ImageSource
                                                                          .camera,
                                                                      imageOne);
                                                                },
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                                  children: [
                                                                    const Icon(
                                                                      Icons
                                                                          .camera,
                                                                      size:
                                                                      80,
                                                                      color: AppColors
                                                                          .primaryThemeColor,
                                                                    ),
                                                                    utils.tvCustom(
                                                                        "capture Image",
                                                                        AppColors
                                                                            .primaryThemeColor,
                                                                        10)
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 5),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                              children: [
                                                                utils.tvCustom(
                                                                    "Delivery Proof (optional)",
                                                                    AppColors
                                                                        .primaryThemeColor,
                                                                    10),
                                                                InkWell(
                                                                    onTap: () {
                                                                      utils
                                                                          .showCustomDialog(
                                                                        title:
                                                                        "Need Your Action",
                                                                        middleText:
                                                                        "Choose Image Source",
                                                                        buttons: [
                                                                          TextButton
                                                                              .icon(
                                                                            onPressed:
                                                                                () {
                                                                              controller
                                                                                  .captureImage(
                                                                                  ImageSource
                                                                                      .camera,
                                                                                  imageTwo);
                                                                              Get
                                                                                  .back();
                                                                            },
                                                                            icon: const Icon(
                                                                                Icons
                                                                                    .camera_alt,
                                                                                color:
                                                                                AppColors
                                                                                    .primaryThemeColor),
                                                                            label: const Text(
                                                                                "Camera",
                                                                                style:
                                                                                TextStyle(
                                                                                    color: AppColors
                                                                                        .primaryThemeColor)),
                                                                          ),
                                                                           TextButton
                                                                                .icon(
                                                                              onPressed:
                                                                                  () {
                                                                                controller
                                                                                    .captureImage(
                                                                                    ImageSource
                                                                                        .gallery,
                                                                                    imageTwo);
                                                                                Get
                                                                                    .back();
                                                                              },
                                                                              icon: const Icon(
                                                                                  Icons
                                                                                      .image,
                                                                                  color:
                                                                                  AppColors
                                                                                      .lightBlue),
                                                                              label: const Text(
                                                                                  "Gallery",
                                                                                  style:
                                                                                  TextStyle(
                                                                                      color: AppColors
                                                                                          .lightBlue)),
                                                                            )
                                                                          
                                                                        ],
                                                                      );
                                                                    },
                                                                    child:
                                                                    const Icon(
                                                                      Icons
                                                                          .edit_note_rounded,
                                                                      color:
                                                                      AppColors
                                                                          .blue,
                                                                      size: 20,
                                                                    ))
                                                              ],
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                            const EdgeInsets.all(5),
                                                            child: Container(
                                                              height: 200,
                                                              width: double.infinity,
                                                              decoration: utils.roundedBorder(AppColors.lightBlue,5),
                                                              child: controller
                                                                  .paymentProof
                                                                  .value != null
                                                                  ? Image.file(
                                                                controller
                                                                    .paymentProof
                                                                    .value!,
                                                                fit: BoxFit
                                                                    .fill,
                                                              )
                                                                  : InkWell(
                                                                onTap: () {
                                                                  utils
                                                                      .showCustomDialog(
                                                                    title:
                                                                    "Need Your Action",
                                                                    middleText:
                                                                    "Choose Image Source",
                                                                    buttons: [
                                                                      TextButton
                                                                          .icon(
                                                                        onPressed:
                                                                            () {
                                                                          controller
                                                                              .captureImage(
                                                                              ImageSource
                                                                                  .camera,
                                                                              imageTwo);
                                                                          Get.back();
                                                                        },
                                                                        icon: const Icon(
                                                                            Icons
                                                                                .camera_alt,
                                                                            color: AppColors
                                                                                .primaryThemeColor),
                                                                        label: const Text(
                                                                            "Camera",
                                                                            style: TextStyle(
                                                                                color: AppColors
                                                                                    .primaryThemeColor)),
                                                                      ),
                                                                       TextButton
                                                                            .icon(
                                                                          onPressed: () {
                                                                            controller
                                                                                .captureImage(
                                                                                ImageSource
                                                                                    .gallery,
                                                                                imageTwo);
                                                                            Get
                                                                                .back();
                                                                          },
                                                                          icon: const Icon(
                                                                              Icons
                                                                                  .image,
                                                                              color: AppColors
                                                                                  .lightBlue),
                                                                          label: const Text(
                                                                              "Gallery",
                                                                              style: TextStyle(
                                                                                  color: AppColors
                                                                                      .lightBlue)),
                                                                        
                                                                      ),
                                                                    ],
                                                                  );
                                                                },
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                                  children: [
                                                                    const Icon(
                                                                      Icons
                                                                          .image_outlined,
                                                                      size:
                                                                      80,
                                                                      color: AppColors
                                                                          .lightBlue,
                                                                    ),
                                                                    utils.tvCustom(
                                                                        "capture/select Image",
                                                                        AppColors
                                                                            .lightBlue,
                                                                        10)
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Visibility(
                                                            visible: controller
                                                                .markDelivered
                                                                .value,
                                                            child: Column(
                                                              children: [
                                                                Padding(
                                                                  padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                      5),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                    children: [
                                                                      utils.tvCustom(
                                                                          "Signature (optional)",
                                                                          AppColors
                                                                              .primaryThemeColor,
                                                                          10),
                                                                      InkWell(
                                                                          onTap:
                                                                              () {
                                                                            controller
                                                                                .signatureController
                                                                                .disabled =
                                                                            false;
                                                                            controller
                                                                                .signatureController
                                                                                .clear();
                                                                            controller
                                                                                .signImage
                                                                                ?.clear();
                                                                            controller
                                                                                .signatureFile =
                                                                            null;
                                                                          },
                                                                          child:
                                                                          const Icon(
                                                                            Icons
                                                                                .mode_edit,
                                                                            color: AppColors
                                                                                .blue,
                                                                            size:
                                                                            20,
                                                                          ))
                                                                    ],
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                  const EdgeInsets
                                                                      .all(5.0),
                                                                  child: Container(
                                                                    decoration: utils
                                                                        .roundedBorder(
                                                                        AppColors
                                                                            .blue,
                                                                        3),
                                                                    child: Padding(
                                                                      padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                      child:
                                                                      Signature(
                                                                        controller:
                                                                        controller
                                                                            .signatureController,
                                                                        width: 300,
                                                                        height: 180,
                                                                        backgroundColor:
                                                                        Colors
                                                                            .white,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Visibility(
                                                              visible: controller
                                                                  .markUnDelivered
                                                                  .value,
                                                              child: utils
                                                                  .iconButtonWithRoundedBorder(
                                                                  controller
                                                                      .selectedReason
                                                                      .value ==
                                                                      ""
                                                                      ? "Select Reason"
                                                                      : controller
                                                                      .selectedReason
                                                                      .value,
                                                                  45, () {
                                                                controller
                                                                    .popUpWindowReasons();
                                                              },
                                                                  Icons
                                                                      .arrow_drop_down_circle_outlined,
                                                                  AppColors
                                                                      .primaryThemeColor,
                                                                  Icons
                                                                      .keyboard_return,
                                                                  1,
                                                                  AppColors
                                                                      .primaryThemeColor)),
                                                          const SizedBox(
                                                            height: 10,
                                                          )
                                                        ],
                                                      ));
                                                })
                                              ],
                                            ),
                                            Obx(() {
                                              return Align(
                                                alignment: Alignment.bottomCenter,
                                                child: Visibility(
                                                  visible: !controller.markUnDelivered
                                                      .value
                                                      &&
                                                      !controller.markDelivered.value
                                                      &&
                                                      controller.selectedOrder.value
                                                          .status == OFD,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                    children: [
                        
                                                      Row(children: [
                                                        utils.iconButton(
                                                            "Un-Deliver", () {
                                                          controller
                                                              .markUnDelivered
                                                              .value = true;
                                                          controller.startTime =
                                                              DateTime.now();
                                                        },
                                                            Icons.cancel,
                                                            AppColors.red,
                                                            AppColors.white),
                                                        const SizedBox(
                                                          width: 90,
                                                        ),
                                                        utils.iconButton(
                                                            "Mark Deliver", () {
                                                          controller
                                                              .markDelivered
                                                              .value = true;
                                                          controller.startTime =
                                                              DateTime.now();
                                                        },
                                                            Icons.check_box,
                                                            AppColors
                                                                .greenLight,
                                                            AppColors.white),
                                                      ])
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                            Obx(() {
                                              return Align(
                                                alignment: Alignment.bottomCenter,
                                                child: Visibility(
                                                    visible: controller
                                                        .selectedOrder
                                                        .value
                                                        .status ==
                                                        OFD &&
                                                        controller
                                                            .markDelivered.value,
                                                    child: utils.iconButton(
                                                        "Mark Delivered", () async {
                                                      bool isTrue = await controller
                                                          .calculateBufferTime(
                                                          DateTime.now(),
                                                          DELIVERED);
                                                      if (isTrue) {
                                                        if (controller
                                                            .deliveredImage !=
                                                            null) {
                                                             if (_isCallInitiated ){
                                                              _handleCallEnd();
                                                             }
                                                          var isDElivered =
                                                          await controller
                                                              .updateOrder(
                                                              DELIVERED);
                                                          if (isDElivered == true) {
                                                            clearImageSign();
                                                          }
                                                        } else {
                                                          utils.errorSnackBar(
                                                              " Error !",
                                                              "Delivery Image required");
                                                        }
                                                      }
                                                      // Get.toNamed(Routes.signatureImageScreen);
                                                    },
                                                        Icons.check_box,
                                                        AppColors.greenLight,
                                                        AppColors.white)),
                                              );
                                            }),
                                            Obx(() {
                                              return Align(
                                                alignment: Alignment.bottomCenter,
                                                child: Visibility(
                                                    visible: controller
                                                        .selectedOrder
                                                        .value
                                                        .status ==
                                                        OFD &&
                                                        controller
                                                            .markUnDelivered.value,
                                                    child: utils.iconButton(
                                                        "Mark Un-Delivered",
                                                            () async {
                                                          bool isTrue = await controller
                                                              .calculateBufferTime(
                                                              DateTime.now(),
                                                              DELIVERED);
                                                          if (isTrue) {
                                                            var isUpdated =
                                                            await controller
                                                                .updateOrder(
                                                                  
                                                                UNDELIVERED);
                                                            if (isUpdated ==
                                                                true) {
                                                              clearImageSign();
                                                            }
                                                            if (_isCallInitiated ){
                                                              _handleCallEnd();
                                                             }
                                                          }
                                                        },
                        
                                                        Icons
                                                            .cancel_presentation_outlined,
                                                        AppColors.red,
                                                        AppColors.white)),
                                              );
                                            }),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            Obx(() {
                if (controller.showCallConfirmation.value) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showNonCancellableCallConfirmationDialog();
                  });
                }
                return const SizedBox.shrink();
              }),
            
            Positioned(
                top: 20,
                left: 15,
                right: 15,
                child: 
                    Obx(() {
              final bool hasCurrent =
                  controller.currentLocationOrders.isNotEmpty;
              final order = hasCurrent
                  ? controller.currentLocationOrders.first
                  : controller.ordersList.first;
              final bool isPicked = order.status == PICKED;

              return Visibility(
                visible: isPicked,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryThemeColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              "Current Order",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryThemeColor,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPicked
                                  ? Colors.green.withOpacity(0.12)
                                  : Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              order.status ?? "",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isPicked ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("AWB No.",
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500)),
                                const SizedBox(height: 2),
                                Text(
                                  order.awbNo.toString(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          slaTimer(
                            60.sp,
                            60.sp,
                            order.createdAt.toString(),
                            int.tryParse(order.sla_in_hours.toString()) ?? 0,
                            10,
                          ),
                        ],
                      ),
                
                      const SizedBox(height: 14),
                      Divider(color: Colors.grey.shade200, height: 1),
                      const SizedBox(height: 14),
                
                      // Location info chips
                      _modernInfoRow(
                          Icons.my_location_rounded, "Zone", order.consigneeZone ?? ""),
                      const SizedBox(height: 8),
                      _modernInfoRow(
                          Icons.signpost_rounded, "Street", order.consigneeStreetNumber ?? ""),
                      const SizedBox(height: 8),
                      _modernInfoRow(
                          Icons.apartment_rounded, "Building", order.consigneeBuildingNo ?? ""),
                
                     
                      Visibility(
                        visible: isPicked,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),
                            Divider(color: Colors.grey.shade200, height: 1),
                            const SizedBox(height: 14),
                
                            // Distance + Time pills
                            Row(
                              children: [
                                _statPill(
                                  Icons.route_rounded,
                                  order.distance ?? "-",
                                  Colors.blue.shade50,
                                  Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                _statPill(
                                  Icons.access_time_rounded,
                                  order.duration ?? "-",
                                  Colors.purple.shade50,
                                  Colors.purple.shade700,
                                ),
                              ],
                            ),
                
                            const SizedBox(height: 12),
                            _modernInfoRow(Icons.timer_outlined, "SLA",
                                "${order.sla_in_hours} Hrs"),
                            const SizedBox(height: 8),
                            _modernInfoRow(Icons.currency_rupee_rounded,
                                "Amount", order.orderAmount ?? ""),
                            const SizedBox(height: 8),
                            _modernInfoRow(Icons.scale_rounded, "Weight",
                                order.weight ?? ""),
                            const SizedBox(height: 8),
                            _modernInfoRow(Icons.person_rounded,
                                "Consignee", order.consigneeName ?? ""),
                
                            const SizedBox(height: 14),
                            Divider(color: Colors.grey.shade200, height: 1),
                            const SizedBox(height: 14),
                
                            _addressBlock(Icons.radio_button_checked_rounded,
                                "Pick-Up", order.pickupAddress ?? "",
                                Colors.green),
                            const SizedBox(height: 10),
                            _addressBlock(Icons.location_on_rounded,
                                "Drop-Off", order.consigneeAddress ?? "",
                                Colors.red),
                          ],
                        ),
                      ),
                
                      const SizedBox(height: 14),
                
                      // Call buttons row
                      Obx(() => controller.hasOngoingCall.value
                          ? Row(
                              children: [
                                Expanded(
                                  child: _callActionButton(
                                    "Call Active",
                                    Icons.phone,
                                    AppColors.greyColor2,
                                    () => _handleCallEnd(),
                                  ),
                                ),
                                
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _callActionButton(
                                    "Pickup",
                                    Icons.phone,
                                    AppColors.lightBlue,
                                    () => _startCall(order.pickupPhoneNo.toString(), 'pickup', order),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _callActionButton(
                                    "Consignee ",
                                    Icons.phone,
                                    AppColors.blue,
                                    () => _startCall(order.consigneeMobileNo.toString(), 'consignee', order),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _callActionButton(
                                    "WhatsApp ",
                                    Icons.chat,
                                    Colors.green,
                                    () => utils.openWhtsApp(isPicked
                                        ? order.consigneeMobileNo.toString()
                                        : order.pickupPhoneNo.toString()),
                                  ),
                                ),
                              ],
                            ),
                      ),
                
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                controller.viewAcceptView.value = true;
                                controller.minimizeOrderView.value = true;
                                controller.bottomBarListType.value = 1;
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.primaryThemeColor,
                                      width: 1.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  "Update Order",
                                  style: TextStyle(
                                    color: AppColors.primaryThemeColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: isPicked,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  controller.selectedOrder.value = hasCurrent
                                      ? controller.currentLocationOrders.first
                                      : controller.ordersList.first;
                                  bool isUpdated =
                                      await controller.updateOrder(OFD);
                                  if (isUpdated) {
                                    controller.startGuidedNavigation();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 11, horizontal: 18),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryThemeColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryThemeColor
                                            .withOpacity(0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    "Mark OFD",
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
               ),
            
            Positioned(
                 top: 100,
                 child: Visibility(
                   visible: _isCallInitiated,
                   child: SizedBox(
                    height: 120,
                    width: Get.width,
                     child: Card(child: Padding(
                       padding: const EdgeInsets.all(8.0),
                       child: Column(
                         children: [
                            utils.tvCustom("Ongoing Call",AppColors.primaryThemeColor,15),
                             const SizedBox(height: 5,),
                            utils.tvCustom("${controller.callType == "pickup" ?controller.selectedCallOrder.value.pickupPhoneNo :controller.selectedCallOrder.value.consigneeMobileNo}", AppColors.black, 12),
                            const SizedBox(height: 10,),
                           Row(
                                          children: [
                                            Expanded(
                                              child: _callActionButton(
                                                "End Call",
                                                Icons.phone,
                                                AppColors.red,
                                                () => _handleCallEnd(),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.green.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.green),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        _currentCallDuration,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          color: AppColors.green,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                         ],
                       ),
                     ),),
                   ),
                 ),
               ),

              
            ]),
          ),
        ))))
        ;
  }

  // Future<void> _cameraToPosition(LatLng pos) async {
  //   final GoogleMapController controller = await _mapController.future;
  //   var zoomLevel = await controller.getZoomLevel();
  //   CameraPosition _newCameraPosition = CameraPosition(
  //     target: pos,
  //     zoom: 18,
  //   );
  //
  //   await controller.animateCamera(
  //     CameraUpdate.newCameraPosition(_newCameraPosition),
  //   );
  // }

  //
  //  void drawPolylineFromJson(dynamic jsonResponse) {
  //  final jsonData = jsonDecode(jsonResponse);
  //   final List<LatLng> polylineCoordinates = [];
  //
  //   if (jsonData["routes"].isNotEmpty) {
  //     final steps = jsonData["routes"][0]["legs"][0]["steps"];
  //     final legs = jsonData["routes"][0]["legs"][0];
  //     orderDurationByGoogle.value =  legs["duration"]["text"] ?? "";
  //     orderDistanceByGoogle.value =  legs["distance"]["text"] ?? "";
  //
  //     for (var step in steps) {
  //       String instruction = step["html_instructions"] ?? "Continue straight";
  //       double stepLat = step["end_location"]["lat"];
  //       double stepLng = step["end_location"]["lng"];
  //
  //       navigationSteps.add({
  //         "instruction": instruction.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
  //         "location": LatLng(stepLat, stepLng)
  //       });
  //       String encodedPolyline = step["polyline"]["points"];
  //       List<PointLatLng> decodedPoints = PolylinePoints().decodePolyline(encodedPolyline);
  //
  //       for (var point in decodedPoints) {
  //         polylineCoordinates.add(LatLng(point.latitude, point.longitude));
  //       }
  //     }
  //   }
  //
  //   generatePolyLineFromPoints(polylineCoordinates);
  // }

  // void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
  //   PolylineId id = PolylineId("poly");
  //   Polyline polyline = Polyline(
  //       polylineId: id,
  //       color: AppColors.primaryThemeColor,
  //       points: polylineCoordinates,
  //       width: 6);
  //   setState(() {
  //     polylines[id] = polyline;
  //   });
  // }

  void clearImageSign() {
    controller.deliveredImage = null;
    controller.image.value = null;
    controller.signatureFile = null;
    controller.signatureController.value.clear();
    controller.markDelivered.value = false;
    controller.markUnDelivered.value = false;
  }


Widget _modernInfoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 15, color: Colors.grey.shade500),
      const SizedBox(width: 6),
      Text(
        "$label: ",
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget _callActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _statPill(IconData icon, String value, Color bg, Color fg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: fg),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    ),
  );
}

Widget _addressBlock(
    IconData icon, String label, String address, Color accent) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 13, color: accent),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              address,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    ],
  );
}

// void showCustomMarker(OrdersData data, int type) {
//   showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return Wrap(
//           children: [
//             Column(
//               children: [
//                 Align(
//                   alignment: Alignment.topRight,
//                   child: InkWell(
//                       onTap: () {
//                         Get.back();
//                       },
//                       child: const Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: Icon(
//                           Icons.cancel,
//                           color: AppColors.red,
//                         ),
//                       )),
//                 ),
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     utils.tvCustom(
//                         type == 0
//                             ? "${data.merchantName!}\n${data.pickupAddress!},${data.pickupZoneNo!}"
//                             : "${data.consigneeName!}\n${data.consigneeAddress!},${data.consigneeStreetNumber!},${data.consigneeBuildingNo!},${data.consigneeUnitNo!},${data.consigneeZone!}",
//                         AppColors.black,
//                         14),
//                   ],
//                 ),
//                 const SizedBox(
//                   height: 5,
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     utils.tvRegular("Landmark", AppColors.black),
//                     utils.tvRegular(":", AppColors.black),
//                     utils.tvCustom(
//                         type == 0
//                             ? data.pickupLocationName
//                             : data.consigneeAddress,
//                         AppColors.blue,
//                         13)
//                   ],
//                 ),
//                 Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: utils.iconButtonWithRoundedBorder(
//                         "Navigate Address", 40, () {
//                       utils.openMaps(type == 0
//                           ? data.pickupAddress!
//                           : data.consigneeAddress!);
//                     },
//                         Icons.assistant_navigation,
//                         AppColors.primaryThemeColor,
//                         Icons.alt_route_rounded,
//                         2,
//                         AppColors.primaryThemeColor))
//               ],
//             )
//           ],
//         );
//       });
// }

// @override
// void dispose() async {
//   _locationSubscription.cancel();
//   await GoogleMapsNavigator.cleanup();
//   _navigationSessionInitialized = false;
//   await controller.navigationViewController?.clear();
//   super.dispose();
// }

/*getDeliveryAddress() async {
    var address = await getLatLangFromAddress(
        controller.selectedOrder.value.consigneeAddress);
    setState(() {
      if (controller.selectedOrder.value.dropoffLatitude != null &&
          controller.selectedOrder.value.dropoffLongitude != null) {
        deliveryLocation = LatLng(
          latitude: double.parse(
              controller.selectedOrder.value.dropoffLatitude ?? "0.0"),
          longitude: double.parse(
              controller.selectedOrder.value.dropoffLongitude ?? "0.0"),
        );
      } else {
        deliveryLocation = LatLng(
          latitude: address!.latitude,
          longitude: address.longitude,
        );
      }
    });*/
// }
}

// double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//   const R = 6371000;
//   final dLat = _toRadians(lat2 - lat1);
//   final dLon = _toRadians(lon2 - lon1);
//   final a = sin(dLat / 2) * sin(dLat / 2) +
//       cos(_toRadians(lat1)) *
//           cos(_toRadians(lat2)) *
//           sin(dLon / 2) *
//           sin(dLon / 2);
//   final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//   return R * c;
// }
//
// double _toRadians(double degree) {
//   return degree * pi / 180;
// }

// Future<List<LatLng>?> getPolylinePoints() async {
//   List<LatLng> polylineCoordinates = [];
//   try {
//     PolylinePoints polylinePoints = PolylinePoints();
//     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//       GOOGLE_MAPS_API_KEY,
//       PointLatLng(pickUpLocation.latitude, pickUpLocation.longitude),
//       PointLatLng(deliveryLocation!.latitude, deliveryLocation!.longitude),
//       travelMode: TravelMode.driving,
//     );
//     if (result.points.isNotEmpty) {
//       result.points.forEach((PointLatLng point) {
//         polylineCoordinates.add(LatLng(point.latitude, point.longitude));
//       });
//       orderDurationByGoogle.value = result.duration ?? "";
//       orderDistanceByGoogle.value = result.distance ?? "";
//     } else {
//       if (kDebugMode) {
//         print(result.errorMessage);
//       }
//     }
//     return polylineCoordinates;
//   } catch (e) {
//     utils.errorDialog(e.toString());
//     return null;
//   }
// }

// Future<void> getLocationUpdates() async {
//   bool _serviceEnabled;
//   PermissionStatus _permissionGranted;
//
//   _serviceEnabled = await _locationController.serviceEnabled();
//   if (!_serviceEnabled) {
//     _serviceEnabled = await _locationController.requestService();
//     if (!_serviceEnabled) {
//       return;
//     }
//   }
//
//   _permissionGranted = await _locationController.hasPermission();
//   if (_permissionGranted == PermissionStatus.denied) {
//     _permissionGranted = await _locationController.requestPermission();
//     if (_permissionGranted != PermissionStatus.granted) {
//       return;
//     }
//   }
//
//   if (!mounted) return;
//
//   _locationSubscription = _locationController.onLocationChanged
//       .listen((LocationData currentLocation) {
//     if (currentLocation.latitude != null &&
//         currentLocation.longitude != null) {
//       setState(() {
//         curentLocation =
//             LatLng(currentLocation.latitude!, currentLocation.longitude!);
//         if (enableMapLiveCamera.value) {
//           _cameraToPosition(curentLocation!);
//         }
//         double distanceInMeters = calculateDistance(
//           curentLocation!.latitude,
//           curentLocation!.longitude,
//           pickUpLocation.latitude,
//           pickUpLocation.longitude,
//         );
//         if (widget.mapView == 1) {
//           if (distanceInMeters <= 5000) {
//             isPickUpVisible.value = true;
//           }
//         }
//       });
//     }
//   });
// }
