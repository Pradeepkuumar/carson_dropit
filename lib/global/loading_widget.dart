
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/colors.dart';
import 'global.dart';

class LoadingWidget extends StatefulWidget {
  const LoadingWidget({super.key});

  @override
  State<StatefulWidget> createState()  =>  LoadingWidgetState();

}

class LoadingWidgetState   extends State<LoadingWidget>{
  var isLoading =  false;

  @override
  Widget build(BuildContext context) {
    return   Center(
      child: Container(
        height: Get.height,
        width: Get.width,
        color: AppColors.transparent,
        child: Center(
          child: Container(
            height: 100,
            width: 100,
            alignment: Alignment.center,
            decoration: utils.boxDecorationWhite(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    height: context.isPhone ? 50 :80,
                    width: context.isPhone ?50 :80,
                    // child: Lottie.asset(ImageConstants.ANIM_LOADING_DOTS),
                    child: GetPlatform.isAndroid
                        ? const CircularProgressIndicator(
                      color: AppColors.primaryThemeColor,
                    )
                        : utils.iosProgressIndicator(AppColors.white,"Loading..."),
                  ),
                ),
                utils.tvCustom("Loading...", AppColors.black,
                    10)
              ],
            ),
          ),
        ),
      ),
    );
  }
}