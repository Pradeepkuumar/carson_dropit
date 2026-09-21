import 'package:carson_zyppy/global/consts.dart';
import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/pages/auth/auth_controller.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:carson_zyppy/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_pages/app_pages.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController controller = Get.put(AuthController());
  bool obscurePassword = true;

  Future<void> _onLoginTap() async {
    if (controller.feCode.value.text.isNotEmpty &&
        controller.password.value.text.isNotEmpty) {
      if (controller.isTokenLoaded.value) {
        bool isLoggedIn = await controller.login();
        if (isLoggedIn) {
          Get.offAllNamed(Routes.riderDashBord);
        } else {
          Get.snackbar('Login Failed', 'Invalid credentials');
        }
      } else {
        controller.getFireBaseToken();
      }
    } else {
      utils.errorDialog("Please Enter Credentials");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColorMain,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: GeometricBackgroundPainter()),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          SizedBox(
                            height: 110,
                            width: 200,
                            child: Image.asset(
                              appLogo,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundColorLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                utils.tvCustom(
                                    "Driver Login", Colors.white, 26),
                                const SizedBox(height: 6),
                                Align(
                                  alignment:Alignment.center,
                                  child: utils.tvMedium(
                                    "Sign in to start your shift",
                                    color: Colors.white.withOpacity(0.65),
                                    size: 13,
                                  ),

                                ),

                                const SizedBox(height: 28),
                                _LoginField(
                                  controller: controller.feCode,
                                  hint: "User ID",
                                  icon: Icons.person_outline,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 14),
                                _LoginField(
                                  controller: controller.password,
                                  hint: "Password",
                                  icon: Icons.lock_outline,
                                  obscureText: obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  trailing: InkWell(
                                    onTap: () {
                                      setState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                                    child: Icon(
                                      obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.white.withOpacity(0.6),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    onTap: () {
                                      utils.errorSnackBar(
                                        "Forgot password?",
                                        "Please contact your admin to reset your password.",
                                      );
                                    },
                                    child: utils.tvCustom("Forgot password?",
                                        AppColors.primaryThemeColor, 12.5),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _onLoginTap,
                                  child: Container(
                                    height: utils.isMobileScreen(context)
                                        ? 48
                                        : 60,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryThemeColor,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        utils.tvCustom(
                                            "Log In", Colors.white, 16),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.65),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: [
                                        const TextSpan(text: "Need help? "),
                                        TextSpan(
                                          text: "Contact operations",
                                          style: const TextStyle(
                                            color: AppColors.primaryThemeColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              utils.errorSnackBar(
                                                "Need help?",
                                                "Please reach out to your operations team for assistance.",
                                              );
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: utils.tvCustom(
                              "Secure access for authorised delivery personnel",
                              Colors.white.withOpacity(0.45),
                              12,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? trailing;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;

  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.trailing,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundColorExtraLight),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        cursorColor: AppColors.primaryThemeColor,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.6),
            size: 20,
          ),
          suffixIcon: trailing,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

