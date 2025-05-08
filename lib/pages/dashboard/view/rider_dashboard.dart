import 'dart:ui';

import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../../app_pages/app_pages.dart';
import '../../../global/consts.dart';
import '../components/attandanceItem.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  final RiderDashboardController controller =
  Get.put(RiderDashboardController());

  var showMenu = false.obs;

  @override
  void initState() {
    controller.getUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
            children: [
          Obx(() {
            return Visibility(
              visible: !controller.isAttendanceMarked.value,
              child: Container(
                height: Get.height,
                width: Get.width,
                color: AppColors.white,
                child: Center(
                    child: SizedBox(
                      height: 200,
                      width: Get.width - 50,
                      child: Image.asset(appLogo),
                    )
                ),
              ),
            );
          }),
          Obx(() {
            return Visibility(
              visible: controller.isAttendanceMarked.value,
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Container(
                        height: utils.isMobileScreen(context) ? 620 : 920,
                        width: Get.width - 20,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.primaryThemeColor),
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.primaryThemeColor.withOpacity(0.1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaY: 1, sigmaX: 1),
                              child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Obx(() {
                                        return Container(
                                          height: utils.isMobileScreen(context)
                                              ? 160
                                              : 260,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 15),
                                          decoration: utils.roundedBorder(
                                              AppColors.primaryThemeColor, 10),
                                          child: Padding(
                                              padding:
                                              const EdgeInsets.all(15.0),
                                              child: controller
                                                  .attendancesList.isEmpty
                                                  ? utils.iosProgressIndicator(
                                                  AppColors.primaryThemeColor,
                                                  "Fetching...")
                                                  : Column(
                                                children: [
                                                  utils.tvCustom(
                                                      "Working Hours/Day",
                                                      AppColors
                                                          .primaryThemeColor,
                                                      10),
                                                  SizedBox(
                                                    height:
                                                    context.isPhone
                                                        ? 100
                                                        : 160,
                                                    child:
                                                    ListView.builder(
                                                        scrollDirection:
                                                        Axis
                                                            .horizontal,
                                                        itemCount:
                                                        controller
                                                            .attendancesList
                                                            .length,
                                                        itemBuilder:
                                                            (context,
                                                            position) {
                                                          return AttendanceProgressBar(
                                                              attendance:
                                                              controller
                                                                  .attendancesList[position]);
                                                        }),
                                                  ),
                                                  utils.tvCustom(
                                                      "Work Days",
                                                      AppColors
                                                          .primaryThemeColor,
                                                      10),
                                                ],
                                              )),
                                        );
                                      }),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          // Get.toNamed(Routes.ordersScreen);
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 15),
                                          decoration:
                                          utils.boxDecorationWhite(),
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                                utils.isMobileScreen(context)
                                                    ? 8.0
                                                    : 20),
                                            child: Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Padding(
                                                  padding:
                                                  const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    children: [
                                                      utils.imageView(
                                                          myOrdersImage,
                                                          utils.isMobileScreen(
                                                              context)
                                                              ? 35
                                                              : 60,
                                                          utils.isMobileScreen(
                                                              context)
                                                              ? 35
                                                              : 50),
                                                      const SizedBox(width: 10),
                                                      utils.tvCustom(
                                                          "My Orders",
                                                          AppColors
                                                              .primaryThemeColor,
                                                          15)
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    utils.tvCustom(
                                                        "Today's Orders",
                                                        AppColors
                                                            .primaryThemeColor,
                                                        14),
                                                    Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                      children: [
                                                        utils.tvCustom(
                                                            "Assigned : ${controller
                                                                .dashBoardData
                                                                .value
                                                                .todayOrdersCount
                                                                ?.aSSIGNED}",
                                                            AppColors.black,
                                                            12),
                                                        utils.tvCustom(
                                                            "Picked : ${controller
                                                                .dashBoardData
                                                                .value
                                                                .todayOrdersCount
                                                                ?.pICKED}",
                                                            AppColors.black,
                                                            12)
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                      children: [
                                                        utils.tvCustom(
                                                            "OFD : ${controller
                                                                .dashBoardData
                                                                .value
                                                                .todayOrdersCount
                                                                ?.oFD}",
                                                            AppColors.black,
                                                            12),
                                                        utils.tvCustom(
                                                            "Delivered : ${controller
                                                                .dashBoardData
                                                                .value
                                                                .todayOrdersCount
                                                                ?.dELIVERED}",
                                                            AppColors.black,
                                                            12)
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    utils.tvCustom(
                                                        "All Orders",
                                                        AppColors
                                                            .primaryThemeColor,
                                                        14),
                                                    Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                      children: [
                                                        utils.tvCustom(
                                                            "Assigned : ${controller
                                                                .dashBoardData
                                                                .value
                                                                .allOrdersCount
                                                                ?.aSSIGNED}",
                                                            AppColors.black,
                                                            12),
                                                        utils.tvCustom(
                                                            "Picked : ${controller
                                                                .dashBoardData
                                                                .value
                                                                .allOrdersCount
                                                                ?.pICKED}",
                                                            AppColors.black,
                                                            12)
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                      children: [
                                                        utils.tvCustom(
                                                            "OFD : ${controller
                                                                .dashBoardData
                                                                .value
                                                                .allOrdersCount
                                                                ?.oFD}",
                                                            AppColors.black,
                                                            12),
                                                        utils.tvCustom(
                                                            "Delivered : ${controller
                                                                .dashBoardData
                                                                .value
                                                                .allOrdersCount
                                                                ?.dELIVERED}",
                                                            AppColors.black,
                                                            12)
                                                      ],
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Get.toNamed(Routes.nearByOrders);
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 15),
                                          decoration:
                                          utils.boxDecorationWhite(),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Padding(
                                                  padding:
                                                  const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    children: [
                                                      utils.imageView(
                                                          nearByImage,
                                                          context.isPhone
                                                              ? 50
                                                              : 60,
                                                          context.isPhone
                                                              ? 50
                                                              : 50),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      utils.tvCustom(
                                                          "Nearby Pickup Orders",
                                                          AppColors
                                                              .primaryThemeColor,
                                                          16)
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Obx(() {
                                        return Visibility(
                                          visible: controller.isAnyActiveOrder.value,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 15),
                                            decoration:
                                            utils.boxDecorationWhite(),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                  8.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  Padding(
                                                    padding:
                                                    const EdgeInsets.all(8.0),
                                                    child: InkWell(
                                                      onTap: () {
                                                        Get.toNamed(Routes
                                                            .allOrdersMapScreen);
                                                      },
                                                      child: Row(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                        children: [
                                                          Column(
                                                            children: [
                                                              utils.imageView(
                                                                  icDropOrders,
                                                                  context
                                                                      .isPhone
                                                                      ? 50
                                                                      : 60,
                                                                  context
                                                                      .isPhone
                                                                      ? 50
                                                                      : 50),
                                                              utils.tvCustom(
                                                                  "Go For Pickup/Delivery",
                                                                  AppColors
                                                                      .primaryThemeColor,
                                                                  15),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          ),
                                        );
                                      })
                                    ],
                                  ))),
                        ),
                      ),
                    ),
                  ),
                  Obx(() {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          showMenu.value = true;
                          controller.fetchWalletAmount();
                        },
                        child: AnimatedContainer(
                          width: showMenu.value
                              ? context.isPhone
                              ? 250
                              : 350.0
                              : 45.0,
                          height: showMenu.value
                              ? context.isPhone
                              ? 450
                              : 600
                              : 45.0,
                          decoration: showMenu.value
                              ? utils.boxDecorationWhite()
                              : null,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.linearToEaseOut,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Visibility(
                                    visible: !showMenu.value,
                                    child: const Icon(
                                      Icons.menu_sharp,
                                      color: AppColors.primaryThemeColor,
                                    )),
                                Visibility(
                                    visible: showMenu.value,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.end,
                                          children: [
                                            InkWell(
                                                onTap: () {
                                                  showMenu.value = false;
                                                },
                                                child: const Icon(
                                                  Icons.close,
                                                  color: AppColors.red,
                                                ))
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 25,
                                              backgroundColor:
                                              AppColors.primaryThemeColor,
                                              child: Image.asset(
                                                "assets/icons/ic_rider.png",
                                                fit: BoxFit.cover,
                                                width: 45,
                                                alignment: Alignment.center,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment.start,
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                utils.tvCustom(
                                                    controller.userData.name,
                                                    AppColors.black,
                                                    15),
                                                utils.tvCustom(
                                                    controller.userData.email,
                                                    AppColors.black,
                                                    10)
                                              ],
                                            )
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Obx(() {
                                              return Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.wallet,
                                                        color: AppColors
                                                            .primaryThemeColor,
                                                      ),
                                                      const SizedBox(
                                                        width: 5,
                                                      ),
                                                      utils.tvCustom(
                                                          controller
                                                              .walletAmount
                                                              .value.toString(),
                                                          AppColors
                                                              .primaryThemeColor,
                                                          16)
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                ],
                                              );
                                            }),
                                            Column(
                                              children: [
                                                Transform.scale(
                                                    scale: 0.8,
                                                    child: Switch(
                                                        value: true,
                                                        activeTrackColor:
                                                        AppColors
                                                            .greenLight,
                                                        onChanged:
                                                            (value) async {
                                                          bool isSignIn =
                                                          await controller
                                                              .markAttendance(
                                                              false);
                                                          if (isSignIn) {
                                                            controller
                                                                .isAttendanceMarked
                                                                .value = false;
                                                          }
                                                        })),
                                                utils.tvCustom(
                                                    "Sign-Off",
                                                    AppColors.primaryThemeColor,
                                                    8)
                                              ],
                                            )
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        utils.iconButton("MY ORDERS", () {
                                          Get.toNamed(Routes.ordersScreen);
                                        },
                                            Icons.outbound_rounded,
                                            AppColors.primaryThemeColor,
                                            AppColors.white),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        utils.iconButton("NEARBY ORDERS", () {
                                          Get.toNamed(Routes.nearByOrders);
                                        },
                                            Icons.near_me,
                                            AppColors.primaryThemeColor,
                                            AppColors.white),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        utils.iconButton(
                                            "SUPPORT",
                                                () {},
                                            Icons.support_agent_rounded,
                                            AppColors.primaryThemeColor,
                                            AppColors.white),
                                        const SizedBox(
                                          height: 130,
                                        ),
                                        utils.iconButton("LOGOUT", () async {
                                          bool isLoggedOut =
                                          await controller.logout();
                                          if (isLoggedOut) {
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
                                          }
                                        }, Icons.arrow_forward, AppColors.red,
                                            AppColors.white),
                                      ],
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          Obx(() {
            return !controller.isAttendanceLoaded.value
                ? Center(child: utils.iosProgressIndicator(
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
                          Obx(
                                () =>
                                utils.tvCustom(
                                    "Welcome ${controller.riderName.toString()
                                        .toUpperCase()} mark your attendance to start working",
                                    AppColors.primaryThemeColor,
                                    20),
                          ),
                          Lottie.asset(ANIM_RIDER),
                          const SizedBox(
                            height: 20,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                            ),
                            child: utils.iconButtonWithRoundedBorder(
                                "Sign-In",
                                45, () async {
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
          })
        ]),
      ),
    );
  }
}
