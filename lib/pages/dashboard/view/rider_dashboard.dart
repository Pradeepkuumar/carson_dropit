import 'package:cached_network_image/cached_network_image.dart';
import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:carson_zyppy/pages/my_orders/orders/models/orders_model.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:carson_zyppy/utils/text_style_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../../app_pages/app_pages.dart';
import '../../../global/app_bar.dart';
import '../../../global/consts.dart';

const Color _amberOFD = Color(0xFFA67C00);
const Color _whatsAppGreen = Color(0xFF0BA30B);

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard>
    with WidgetsBindingObserver {
  final RiderDashboardController controller =
      Get.put(RiderDashboardController());

  var showMenu = false.obs;
  var selectedNavIndex = 0.obs;

  @override
  void initState() {
    controller.getUser();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.checkForUpdate();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(title: ""),
      bottomNavigationBar: Obx(() => controller.isAttendanceMarked.value
          ? _buildBottomNav(context)
          : const SizedBox.shrink()),
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() {
              return Visibility(
                visible: !controller.isAttendanceMarked.value,
                child: Container(
                  height: Get.height,
                  width: Get.width,
                  color: Get.isDarkMode ? AppColors.black : AppColors.white,
                  child: Center(
                    child: SizedBox(
                      height: 200,
                      width: Get.width - 50,
                      child: Image.asset(appLogo,
                          color: Get.isDarkMode
                              ? AppColors.primaryThemeColor
                              : null),
                    ),
                  ),
                ),
              );
            }),
            Obx(() {
              return Visibility(
                visible: controller.isAttendanceMarked.value,
                child: Container(
                  color: Get.isDarkMode ? AppColors.black : AppColors.greyColor1,
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () async {
                          await controller.getDashBoardData();
                          await controller.getC2CCDashBoardData();
                          await controller.getWhatsAppDashBoardData();
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(context),
                              Transform.translate(
                                offset: const Offset(0, -28),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    children: [
                                      _buildStatsCard(context),
                                      const SizedBox(height: 18),
                                      _buildQuickActions(context),
                                      const SizedBox(height: 18),
                                      _buildUpcomingOrders(context),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      _buildProfileMenuOverlay(context),
                      Obx(() => Visibility(
                            visible: controller.updateProfileDialog.value,
                            child: _buildUpdateProfileDialog(),
                          )),
                    ],
                  ),
                ),
              );
            }),
            Obx(() {
              return !controller.isAttendanceLoaded.value
                  ? Center(
                      child: utils.iosProgressIndicator(
                          AppColors.white, "Fetching Data..."))
                  : Visibility(
                      visible: !controller.isAttendanceMarked.value,
                      child: Container(
                        height: Get.height,
                        width: Get.width,
                        decoration: utils.boxDecorationWhite(),
                        child: Stack(
                          children: [
                            Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        utils.iconButtonWithoutBorderVertical(
                                            "Logout", () {
                                          utils.simpleDialog(
                                              "Do you want to Logout from app?",
                                              "", () async {
                                            var isLoggedOut =
                                                await controller.logout();
                                            if (isLoggedOut) {
                                              userRepository.deleteUser();
                                              Get.offAllNamed(Routes.auth);
                                            }
                                          }, () {
                                            Get.back();
                                          });
                                        }, Icons.logout, AppColors.red),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Obx(() => utils.tvCustom(
                                      "Welcome ${controller.riderName.toString().toUpperCase()} mark your attendance to start working",
                                      AppColors.primaryThemeColor,
                                      20)),
                                  Lottie.asset(ANIM_RIDER),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 50,
                                    ),
                                    child: utils.iconButtonWithRoundedBorder(
                                        "Sign-In", 45, () async {
                                      bool isSignIn =
                                          await controller.markAttendance(true);
                                      if (isSignIn) {
                                        controller.isAttendanceMarked.value =
                                            true;
                                      }
                                    },
                                        Icons.start,
                                        AppColors.primaryThemeColor,
                                        Icons.electric_bike,
                                        2.0,
                                        AppColors.primaryThemeColor),
                                  ),
                                  const Spacer(),
                                ]),
                          ],
                        ),
                      ),
                    );
            }),
            Obx(() => controller.isConsentGiven.value
                ? const SizedBox.shrink()
                : Container(
                    decoration: utils.boxDecorationWhite(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 100,
                            width: Get.width - 70,
                            child: Image.asset(appLogo,
                                color: Get.isDarkMode
                                    ? AppColors.primaryThemeColor
                                    : null),
                          ),
                          SizedBox(
                            height: 20.sp,
                          ),
                          utils.tvCustom("Location Permission Required",
                              AppColors.primaryThemeColor, 20.sp),
                          SizedBox(
                            height: 20.sp,
                          ),
                          utils.tvCustom("Background Location Permission",
                              AppColors.primaryThemeColor, 17.sp),
                          SizedBox(
                            height: 10.sp,
                          ),
                          utils.tvCustom(
                              "This app collects location data to enable order assignment and rider notifications even when the app is closed or not in use (background).",
                              AppColors.black,
                              15.sp),
                          SizedBox(
                            height: 14.sp,
                          ),
                          utils.tvCustom("Foreground Location Permission",
                              AppColors.primaryThemeColor, 17.sp),
                          SizedBox(
                            height: 10.sp,
                          ),
                          utils.tvCustom(
                              "Foreground location is used to provide navigation directions for delivering orders to customer addresses. Your location data will only be used to enhance delivery operations and ensure timely updates. We do not share your location data with any third parties.",
                              AppColors.black,
                              15.sp),
                          SizedBox(
                            height: 14.sp,
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: controller.checkBoxValue.value,
                                activeColor: AppColors.greenLight,
                                onChanged: (bool? value) {
                                  controller.checkBoxValue.toggle();
                                },
                              ),
                              utils.tvCustom(
                                  "I agree to share my location data as described above.",
                                  AppColors.blue,
                                  10.sp),
                            ],
                          ),
                          SizedBox(
                            height: 24.sp,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              utils.iconButton("Agree ", () async {
                                if (controller.checkBoxValue.value) {
                                  await box.write("isConsentGiven", true);
                                  controller.isConsentGiven.value = true;
                                  controller.updateLocation();
                                  controller.requestBackgroundPermission();
                                } else {
                                  utils.errorSnackBar("Error !",
                                      "Pls accept terms & conditions before proceed");
                                }
                              }, Icons.done, AppColors.greenLight,
                                  AppColors.white),
                              utils.iconButton("Disagree", () async {
                                bool isLoggedOut = await controller.logout();
                                if (isLoggedOut) {
                                  utils.simpleDialog("Action",
                                      "If you disagree with our location policy, you will be logged out of the app.",
                                      () async {
                                    var isLoggedOut = await controller.logout();
                                    if (isLoggedOut) {
                                      userRepository.deleteUser();
                                      Get.offAllNamed(Routes.auth);
                                    }
                                  }, () {
                                    Get.back();
                                  });
                                }
                              }, Icons.cancel_presentation_outlined,
                                  AppColors.red, AppColors.white)
                            ],
                          )
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Avatar: local file > cached network image (with placeholder/error
  // fallback) > initial/icon fallback. Shared by every avatar spot so the
  // profile photo loads instantly after the first fetch instead of being
  // re-downloaded at full resolution on every rebuild.
  // ---------------------------------------------------------------------
  Widget _buildAvatar({
    required double radius,
    required Color backgroundColor,
    required Widget fallback,
  }) {
    return Obx(() {
      if (controller.avatar.value != null) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          backgroundImage: FileImage(controller.avatar.value!),
        );
      }
      final avatarUrl = controller.userData.avatar;
      if (avatarUrl == null || avatarUrl.isEmpty) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          child: fallback,
        );
      }
      final size = radius * 2;
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: (size * 2).round(),
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: backgroundColor,
            alignment: Alignment.center,
            child: SizedBox(
              width: radius * 0.7,
              height: radius * 0.7,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryThemeColor,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            color: backgroundColor,
            alignment: Alignment.center,
            child: fallback,
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------
  // Header: brand, on-duty toggle, profile avatar, greeting, wallet chip
  // ---------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    final isTablet = !context.isPhone;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 5, 16, isTablet ? 64.h : 46.h),
      color: AppColors.backgroundColorMain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  showMenu.value = true;
                  controller.getUserData();
                  controller.fetchWalletAmount();
                },
                child: Container(
                  width: isTablet ? 44.w : 36.w,
                  height: isTablet ? 44.w : 36.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(isTablet ? 10.r : 8.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.menu,
                      color: Colors.white, size: (isTablet ? 22 : 20).sp),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      utils.simpleDialog("Attention!",
                          "Do you want to Sign-Off this session ?", () async {
                        bool isSignIn = await controller.markAttendance(false);
                        if (isSignIn) {
                          controller.isAttendanceMarked.value = false;
                        }
                      }, () {
                        Navigator.of(Get.context!).pop();
                      });
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.greenLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          utils.tvCustom("On duty", Colors.white, 11,
                              textAlignment: TextAlign.left),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildAvatar(
                    radius: isTablet ? 22 : 18,
                    backgroundColor: Colors.white,
                    fallback: utils.tvCustom(
                        controller.riderName.value.isNotEmpty
                            ? controller.riderName.value[0].toUpperCase()
                            : "R",
                        AppColors.primaryThemeColor,
                        14),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isTablet ? 22.h : 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    utils.tvCustom("Good to see you", Colors.white70, 12,
                        textAlignment: TextAlign.left),
                    const SizedBox(height: 2),
                    Obx(() => utils.tvCustom(
                        controller.riderName.value.toUpperCase(),
                        Colors.white,
                        19,
                        textAlignment: TextAlign.left,
                        maxLines: 1)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16.w : 12.w,
                    vertical: isTablet ? 11.h : 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        color: Colors.white, size: (isTablet ? 18 : 15).sp),
                    const SizedBox(width: 6),
                    Obx(() => utils.tvCustom(
                        "QAR ${controller.walletAmount.value}",
                        Colors.white,
                        14,
                        textAlignment: TextAlign.left)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Stats card: Today's Orders grid + compact All Orders summary
  // ---------------------------------------------------------------------
  Widget _buildStatsCard(BuildContext context) {
    final isTablet = !context.isPhone;
    return Obx(() {
      final b2c = controller.dashBoardData.value;
      final c2c = controller.c2cDashBoardData.value;
      final wa = controller.whatsAppDashBoardData.value;

      int todayAssigned = (b2c.todayOrdersCount?.aSSIGNED ?? 0) +
          (c2c.todayOrdersCount?.aSSIGNED ?? 0) +
          (wa.todayOrdersCount?.aSSIGNED ?? 0);
      int todayPicked = (b2c.todayOrdersCount?.pICKED ?? 0) +
          (c2c.todayOrdersCount?.pICKED ?? 0) +
          (wa.todayOrdersCount?.pICKED ?? 0);
      int todayOfd = (b2c.todayOrdersCount?.oFD ?? 0) +
          (c2c.todayOrdersCount?.oFD ?? 0) +
          (wa.todayOrdersCount?.oFD ?? 0);
      int todayDelivered = (b2c.todayOrdersCount?.dELIVERED ?? 0) +
          (c2c.todayOrdersCount?.dELIVERED ?? 0) +
          (wa.todayOrdersCount?.dELIVERED ?? 0);

      int allAssigned = (b2c.allOrdersCount?.aSSIGNED ?? 0) +
          (c2c.allOrdersCount?.aSSIGNED ?? 0) +
          (wa.allOrdersCount?.aSSIGNED ?? 0);
      int allPicked = (b2c.allOrdersCount?.pICKED ?? 0) +
          (c2c.allOrdersCount?.pICKED ?? 0) +
          (wa.allOrdersCount?.pICKED ?? 0);
      int allOfd = (b2c.allOrdersCount?.oFD ?? 0) +
          (c2c.allOrdersCount?.oFD ?? 0) +
          (wa.allOrdersCount?.oFD ?? 0);
      int allDelivered = (b2c.allOrdersCount?.dELIVERED ?? 0) +
          (c2c.allOrdersCount?.dELIVERED ?? 0) +
          (wa.allOrdersCount?.dELIVERED ?? 0);

      final cardBg = Get.isDarkMode ? AppColors.greyColor10 : Colors.white;

      return Container(
        padding: EdgeInsets.all(isTablet ? 22.w : 16.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(isTablet ? 20.r : 16.r),
          border: Get.isDarkMode
              ? Border.all(color: Colors.white.withOpacity(0.08))
              : null,
          boxShadow: Get.isDarkMode
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6)),
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8)),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                utils.tvCustom("Today's Orders", AppColors.black, 15,
                    textAlignment: TextAlign.left),
                utils.tvCustom(
                    "${todayAssigned + todayPicked + todayOfd + todayDelivered} total",
                    AppColors.greyColor4,
                    11,
                    textAlignment: TextAlign.left),
              ],
            ),
            SizedBox(height: isTablet ? 16.h : 14.h),
            Row(
              children: [
                Expanded(
                    child: _statTile(context, Icons.assignment_outlined,
                        AppColors.primaryThemeColor, todayAssigned, "Assigned")),
                SizedBox(width: isTablet ? 14.w : 8.w),
                Expanded(
                    child: _statTile(context, Icons.shopping_bag_outlined,
                        AppColors.blue, todayPicked, "Picked")),
                SizedBox(width: isTablet ? 14.w : 8.w),
                Expanded(
                    child: _statTile(context, Icons.local_shipping_outlined,
                        _amberOFD, todayOfd, "OFD")),
                SizedBox(width: isTablet ? 14.w : 8.w),
                Expanded(
                    child: _statTile(context, Icons.check_circle_outline,
                        AppColors.greenLight, todayDelivered, "Delivered")),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _statTile(
      BuildContext context, IconData icon, Color color, int value, String label) {
    final isTablet = !context.isPhone;
    return Container(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 18.h : 10.h),
      decoration: BoxDecoration(
        color: color.withOpacity(Get.isDarkMode ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(isTablet ? 16.r : 12.r),
      ),
      child: Column(
        children: [
          Icon(icon, size: (isTablet ? 24 : 18).sp, color: color),
          SizedBox(height: isTablet ? 10.h : 2.h),
          utils.tvCustom(value.toString(), AppColors.black, 12),
          const SizedBox(height: 2),
          utils.tvCustom(label, AppColors.greyColor5, 9.5),
        ],
      ),
    );
  }

  Widget _allOrdersChip(Color color, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(value.toString(),
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.greyColor5)),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Quick actions: active-order banner, Nearby B2C, WhatsApp Orders
  // ---------------------------------------------------------------------
  Widget _buildQuickActions(BuildContext context) {
    final isTablet = !context.isPhone;
    final actionRows = [
      _actionRow(
        context,
        icon: Icons.location_on_outlined,
        iconColor: AppColors.primaryThemeColor,
        iconBg: AppColors.primaryThemeColor.withOpacity(Get.isDarkMode ? 0.18 : 0.10),
        title: "Find Nearby Pickups",
        subtitle: "B2C pickup orders near you",
        onTap: () {
          Get.toNamed(Routes.nearByOrders)?.then((value) {
            controller.getC2CCDashBoardData();
            controller.getDashBoardData();
            controller.getWhatsAppDashBoardData();
          });
        },
      ),
      Obx(() => _actionRow(
            context,
            icon: Icons.chat_bubble_outline,
            iconColor: _whatsAppGreen,
            iconBg: _whatsAppGreen.withOpacity(Get.isDarkMode ? 0.22 : 0.12),
            title: "WhatsApp Orders",
            subtitle: "Orders booked via WhatsApp",
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _whatsAppGreen.withOpacity(Get.isDarkMode ? 0.24 : 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: utils.tvCustom(
                  "${controller.whatsAppDashBoardData.value.allOrdersCount?.aSSIGNED ?? 0} Assigned",
                  _whatsAppGreen,
                  11.5),
            ),
            onTap: () {},
          )),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: utils.tvCustom("Quick Actions", AppColors.black, 14,
              textAlignment: TextAlign.left),
        ),
        SizedBox(height: isTablet ? 14.h : 10.h),
        Obx(() => Visibility(
              visible: controller.isAnyActiveOrder.value,
              child: Padding(
                padding: EdgeInsets.only(bottom: isTablet ? 14.h : 10.h),
                child: _activeOrderBanner(context),
              ),
            )),
        if (isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: actionRows[0]),
              SizedBox(width: 14.w),
              Expanded(child: actionRows[1]),
            ],
          )
        else
          Column(
            children: [
              actionRows[0],
              SizedBox(height: 10.h),
              actionRows[1],
            ],
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Upcoming Orders: not-yet-delivered orders, soonest due first
  // ---------------------------------------------------------------------
  Widget _buildUpcomingOrders(BuildContext context) {
    final isTablet = !context.isPhone;
    return Obx(() {
      final orders = controller.upcomingOrders;
      if (orders.isEmpty) return const SizedBox.shrink();
      final cardBg = Get.isDarkMode ? AppColors.greyColor10 : Colors.white;
      final dividerColor =
          Get.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFF0F0F0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              utils.tvCustom("Upcoming Orders", AppColors.black, 14,
                  textAlignment: TextAlign.left),
              InkWell(
                onTap: () => Get.toNamed(Routes.orderListScreen),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    utils.tvCustom("View All", AppColors.primaryThemeColor, 12,
                        textAlignment: TextAlign.left),
                    Icon(Icons.chevron_right,
                        color: AppColors.primaryThemeColor,
                        size: (isTablet ? 18 : 16).sp),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 14.h : 10.h),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(isTablet ? 20.r : 14.r),
              border: Get.isDarkMode
                  ? Border.all(color: Colors.white.withOpacity(0.08))
                  : null,
              boxShadow: Get.isDarkMode
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < orders.length; i++) ...[
                  _upcomingOrderRow(context, orders[i]),
                  if (i != orders.length - 1)
                    Container(
                        height: 1,
                        margin: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20.w : 14.w),
                        color: dividerColor),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  Color _upcomingStatusColor(String status) {
    switch (status) {
      case ASSIGNED:
      case RE_ASSIGNED:
        return AppColors.linkColor;
      case PICKED:
        return AppColors.blue;
      case OFD:
        return _amberOFD;
      default:
        return AppColors.primaryThemeColor;
    }
  }

  IconData _upcomingStatusIcon(String status) {
    switch (status) {
      case PICKED:
        return Icons.shopping_bag_outlined;
      case OFD:
        return Icons.local_shipping_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  String _dueInLabel(int remainingSeconds) {
    if (remainingSeconds <= 0) return "Overdue";
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    return hours > 0 ? "Due in ${hours}h ${minutes}m" : "Due in ${minutes}m";
  }

  Widget _upcomingOrderRow(BuildContext context, OrdersData order) {
    final isTablet = !context.isPhone;
    final status = order.status ?? "";
    final statusColor = _upcomingStatusColor(status);
    final remaining = controller.remainingSecondsFor(order);
    final overdue = remaining <= 0;

    return InkWell(
      onTap: () => Get.toNamed(Routes.allOrdersMapScreen),
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: isTablet ? 16.h : 13.h, horizontal: isTablet ? 20.w : 14.w),
        child: Row(
          children: [
            Container(
              width: isTablet ? 48.w : 38.w,
              height: isTablet ? 48.w : 38.w,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(Get.isDarkMode ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(isTablet ? 12.r : 10.r),
              ),
              alignment: Alignment.center,
              child: Icon(_upcomingStatusIcon(status),
                  color: statusColor, size: (isTablet ? 22 : 19).sp),
            ),
            SizedBox(width: isTablet ? 14.w : 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  utils.tvCustom(
                      order.awbNo ?? order.orderRefNumber ?? "-",
                      AppColors.black,
                      12,
                      textAlignment: TextAlign.left,
                      maxLines: 1),
                  const SizedBox(height: 2),
                  utils.tvCustom(
                      (order.consigneeName?.isNotEmpty ?? false)
                          ? order.consigneeName!
                          : (order.merchantName ?? ""),
                      AppColors.greyColor4,
                      11,
                      textAlignment: TextAlign.left,
                      maxLines: 1),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(Get.isDarkMode ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: utils.tvCustom(status, statusColor, 9,
                        textAlignment: TextAlign.left),
                  ),
                ],
              ),
            ),
            SizedBox(width: isTablet ? 10.w : 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                utils.tvCustom(_dueInLabel(remaining),
                    overdue ? AppColors.red : AppColors.black, 12),
                const SizedBox(height: 4),
                _paymentBadge(order),
              ],
            ),
            Icon(Icons.chevron_right,
                color: Get.isDarkMode ? AppColors.greyColor4 : const Color(0xFFC7C7C7),
                size: 18),
          ],
        ),
      ),
    );
  }

  // COD orders show the amount the rider must collect; everything else
  // (prepaid/paid) just shows the payment type as already settled -
  // reuses the same COD-vs-other color split as c2cOrders_item.dart.
  Widget _paymentBadge(OrdersData order) {
    final isCod = (order.paymentType ?? "").toLowerCase() == "cod";
    final color = isCod ? _amberOFD : AppColors.greenLight;
    final label = isCod
        ? "COD · QAR ${order.orderAmount ?? '0'}"
        : "${(order.paymentType ?? "").isNotEmpty ? "${order.paymentType} · " : ""}Paid";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(Get.isDarkMode ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: utils.tvCustom(label, color, 10, textAlignment: TextAlign.left),
    );
  }

  Widget _activeOrderBanner(BuildContext context) {
    final isTablet = !context.isPhone;
    return InkWell(
      borderRadius: BorderRadius.circular(isTablet ? 20.r : 14.r),
      onTap: () {
        Get.toNamed(Routes.allOrdersMapScreen);
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20.w : 14.w),
        decoration: BoxDecoration(
          color: AppColors.greenLight,
          borderRadius: BorderRadius.circular(isTablet ? 20.r : 14.r),
          boxShadow: [
            BoxShadow(
                color: AppColors.greenLight.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 56.w : 44.w,
              height: isTablet ? 56.w : 44.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(isTablet ? 16.r : 12.r),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.two_wheeler,
                  color: Colors.white, size: (isTablet ? 28 : 24).sp),
            ),
            SizedBox(width: isTablet ? 16.w : 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: utils.tvCustom(
                            "Continue B2C Delivery", Colors.white, 14,
                            textAlignment: TextAlign.left, maxLines: 1),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: utils.tvCustom("LIVE", Colors.white, 9,
                            textAlignment: TextAlign.left),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  utils.tvCustom(
                      "1 active order in progress", Colors.white70, 11.5,
                      textAlignment: TextAlign.left),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _actionRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final isTablet = !context.isPhone;
    final cardBg = Get.isDarkMode ? AppColors.greyColor10 : Colors.white;
    final chevronColor = Get.isDarkMode ? AppColors.greyColor4 : const Color(0xFFC7C7C7);
    return InkWell(
      borderRadius: BorderRadius.circular(isTablet ? 20.r : 14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20.w : 14.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(isTablet ? 20.r : 14.r),
          border: Get.isDarkMode
              ? Border.all(color: Colors.white.withOpacity(0.08))
              : null,
          boxShadow: Get.isDarkMode
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 56.w : 44.w,
              height: isTablet ? 56.w : 44.w,
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(isTablet ? 16.r : 12.r)),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: (isTablet ? 28 : 22).sp),
            ),
            SizedBox(width: isTablet ? 16.w : 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  utils.tvCustom(title, AppColors.black, 14,
                      textAlignment: TextAlign.left),
                  const SizedBox(height: 2),
                  utils.tvCustom(subtitle, AppColors.greyColor4, 11.5,
                      textAlignment: TextAlign.left),
                ],
              ),
            ),
            if (trailing != null) ...[trailing, const SizedBox(width: 6)],
            Icon(Icons.chevron_right, color: chevronColor, size: 18),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Bottom navigation: Home, Order, Active Order, Account
  // ---------------------------------------------------------------------
  Widget _buildBottomNav(BuildContext context) {
    final isTablet = !context.isPhone;
    return Obx(() {
      final selected = selectedNavIndex.value;
      final navBg = Get.isDarkMode ? AppColors.greyColor10 : Colors.white;
      return Container(
        padding: EdgeInsets.fromLTRB(6, isTablet ? 16.h : 10.h, 6, isTablet ? 16.h : 14.h),
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(isTablet ? 26.r : 20.r)),
          border: Get.isDarkMode
              ? Border(top: BorderSide(color: Colors.white.withOpacity(0.08)))
              : null,
          boxShadow: Get.isDarkMode
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, -4)),
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 24,
                      offset: const Offset(0, -8)),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _navItem(
                context,
                icon: Icons.home_outlined,
                label: "Home",
                selected: selected == 0,
                onTap: () => selectedNavIndex.value = 0,
              ),
            ),
            Expanded(
              child: _navItem(
                context,
                icon: Icons.inventory_2_outlined,
                label: "Order",
                selected: selected == 1,
                onTap: () {
                  selectedNavIndex.value = 1;
                  Get.toNamed(Routes.orderListScreen)?.then((_) {
                    selectedNavIndex.value = 0;
                  });
                },
              ),
            ),
            Expanded(
              child: _navItem(
                context,
                icon: Icons.two_wheeler,
                label: "Active Order",
                selected: selected == 2,
                showBadge: controller.isAnyActiveOrder.value,
                onTap: () {
                  selectedNavIndex.value = 2;
                  Get.toNamed(Routes.allOrdersMapScreen)?.then((_) {
                    selectedNavIndex.value = 0;
                  });
                },
              ),
            ),
            Expanded(
              child: _navItem(
                context,
                icon: Icons.person_outline,
                label: "Account",
                selected: selected == 3,
                onTap: () {
                  selectedNavIndex.value = 3;
                  showMenu.value = true;
                  controller.getUserData();
                  controller.fetchWalletAmount();
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    final isTablet = !context.isPhone;
    final inactiveColor = Get.isDarkMode ? AppColors.greyColor3 : AppColors.greyColor4;
    final color = selected ? AppColors.primaryThemeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isTablet ? 56.w : 44.w,
              height: isTablet ? 34.h : 28.h,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryThemeColor.withOpacity(Get.isDarkMode ? 0.16 : 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: (isTablet ? 26 : 21).sp, color: color),
                  if (showBadge)
                    Positioned(
                      top: -2,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Get.isDarkMode ? AppColors.greyColor10 : Colors.white,
                              width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyle.tsCustom(
                      color, utils.responsiveFontSize(isTablet ? 12.5 : 10.5))
                  .copyWith(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Profile flyout menu (triggered by the header menu button)
  // ---------------------------------------------------------------------
  Widget _buildProfileMenuOverlay(BuildContext context) {
    return Obx(() {
      if (!showMenu.value) {
        return const SizedBox.shrink();
      }
      return Stack(
        children: [
          // Scrim - tap outside to close
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                showMenu.value = false;
                selectedNavIndex.value = 0;
              },
              child: Container(color: Colors.black.withOpacity(0.32)),
            ),
          ),
          Positioned(
            top: 46,
            left: 20,
            child: Container(
              width: context.isPhone ? 264.sp : 360.0.sp,
              constraints:
                  BoxConstraints(maxHeight: context.isPhone ? 520.sp : 650.sp),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 40,
                      offset: const Offset(0, 16)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                  onTap: () {
                                    showMenu.value = false;
                                    selectedNavIndex.value = 0;
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Color(0xFFB0B0B0),
                                  ))
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              controller.updateProfileDialog.value = true;
                            },
                            child: Row(
                              children: [
                                _buildAvatar(
                                  radius: 26,
                                  backgroundColor: AppColors.primaryThemeColor
                                      .withOpacity(0.14),
                                  fallback: Text(
                                    controller.riderName.value.isNotEmpty
                                        ? controller.riderName.value[0]
                                            .toUpperCase()
                                        : "R",
                                    style: const TextStyle(
                                        color: AppColors.primaryThemeColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(controller.userData.name ?? "",
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: AppColors.black)),
                                      const SizedBox(height: 2),
                                      Text(controller.userData.email ?? "",
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: AppColors.greyColor4,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.edit_outlined,
                                    size: 16, color: AppColors.primaryThemeColor),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(() => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 9),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryThemeColor
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 16,
                                        color: AppColors.primaryThemeColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                          "QAR ${controller.walletAmount.value}",
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  AppColors.primaryThemeColor)),
                                    ),
                                    const Text("WALLET",
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                AppColors.primaryThemeColor)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),

                    // Menu rows
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Column(
                        children: [
                          _menuRow(
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppColors.primaryThemeColor,
                            iconBg: AppColors.primaryThemeColor.withOpacity(0.10),
                            label: "My Orders",
                            onTap: () {
                              showMenu.value = false;
                              selectedNavIndex.value = 0;
                              Get.toNamed(Routes.orderListScreen);
                            },
                          ),
                          _menuRow(
                            icon: Icons.near_me_outlined,
                            iconColor: AppColors.blue,
                            iconBg: AppColors.blue.withOpacity(0.08),
                            label: "Nearby Orders",
                            onTap: () {
                              showMenu.value = false;
                              selectedNavIndex.value = 0;
                              Get.toNamed(Routes.nearByOrders);
                            },
                          ),
                          _menuRow(
                            icon: Icons.support_agent_outlined,
                            iconColor: AppColors.greenLight,
                            iconBg: AppColors.greenLight.withOpacity(0.08),
                            label: "Support",
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),

                    // Logout
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: _menuRow(
                        icon: Icons.logout,
                        iconColor: AppColors.red,
                        iconBg: AppColors.red.withOpacity(0.08),
                        label: "Logout",
                        labelColor: AppColors.red,
                        showChevron: false,
                        onTap: () async {
                          bool isLoggedOut = await controller.logout();
                          if (isLoggedOut) {
                            utils.simpleDialog(
                                "Do you want to Logout from app?", "",
                                () async {
                              var isLoggedOut = await controller.logout();
                              if (isLoggedOut) {
                                userRepository.deleteUser();
                                Get.offAllNamed(Routes.auth);
                              }
                            }, () {
                              Get.back();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _menuRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
    Color labelColor = AppColors.black,
    bool showChevron = true,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: labelColor)),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, color: Color(0xFFC7C7C7), size: 15),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Update profile dialog (unchanged)
  // ---------------------------------------------------------------------
  Widget _buildUpdateProfileDialog() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          decoration: utils.boxDecorationWhite(),
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Form(
                key: controller.profileFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Update Profile",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                controller.updateProfileDialog.value = false),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Avatar Section
                    Center(
                      child: Stack(
                        children: [
                          _buildAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200]!,
                            fallback:
                                Icon(Icons.person, size: 50, color: Colors.grey[400]),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: controller.showImageSourceDialog,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryThemeColor,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Address Field
                    Text(
                      "Address",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.address,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        focusColor: AppColors.primaryThemeColor,
                        hintText: "Enter your complete address",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            const Icon(Icons.location_on, color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primaryThemeColor,
                            width: 2,
                          ),
                        ),
                      ),
                      cursorColor: AppColors.primaryThemeColor,
                      validator: controller.validateAddress,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Phone Number",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "Enter your phone number",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primaryThemeColor,
                            width: 2,
                          ),
                        ),
                      ),
                      cursorColor: AppColors.primaryThemeColor,
                      validator: controller.validatePhone,
                    ),
                    const SizedBox(height: 10),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                controller.updateProfileDialog.value = false,
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              bool success =
                                  await controller.updateProfileDetails();
                              if (success) {
                                controller.updateProfileDialog.value = false;
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppColors.primaryThemeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Update",
                              style: TextStyle(color: Colors.white),
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
      ),
    );
  }
}
