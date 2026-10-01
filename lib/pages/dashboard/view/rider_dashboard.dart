import 'package:cached_network_image/cached_network_image.dart';
import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:carson_zyppy/pages/my_orders/orders/models/orders_model.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:carson_zyppy/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../../app_pages/app_pages.dart';
import '../../../global/app_bar.dart';
import '../../../global/consts.dart';
import '../../../global/order_card_widget.dart';
import '../../../global/update_profile_dialog.dart';

const Color _amberOFD = Color(0xFFA67C00);
const Color _whatsAppGreen = Color(0xFF0BA30B);

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard>
    with WidgetsBindingObserver {
  final RiderDashboardController controller = Get.put(
    RiderDashboardController(),
  );

  var selectedNavIndex = 0.obs;

  // "New Requests" mobile carousel - one full-width order card per page,
  // with a dot indicator below tracking the swiped-to page.
  final PageController _newRequestsPageController = PageController();
  final _newRequestsPage = 0.obs;
  // Measured natural height of each carousel page, keyed by index, so the
  // page viewport can size to the actual card instead of a fixed height.
  final Map<int, double> _newRequestsCardHeights = {};
  final _newRequestsCarouselHeight = RxnDouble();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _newRequestsPageController.dispose();
    super.dispose();
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
      bottomNavigationBar: Obx(
        () => controller.isAttendanceMarked.value
            ? _buildBottomNav(context)
            : const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() {
              return Visibility(
                visible: !controller.isAttendanceMarked.value,
                child: Container(
                  height: Get.height,
                  width: Get.width,
                  color: AppColors.backgroundColorMain,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GeometricBackgroundPainter(),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 110,
                          width: 200,
                          child: Image.asset(appLogo, fit: BoxFit.contain),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Obx(() {
              return Visibility(
                visible: controller.isAttendanceMarked.value,
                child: Container(
                  color: controller.isDarkMode.value
                      ? AppColors.black
                      : AppColors.greyColor1,
                  child: Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () async {
                         // controller.driverCheckAttendance();
                          await controller.getDashBoardData();
                          // await controller.getC2CCDashBoardData();
                          //await controller.getWhatsAppDashBoardData();
                          await controller.getNextDelivery();
                          await controller.fetchAvailableOrders();
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    children: [
                                      _buildStatsCard(context),
                                     // const SizedBox(height: 18),
                                      //_buildQuickActions(context),
                                      const SizedBox(height: 18),
                                      _buildNewRequests(context),
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
                    ],
                  ),
                ),
              );
            }),
            Obx(() {
              final isTablet = !context.isPhone;
              return !controller.isAttendanceLoaded.value
                  ? Align(
                      alignment: const Alignment(0, 0.12),
                      child: utils.iosProgressIndicator(
                        AppColors.white,
                        "Fetching Data...",
                      ),
                    )
                  : Visibility(
                      visible: !controller.isAttendanceMarked.value,
                      child: SizedBox(
                        height: Get.height,
                        width: Get.width,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 60.w : 24.w,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isTablet ? 420.w : 480,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(50),
                                      onTap: () {
                                        utils.simpleDialog(
                                          "Do you want to Logout from app?",
                                          "",
                                          () async {
                                            var isLoggedOut = await controller
                                                .logout();
                                            if (isLoggedOut) {
                                              userRepository.deleteUser();
                                              Get.offAllNamed(Routes.auth);
                                            }
                                          },
                                          () {
                                            Get.back();
                                          },
                                        );
                                      },
                                      child: Container(
                                        width: isTablet ? 44.w : 36.w,
                                        height: isTablet ? 44.w : 36.w,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.logout,
                                          color: Colors.white.withOpacity(0.85),
                                          size: (isTablet ? 20 : 17).sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 28.h : 18.h),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.fromLTRB(
                                      isTablet ? 30.w : 22.w,
                                      isTablet ? 38.h : 30.h,
                                      isTablet ? 30.w : 22.w,
                                      isTablet ? 30.h : 24.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundColorLight,
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Obx(
                                          () => utils.tvCustom(
                                            "Welcome, ${controller.riderName.toString().toUpperCase()}",
                                            Colors.white,
                                            20,
                                          ),
                                        ),
                                        SizedBox(height: isTablet ? 8.h : 6.h),
                                        utils.tvCustom(
                                          "Mark your attendance to start working",
                                          Colors.white.withOpacity(0.6),
                                          14,
                                        ),
                                        SizedBox(
                                          height: isTablet ? 20.h : 14.h,
                                        ),
                                        Container(
                                          height: isTablet ? 150.h : 120.h,
                                          width: isTablet ? 150.h : 120.h,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                AppColors.primaryThemeColor
                                                    .withOpacity(0.22),
                                                AppColors.primaryThemeColor
                                                    .withOpacity(0),
                                              ],
                                              stops: const [0.0, 0.8],
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Lottie.asset(
                                            ANIM_RIDER,
                                            height: isTablet ? 200.h : 150.h,
                                          ),
                                        ),
                                        SizedBox(
                                          height: isTablet ? 24.h : 18.h,
                                        ),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(
                                            14.r,
                                          ),
                                          onTap: () async {
                                            bool isSignIn = await controller.markAttendance(true);
                                            if (isSignIn) {
                                              controller.isAttendanceMarked.value = true;
                                            }
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            height: isTablet ? 56.h : 48.h,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.primaryThemeColor,
                                              borderRadius:
                                                  BorderRadius.circular(14.r),
                                            ),
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                utils.tvCustom(
                                                  "Sign In",
                                                  Colors.white,
                                                  17,
                                                ),
                                                SizedBox(width: 8.w),
                                                Icon(
                                                  Icons.arrow_forward,
                                                  color: Colors.white,
                                                  size: (isTablet ? 20 : 18).sp,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
              final isTablet = !context.isPhone;
              if (controller.isConsentGiven.value) {
                return const SizedBox.shrink();
              }
              return Container(
                height: Get.height,
                width: Get.width,
                color: AppColors.backgroundColorMain,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: GeometricBackgroundPainter()),
                    ),
                    Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 60.w : 24.w,
                          vertical: 24.h,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 460.w : 480,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: isTablet ? 76.h : 64.h,
                                width: isTablet ? 76.h : 64.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.primaryThemeColor.withOpacity(
                                        0.22,
                                      ),
                                      AppColors.primaryThemeColor.withOpacity(
                                        0,
                                      ),
                                    ],
                                    stops: const [0.0, 0.8],
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.location_on,
                                  color: AppColors.primaryThemeColor,
                                  size: (isTablet ? 34 : 28).sp,
                                ),
                              ),
                              SizedBox(height: isTablet ? 20.h : 14.h),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.fromLTRB(
                                  isTablet ? 30.w : 22.w,
                                  isTablet ? 30.h : 24.h,
                                  isTablet ? 30.w : 22.w,
                                  isTablet ? 30.h : 24.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundColorLight,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    utils.tvCustom(
                                      "Location Permission Required",
                                      Colors.white,
                                      19,
                                    ),
                                    SizedBox(height: isTablet ? 22.h : 18.h),
                                    _PermissionRow(
                                      icon: Icons.schedule,
                                      title: "Background access",
                                      description:
                                          "Keeps order assignment and rider notifications working even when the app is closed.",
                                      isTablet: isTablet,
                                    ),
                                    SizedBox(height: isTablet ? 18.h : 14.h),
                                    _PermissionRow(
                                      icon: Icons.navigation_outlined,
                                      title: "Foreground access",
                                      description:
                                          "Powers turn-by-turn navigation to customer addresses while you're delivering. Your location is never shared with third parties.",
                                      isTablet: isTablet,
                                    ),
                                    SizedBox(height: isTablet ? 22.h : 18.h),
                                    Container(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                    SizedBox(height: isTablet ? 18.h : 14.h),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Transform.scale(
                                          scale: isTablet ? 1.1 : 1,
                                          child: Checkbox(
                                            value:
                                                controller.checkBoxValue.value,
                                            activeColor: AppColors.greenLight,
                                            side: BorderSide(
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            onChanged: (bool? value) {
                                              controller.checkBoxValue.toggle();
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              top: isTablet ? 14.h : 12.h,
                                            ),
                                            child: utils.tvCustom(
                                              "I agree to share my location data as described above.",
                                              Colors.white.withOpacity(0.8),
                                              13,
                                              textAlignment: TextAlign.left,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isTablet ? 20.h : 16.h),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(14.r),
                                      onTap: () async {
                                        if (controller.checkBoxValue.value) {
                                          await box.write(
                                            "isConsentGiven",
                                            true,
                                          );
                                          controller.isConsentGiven.value =
                                              true;
                                          controller.updateLocation();
                                          controller
                                              .requestBackgroundPermission();
                                        } else {
                                          utils.errorSnackBar(
                                            "Error !",
                                            "Pls accept terms & conditions before proceed",
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: isTablet ? 56.h : 48.h,
                                        decoration: BoxDecoration(
                                          color: AppColors.greenLight,
                                          borderRadius: BorderRadius.circular(
                                            14.r,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            utils.tvCustom(
                                              "Agree & continue",
                                              Colors.white,
                                              16,
                                            ),
                                            SizedBox(width: 8.w),
                                            Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: (isTablet ? 20 : 18).sp,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 10.h : 6.h),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(10.r),
                                      onTap: () async {
                                        bool isLoggedOut = await controller
                                            .logout();
                                        if (isLoggedOut) {
                                          utils.simpleDialog(
                                            "Action",
                                            "If you disagree with our location policy, you will be logged out of the app.",
                                            () async {
                                              var isLoggedOut = await controller
                                                  .logout();
                                              if (isLoggedOut) {
                                                userRepository.deleteUser();
                                                Get.offAllNamed(Routes.auth);
                                              }
                                            },
                                            () {
                                              Get.back();
                                            },
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isTablet ? 10.h : 8.h,
                                        ),
                                        child: utils.tvCustom(
                                          "Disagree & log out",
                                          AppColors.red,
                                          14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
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
                  controller.showMenu.value = true;
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
                  child: Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: (isTablet ? 22 : 20).sp,
                  ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      utils.simpleDialog(
                        "Attention!",
                        "Do you want to Sign-Off this session ?",
                        () async {
                          bool isSignIn = await controller.markAttendance(false);
                          if (isSignIn) {
                            controller.isAttendanceMarked.value = false;
                          }
                        },
                        () {
                          Navigator.of(Get.context!).pop();
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
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
                          utils.tvCustom(
                            "On duty",
                            Colors.white,
                            11,
                            textAlignment: TextAlign.left,
                          ),
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
                      14,
                    ),
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
                    utils.tvCustom(
                      "Good to see you",
                      Colors.white70,
                      12,
                      textAlignment: TextAlign.left,
                    ),
                    const SizedBox(height: 2),
                    Obx(
                      () => utils.tvCustom(
                        controller.riderName.value.toUpperCase(),
                        Colors.white,
                        19,
                        textAlignment: TextAlign.left,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16.w : 12.w,
                  vertical: isTablet ? 11.h : 8.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: (isTablet ? 18 : 15).sp,
                    ),
                    const SizedBox(width: 6),
                    Obx(
                      () => utils.tvCustom(
                        "QAR ${controller.walletAmount.value}",
                        Colors.white,
                        14,
                        textAlignment: TextAlign.left,
                      ),
                    ),
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

      int todayAssigned =
          (b2c.todayOrdersCount?.aSSIGNED ?? 0) +
          (c2c.todayOrdersCount?.aSSIGNED ?? 0) +
          (wa.todayOrdersCount?.aSSIGNED ?? 0);
      int todayPicked =
          (b2c.todayOrdersCount?.pICKED ?? 0) +
          (c2c.todayOrdersCount?.pICKED ?? 0) +
          (wa.todayOrdersCount?.pICKED ?? 0);
      int todayOfd =
          (b2c.todayOrdersCount?.oFD ?? 0) +
          (c2c.todayOrdersCount?.oFD ?? 0) +
          (wa.todayOrdersCount?.oFD ?? 0);
      int todayDelivered =
          (b2c.todayOrdersCount?.dELIVERED ?? 0) +
          (c2c.todayOrdersCount?.dELIVERED ?? 0) +
          (wa.todayOrdersCount?.dELIVERED ?? 0);

      int allAssigned =
          (b2c.allOrdersCount?.aSSIGNED ?? 0) +
          (c2c.allOrdersCount?.aSSIGNED ?? 0) +
          (wa.allOrdersCount?.aSSIGNED ?? 0);
      int allPicked =
          (b2c.allOrdersCount?.pICKED ?? 0) +
          (c2c.allOrdersCount?.pICKED ?? 0) +
          (wa.allOrdersCount?.pICKED ?? 0);
      int allOfd =
          (b2c.allOrdersCount?.oFD ?? 0) +
          (c2c.allOrdersCount?.oFD ?? 0) +
          (wa.allOrdersCount?.oFD ?? 0);
      int allDelivered =
          (b2c.allOrdersCount?.dELIVERED ?? 0) +
          (c2c.allOrdersCount?.dELIVERED ?? 0) +
          (wa.allOrdersCount?.dELIVERED ?? 0);

      final cardBg = controller.isDarkMode.value ? AppColors.greyColor10 : Colors.white;

      return Container(
        padding: EdgeInsets.all(isTablet ? 22.w : 16.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(isTablet ? 20.r : 16.r),
          border: controller.isDarkMode.value
              ? Border.all(color: Colors.white.withOpacity(0.08))
              : null,
          boxShadow: controller.isDarkMode.value
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                utils.tvCustom(
                  "Today's Orders",
                  AppColors.black,
                  15,
                  textAlignment: TextAlign.left,
                ),
                utils.tvCustom(
                  "${todayAssigned + todayPicked + todayOfd + todayDelivered} total",
                  AppColors.greyColor4,
                  11,
                  textAlignment: TextAlign.left,
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16.h : 14.h),
            Row(
              children: [
                Expanded(
                  child: _statTile(
                    context,
                    Icons.assignment_outlined,
                    AppColors.primaryThemeColor,
                    todayAssigned,
                    "Assigned",
                  ),
                ),
                SizedBox(width: isTablet ? 14.w : 8.w),
                Expanded(
                  child: _statTile(
                    context,
                    Icons.shopping_bag_outlined,
                    AppColors.blue,
                    todayPicked,
                    "Picked",
                  ),
                ),
                SizedBox(width: isTablet ? 14.w : 8.w),
                Expanded(
                  child: _statTile(
                    context,
                    Icons.local_shipping_outlined,
                    _amberOFD,
                    todayOfd,
                    "OFD",
                  ),
                ),
                SizedBox(width: isTablet ? 14.w : 8.w),
                Expanded(
                  child: _statTile(
                    context,
                    Icons.check_circle_outline,
                    AppColors.greenLight,
                    todayDelivered,
                    "Delivered",
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _statTile(
    BuildContext context,
    IconData icon,
    Color color,
    int value,
    String label,
  ) {
    final isTablet = !context.isPhone;
    return Container(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 18.h : 10.h),
      decoration: BoxDecoration(
        color: color.withOpacity(controller.isDarkMode.value ? 0.18 : 0.08),
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
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.greyColor5,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Quick actions: active-order banner, Nearby B2C, WhatsApp Orders
  // ---------------------------------------------------------------------
  // Widget _buildQuickActions(BuildContext context) {
  //   final isTablet = !context.isPhone;
  //   final actionRows = [
  //     _actionRow(
  //       context,
  //       icon: Icons.location_on_outlined,
  //       iconColor: AppColors.primaryThemeColor,
  //       iconBg: AppColors.primaryThemeColor.withOpacity(
  //         controller.isDarkMode.value ? 0.18 : 0.10,
  //       ),
  //       title: "Find Nearby Pickups",
  //       subtitle: "B2C pickup orders near you",
  //       onTap: () {
  //         Get.toNamed(Routes.nearByOrders)?.then((value) {
  //           // controller.getC2CCDashBoardData();
  //           controller.getDashBoardData();
  //           controller.getNextDelivery();
  //           // controller.getWhatsAppDashBoardData();
  //         });
  //       },
  //     ),
  //     Obx(
  //       () => _actionRow(
  //         context,
  //         icon: Icons.chat_bubble_outline,
  //         iconColor: _whatsAppGreen,
  //         iconBg: _whatsAppGreen.withOpacity(controller.isDarkMode.value ? 0.22 : 0.12),
  //         title: "WhatsApp Orders",
  //         subtitle: "Orders booked via WhatsApp",
  //         trailing: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //           decoration: BoxDecoration(
  //             color: _whatsAppGreen.withOpacity(controller.isDarkMode.value ? 0.24 : 0.14),
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           child: utils.tvCustom(
  //             "${controller.whatsAppDashBoardData.value.allOrdersCount?.aSSIGNED ?? 0} Assigned",
  //             _whatsAppGreen,
  //             11.5,
  //           ),
  //         ),
  //         onTap: () {},
  //       ),
  //     ),
  //   ];
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 2),
  //         child: utils.tvCustom(
  //           "Quick Actions",
  //           AppColors.black,
  //           14,
  //           textAlignment: TextAlign.left,
  //         ),
  //       ),
  //       SizedBox(height: isTablet ? 14.h : 10.h),
  //       Obx(
  //         () => Visibility(
  //           visible: controller.isAnyActiveOrder.value,
  //           child: Padding(
  //             padding: EdgeInsets.only(bottom: isTablet ? 14.h : 10.h),
  //             child: _activeOrderBanner(context),
  //           ),
  //         ),
  //       ),
  //       if (isTablet)
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Expanded(child: actionRows[0]),
  //             SizedBox(width: 14.w),
  //             Expanded(child: actionRows[1]),
  //           ],
  //         )
  //       else
  //         Column(
  //           children: [
  //             actionRows[0],
  //             SizedBox(height: 10.h),
  //             actionRows[1],
  //           ],
  //         ),
  //     ],
  //   );
  // }

  // ---------------------------------------------------------------------
  // New Requests: unclaimed orders nearby the rider can accept, shown
  // horizontally using the same card as order_list_screen's "available"
  // tab so the two never visually drift apart.
  // ---------------------------------------------------------------------
  Widget _buildNewRequests(BuildContext context) {
    final isTablet = !context.isPhone;
    return Obx(() {
      final orders = controller.availableOrders;
      final hasOrders = orders.isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  utils.tvCustom(
                    "New Requests",
                    AppColors.black,
                    14,
                    textAlignment: TextAlign.left,
                  ),
                  if (hasOrders) ...[
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryThemeColor.withOpacity(
                          controller.isDarkMode.value ? 0.22 : 0.14,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: utils.tvCustom(
                        orders.length.toString(),
                        AppColors.primaryThemeColor,
                        10.5,
                      ),
                    ),
                  ],
                ],
              ),
              if (hasOrders)
                InkWell(
                  onTap: () => Get.toNamed(
                    Routes.orderListScreen,
                    arguments: {'initialStatusTab': 'available'},
                  )?.then((_) => controller.fetchAvailableOrders()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      utils.tvCustom(
                        "View All",
                        AppColors.primaryThemeColor,
                        12,
                        textAlignment: TextAlign.left,
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.primaryThemeColor,
                        size: (isTablet ? 18 : 16).sp,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: isTablet ? 14.h : 10.h),
          if (!hasOrders)
            _newRequestsPlaceholder(context)
          else if (isTablet)
            _newRequestsTabletRow(context, orders)
          else
            _newRequestsMobileCarousel(context, orders),
        ],
      );
    });
  }

  // Tablet keeps the original side-by-side horizontal scroll of narrower
  // cards - there's enough width to show more than one at a time.
  Widget _newRequestsTabletRow(BuildContext context, List<OrdersData> orders) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int index = 0; index < orders.length; index++) ...[
              if (index != 0) SizedBox(width: 10.w),
              Builder(
                builder: (context) {
                  final order = orders[index];
                  return OrderCardWidget(
                    order: order,
                    available: true,
                    completed: false,
                    atRisk: controller.isAtRisk(order),
                    dueInLabel: _newRequestDueInLabel(
                      controller.remainingSecondsFor(order),
                    ),
                    accentColor: AppColors.primaryThemeColor,
                    isCod: controller.isCod(order),
                    width: 300.w,
                    onTap: () => Get.toNamed(
                      Routes.orderDetailScreen,
                      arguments: order,
                    )?.then((_) => controller.fetchAvailableOrders()),
                    onAccept: () => _confirmAcceptNewRequest(order),
                    onDecline: () => _confirmDeclineNewRequest(order),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Mobile: one full-width card per page, swipeable, with a dot indicator
  // below sized to the number of orders.
  Widget _newRequestsMobileCarousel(
    BuildContext context,
    List<OrdersData> orders,
  ) {
    if (_newRequestsPage.value >= orders.length) {
      _newRequestsPage.value = 0;
    }
    return Column(
      children: [
        // Hidden pass: lay out every card with no height constraint so its
        // real natural height can be measured (an intrinsic-height query
        // was tried first but underestimates this card's nested button
        // row, causing a bottom overflow once the visible PageView was
        // sized off it).
        Offstage(
          offstage: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < orders.length; i++)
                _MeasuredCarouselCard(
                  onMeasured: (measuredHeight) {
                    if (_newRequestsCardHeights[i] != measuredHeight) {
                      _newRequestsCardHeights[i] = measuredHeight;
                      if (i == _newRequestsPage.value) {
                        _newRequestsCarouselHeight.value = measuredHeight;
                      }
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: _newRequestCard(orders[i]),
                  ),
                ),
            ],
          ),
        ),
        Obx(() {
          final height =
              _newRequestsCardHeights[_newRequestsPage.value] ??
              _newRequestsCarouselHeight.value ??
              380.h;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: height,
            child: PageView.builder(
              controller: _newRequestsPageController,
              itemCount: orders.length,
              onPageChanged: (index) {
                _newRequestsPage.value = index;
                final cached = _newRequestsCardHeights[index];
                if (cached != null) {
                  _newRequestsCarouselHeight.value = cached;
                }
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: _newRequestCard(orders[index]),
                );
              },
            ),
          );
        }),
        if (orders.length > 1) ...[
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int index = 0; index < orders.length; index++) ...[
                if (index != 0) SizedBox(width: 6.w),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: index == _newRequestsPage.value ? 18.w : 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: index == _newRequestsPage.value
                        ? AppColors.primaryThemeColor
                        : (controller.isDarkMode.value
                              ? Colors.white24
                              : const Color(0xFFD9D9D9)),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _newRequestCard(OrdersData order) {
    return OrderCardWidget(
      order: order,
      available: true,
      completed: false,
      compact: true,
      atRisk: controller.isAtRisk(order),
      dueInLabel: _newRequestDueInLabel(
        controller.remainingSecondsFor(order),
      ),
      accentColor: AppColors.primaryThemeColor,
      isCod: controller.isCod(order),
      onTap: () => Get.toNamed(
        Routes.orderDetailScreen,
        arguments: order,
      )?.then((_) => controller.fetchAvailableOrders()),
      onAccept: () => _confirmAcceptNewRequest(order),
      onDecline: () => _confirmDeclineNewRequest(order),
    );
  }

  Widget _newRequestsPlaceholder(BuildContext context) {
    final isDark = controller.isDarkMode.value;
    final isTablet = !context.isPhone;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: isTablet ? 32.h : 24.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.greyColor10 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: AppColors.primaryThemeColor.withOpacity(
                isDark ? 0.18 : 0.10,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primaryThemeColor,
              size: 26.sp,
            ),
          ),
          SizedBox(height: 12.h),
          utils.tvCustom("No new requests right now", AppColors.black, 13.5),
          SizedBox(height: 4.h),
          utils.tvCustom(
            "New pickup requests near you will show up here as soon as they're available.",
            AppColors.greyColor4,
            11.5,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  String _newRequestDueInLabel(int remainingSeconds) {
    if (remainingSeconds <= 0) return "Overdue";
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    return hours > 0 ? "${hours}h ${minutes}m left" : "${minutes}m left";
  }

  void _confirmAcceptNewRequest(OrdersData order) {
    utils.simpleDialog(
      "Accept Order",
      "Do you want to accept this order?",
      () => controller.acceptRejectOrder(acceptOrder, order.awbNo ?? ""),
      () => Get.back(),
    );
  }

  void _confirmDeclineNewRequest(OrdersData order) {
    utils.simpleDialog(
      "Decline Order",
      "Do you want to decline this order?",
      () => controller.acceptRejectOrder(rejectOrder, order.awbNo ?? ""),
      () => Get.back(),
    );
  }

  // ---------------------------------------------------------------------
  // Upcoming Orders: not-yet-delivered orders, soonest due first
  // ---------------------------------------------------------------------
  Widget _buildUpcomingOrders(BuildContext context) {
    final isTablet = !context.isPhone;
    return Obx(() {
      final orders = controller.upcomingOrders;
      final hasOrders = orders.isNotEmpty;
      final cardBg = controller.isDarkMode.value ? AppColors.greyColor10 : Colors.white;
      final dividerColor = controller.isDarkMode.value
          ? Colors.white.withOpacity(0.08)
          : const Color(0xFFF0F0F0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              utils.tvCustom(
                "Upcoming Orders",
                AppColors.black,
                14,
                textAlignment: TextAlign.left,
              ),
              InkWell(
                onTap: () => Get.toNamed(Routes.orderListScreen),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    utils.tvCustom(
                      "View All",
                      AppColors.primaryThemeColor,
                      12,
                      textAlignment: TextAlign.left,
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.primaryThemeColor,
                      size: (isTablet ? 18 : 16).sp,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 14.h : 10.h),
          if (!hasOrders)
            _upcomingOrdersPlaceholder(context)
          else
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(isTablet ? 20.r : 14.r),
                border: controller.isDarkMode.value
                    ? Border.all(color: Colors.white.withOpacity(0.08))
                    : null,
                boxShadow: controller.isDarkMode.value
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
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
                          horizontal: isTablet ? 20.w : 14.w,
                        ),
                        color: dividerColor,
                      ),
                  ],
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _upcomingOrdersPlaceholder(BuildContext context) {
    final isDark = controller.isDarkMode.value;
    final isTablet = !context.isPhone;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: isTablet ? 32.h : 24.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.greyColor10 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: AppColors.primaryThemeColor.withOpacity(
                isDark ? 0.18 : 0.10,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.event_note_outlined,
              color: AppColors.primaryThemeColor,
              size: 26.sp,
            ),
          ),
          SizedBox(height: 12.h),
          utils.tvCustom("No upcoming orders", AppColors.black, 13.5),
          SizedBox(height: 4.h),
          utils.tvCustom(
            "Orders assigned to you will show up here as they come in.",
            AppColors.greyColor4,
            11.5,
            maxLines: 3,
          ),
        ],
      ),
    );
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
      onTap: () => Get.toNamed(Routes.orderListScreen)?.then((_) {
        selectedNavIndex.value = 0;
        controller.getNextDelivery();
        controller.fetchAvailableOrders();
      }),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 16.h : 13.h,
          horizontal: isTablet ? 20.w : 14.w,
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 48.w : 38.w,
              height: isTablet ? 48.w : 38.w,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(controller.isDarkMode.value ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(isTablet ? 12.r : 10.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                _upcomingStatusIcon(status),
                color: statusColor,
                size: (isTablet ? 22 : 19).sp,
              ),
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
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  utils.tvCustom(
                    (order.consigneeName?.isNotEmpty ?? false)
                        ? order.consigneeName!
                        : (order.merchantName ?? ""),
                    AppColors.greyColor4,
                    11,
                    textAlignment: TextAlign.left,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(
                        controller.isDarkMode.value ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: utils.tvCustom(
                      status,
                      statusColor,
                      9,
                      textAlignment: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isTablet ? 10.w : 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                utils.tvCustom(
                  _dueInLabel(remaining),
                  overdue ? AppColors.red : AppColors.black,
                  12,
                ),
                const SizedBox(height: 4),
                _paymentBadge(order),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: controller.isDarkMode.value
                  ? AppColors.greyColor4
                  : const Color(0xFFC7C7C7),
              size: 18,
            ),
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
        color: color.withOpacity(controller.isDarkMode.value ? 0.22 : 0.14),
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
              offset: const Offset(0, 6),
            ),
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
              child: Icon(
                Icons.two_wheeler,
                color: Colors.white,
                size: (isTablet ? 28 : 24).sp,
              ),
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
                          "Continue B2C Delivery",
                          Colors.white,
                          14,
                          textAlignment: TextAlign.left,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: utils.tvCustom(
                          "LIVE",
                          Colors.white,
                          9,
                          textAlignment: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  utils.tvCustom(
                    "1 active order in progress",
                    Colors.white70,
                    11.5,
                    textAlignment: TextAlign.left,
                  ),
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
    final cardBg = controller.isDarkMode.value ? AppColors.greyColor10 : Colors.white;
    final chevronColor = controller.isDarkMode.value
        ? AppColors.greyColor4
        : const Color(0xFFC7C7C7);
    return InkWell(
      borderRadius: BorderRadius.circular(isTablet ? 20.r : 14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20.w : 14.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(isTablet ? 20.r : 14.r),
          border: controller.isDarkMode.value
              ? Border.all(color: Colors.white.withOpacity(0.08))
              : null,
          boxShadow: controller.isDarkMode.value
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 56.w : 44.w,
              height: isTablet ? 56.w : 44.w,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(isTablet ? 16.r : 12.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: iconColor,
                size: (isTablet ? 28 : 22).sp,
              ),
            ),
            SizedBox(width: isTablet ? 16.w : 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  utils.tvCustom(
                    title,
                    AppColors.black,
                    14,
                    textAlignment: TextAlign.left,
                  ),
                  const SizedBox(height: 2),
                  utils.tvCustom(
                    subtitle,
                    AppColors.greyColor4,
                    11.5,
                    textAlignment: TextAlign.left,
                  ),
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
      final navBg = controller.isDarkMode.value ? AppColors.greyColor10 : Colors.white;
      return Container(
        padding: EdgeInsets.fromLTRB(
          6,
          isTablet ? 16.h : 10.h,
          6,
          isTablet ? 16.h : 14.h,
        ),
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isTablet ? 26.r : 20.r),
          ),
          border: controller.isDarkMode.value
              ? Border(top: BorderSide(color: Colors.white.withOpacity(0.08)))
              : null,
          boxShadow: controller.isDarkMode.value
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
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
                onTap: () {
                  selectedNavIndex.value = 0;
                  controller.getDashBoardData();
                  controller.getNextDelivery();
                  controller.fetchAvailableOrders();
                  controller.fetchWalletAmount();
                },
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
                  Get.toNamed(
                      Routes.activeDeliveryScreen
                    // controller.isAnyActiveOrder.value
                    //     ? Routes.activeDeliveryScreen
                    //     : Routes.allOrdersMapScreen,
                  )?.then((_) {
                    selectedNavIndex.value = 0;
                    controller.getNextDelivery();
                    controller.fetchAvailableOrders();
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
                  controller.getUserData();
                  controller.fetchWalletAmount();
                  Get.toNamed(Routes.accountScreen)?.then((_) {
                    selectedNavIndex.value = 0;
                  });
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
    final inactiveColor = controller.isDarkMode.value
        ? AppColors.greyColor3
        : AppColors.greyColor4;
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
                    ? AppColors.primaryThemeColor.withOpacity(
                        controller.isDarkMode.value ? 0.16 : 0.10,
                      )
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
                            color: controller.isDarkMode.value
                                ? AppColors.greyColor10
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            utils.tvCustom(label, color, isTablet ? 12.5 : 10.5, maxLines: 1),
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
      if (!controller.showMenu.value) {
        return const SizedBox.shrink();
      }
      return Stack(
        children: [
          // Scrim - tap outside to close
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                controller.showMenu.value = false;
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
              constraints: BoxConstraints(
                maxHeight: context.isPhone ? 520.sp : 650.sp,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
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
                                  controller.showMenu.value = false;
                                  selectedNavIndex.value = 0;
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Color(0xFFB0B0B0),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: showUpdateProfileDialog,
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
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        controller.userData.name ?? "",
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        controller.userData.email ?? "",
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.greyColor4,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppColors.primaryThemeColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(
                            () => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryThemeColor.withOpacity(
                                  0.08,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 16,
                                    color: AppColors.primaryThemeColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "QAR ${controller.walletAmount.value}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryThemeColor,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    "WALLET",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryThemeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),

                    // Menu rows
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          _menuRow(
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppColors.primaryThemeColor,
                            iconBg: AppColors.primaryThemeColor.withOpacity(
                              0.10,
                            ),
                            label: "My Orders",
                            onTap: () {
                              controller.showMenu.value = false;
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
                              controller.showMenu.value = false;
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
                        horizontal: 8,
                        vertical: 6,
                      ),
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
                              "Do you want to Logout from app?",
                              "",
                              () async {
                                var isLoggedOut = await controller.logout();
                                if (isLoggedOut) {
                                  userRepository.deleteUser();
                                  Get.offAllNamed(Routes.auth);
                                }
                              },
                              () {
                                Get.back();
                              },
                            );
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
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFC7C7C7),
                size: 15,
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isTablet;

  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: isTablet ? 44.w : 36.w,
          width: isTablet ? 44.w : 36.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(isTablet ? 12.r : 10.r),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: (isTablet ? 22 : 19).sp),
        ),
        SizedBox(width: isTablet ? 14.w : 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              utils.tvCustom(
                title,
                Colors.white,
                14.5,
                textAlignment: TextAlign.left,
              ),
              SizedBox(height: isTablet ? 4.h : 3.h),
              utils.tvCustom(
                description,
                Colors.white.withOpacity(0.6),
                12.5,
                textAlignment: TextAlign.left,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Reports its child's natural (unconstrained) height after each layout, so
// a fixed-height parent (e.g. a PageView page) can be resized to fit it
// instead of leaving blank space when the content is shorter.
// Renders `child` with no height constraint (a caller wraps this in an
// Offstage Column so it lays out at its natural size) and reports the
// real rendered height after each layout - more reliable than an
// intrinsic-height query, which can underestimate nested Row/Column
// button layouts.
class _MeasuredCarouselCard extends StatefulWidget {
  final Widget child;
  final ValueChanged<double> onMeasured;

  const _MeasuredCarouselCard({required this.child, required this.onMeasured});

  @override
  State<_MeasuredCarouselCard> createState() => _MeasuredCarouselCardState();
}

class _MeasuredCarouselCardState extends State<_MeasuredCarouselCard> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final height = box.size.height;
        if (height.isFinite && height > 0) {
          widget.onMeasured(height);
        }
      }
    });
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
