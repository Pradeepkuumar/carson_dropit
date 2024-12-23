import 'dart:ui';

import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/pages/auth/auth_controller.dart';
import 'package:carson_zyppy/pages/dashboard/rider_dashboard_controller.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';

import '../../app_pages/app_pages.dart';
import '../../global/consts.dart';
import '../../global/location_service.dart';
import '../../utils/animations.dart';
import '../../utils/text_utils.dart';

class RiderDashboard extends StatefulWidget {
  RiderDashboard({super.key});

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
        child: Stack(children: [
          Container(
            height: Get.height,
            width: Get.width,
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/images/bg_login.jpg"),
                  fit: BoxFit.fill),
            ),
          ),
          Obx(() {
            return Visibility(
              visible: controller.isAttendanceMarked.value,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      height: 400,
                      width: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black.withOpacity(0.1),
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        utils.elevatedContainer(
                                            120,
                                            120,
                                            AppColors.greenLight,
                                            "Assigned Orders",
                                            "50", () {
                                          Get.toNamed(Routes.ordersScreen);
                                        }),
                                        SizedBox(
                                          width: 20,
                                        ),
                                        utils.elevatedContainer(
                                            120,
                                            120,
                                            AppColors.blue,
                                            "Picked Orders",
                                            "20",
                                            () {}),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        utils.elevatedContainer(
                                            120,
                                            120,
                                            AppColors.secondryThemeColor,
                                            "Assigned Orders",
                                            "10",
                                            () {}),
                                        SizedBox(
                                          width: 20,
                                        ),
                                        utils.elevatedContainer(
                                            120,
                                            120,
                                            AppColors.red,
                                            "Assigned Orders",
                                            "10",
                                            () {}),
                                      ],
                                    )
                                  ],
                                ))),
                      ),
                    ),
                  ),
                  Obx(() {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          showMenu.value = true;
                        },
                        child: AnimatedContainer(
                          width: showMenu.value ? 220.0 : 45.0,
                          height: showMenu.value ? 450.0 : 45.0,
                          decoration: showMenu.value
                              ? utils.roundedBorder(AppColors.white, 5)
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
                                      color: AppColors.white,
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
                                                child: Icon(
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
                                            SizedBox(
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
                                        SizedBox(
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
                                                      Icon(
                                                        Icons.wallet,
                                                        color: AppColors
                                                            .primaryThemeColor,
                                                      ),
                                                      SizedBox(
                                                        width: 5,
                                                      ),
                                                      utils.tvCustom(
                                                          "3345.65 QR",
                                                          AppColors
                                                              .primaryThemeColor,
                                                          10)
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.av_timer,
                                                        color: AppColors
                                                            .primaryThemeColor,
                                                      ),
                                                      SizedBox(
                                                        width: 5,
                                                      ),
                                                      utils.tvCustom(
                                                          "${controller.workingHours.value} (Hrs)",
                                                          AppColors
                                                              .primaryThemeColor,
                                                          10)
                                                    ],
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
                                        SizedBox(
                                          height: 10,
                                        ),
                                        utils.iconButton("MY ORDERS", () {
                                          Get.toNamed(Routes.ordersScreen);
                                        },
                                            Icons.outbound_rounded,
                                            AppColors.primaryThemeColor,
                                            AppColors.white),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        utils.iconButton("NEARBY ORDERS", () {
                                          //Get.toNamed(Routes.ordersScreen);
                                        },
                                            Icons.near_me,
                                            AppColors.primaryThemeColor,
                                            AppColors.white),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        utils.iconButton(
                                            "SUPPORT",
                                            () {},
                                            Icons.support_agent_rounded,
                                            AppColors.primaryThemeColor,
                                            AppColors.white),
                                        SizedBox(
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
                                            }, () {});
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
            return Visibility(
              visible: !controller.isAttendanceMarked.value,
              child: Container(
                height: Get.height,
                width: Get.width,
                decoration: utils.boxDacorationVerticalGradient(),
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
                                utils.iconButtonWithoutBorderVertical("Logout",
                                    () {
                                  utils.simpleDialog(
                                      "Do you want to Logout from app?", "",
                                      () async {
                                    var isLoggedOut = await controller.logout();
                                    if (isLoggedOut) {
                                      userRepository.deleteUser();
                                      Get.offAllNamed(Routes.auth);
                                    }
                                  }, () {});
                                }, Icons.logout, AppColors.white),
                              ],
                            ),
                          ),
                          Spacer(),
                          Obx(
                            () => utils.tvCustom(
                                "Welcome ${controller.riderName.toString().toUpperCase()} mark your attendance to start working",
                                AppColors.white,
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
                                "Sign-In", 45, () async {
                              bool isSignIn =
                                  await controller.markAttendance(true);
                              if (isSignIn) {
                                controller.isAttendanceMarked.value = true;
                              }
                            }, Icons.start, AppColors.white,
                                Icons.electric_bike, 2.0, AppColors.white),
                          ),
                          Spacer(),
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
