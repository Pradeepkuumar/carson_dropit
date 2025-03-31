import 'dart:ui';

import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/pages/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_pages/app_pages.dart';
import '../../utils/text_utils.dart';

class LoginScreen extends StatefulWidget {
   const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int selectedIndex = 0;
  bool showOption = false;
  final AuthController controller = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: Get.height,
        width: Get.width,
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/images/bg_login.jpg"),
              fit: BoxFit.fill),
        ),
        alignment: Alignment.center,
        child: Container(
          height: utils.isMobileScreen(context) ? 350 : 550,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(15),
            color: Colors.black.withOpacity(0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaY: 5, sigmaX: 5),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Center(
                          child: TextUtil(
                            text: "Login",
                            weight: true,
                            size: 30,
                          )),
                      const Spacer(),
                      TextUtil(
                        text: "Email / User ID",
                      ),
                      Container(
                        height: 35,
                        decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Colors.white))),
                        child: TextFormField(
                          controller: controller.feCode,
                          style: const TextStyle(color: Colors.white),
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            suffixIcon: Icon(
                              Icons.mail,
                              color: Colors.white,
                            ),
                            fillColor: Colors.white,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextUtil(
                        text: "Password",
                      ),
                      Container(
                        height: 35,
                        decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Colors.white))),
                        child: TextFormField(
                          controller: controller.password,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            suffixIcon: Icon(
                              Icons.lock,
                              color: Colors.white,
                            ),
                            fillColor: Colors.white,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                          onTap: () async{
                            if(controller.feCode.value.text.isNotEmpty && controller.password.value.text.isNotEmpty) {
                              bool isLoggedIn = await controller.login();
                              if (isLoggedIn) {
                                Get.offAllNamed(Routes.riderDashBord);
                              } else {
                                Get.snackbar('Login Failed', 'Invalid credentials');
                              }
                            }else{
                              utils.errorDialog("Pls Enter Credentials");
                            }

                          },
                          child: Container(
                            height: utils.isMobileScreen(context)?40:60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30)),
                            alignment: Alignment.center,
                            child: TextUtil(
                              text: "Log In",
                              color: Colors.black,
                            ),
                          )),
                      const Spacer(),

                    ],
                  ),
                )),
          ),
        ),
      ),
    );
  }
}
