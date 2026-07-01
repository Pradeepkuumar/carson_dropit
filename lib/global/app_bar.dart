import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/material.dart';

import 'global.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  

  const MyAppBar({
    Key? key,
    required this.title,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: AppColors.primaryLight,
      child: AppBar(
        title: utils.tvCustom("", AppColors.white, 16),
        backgroundColor: AppColors.primaryThemeColor,
        centerTitle: true,
        actions: actions,
        toolbarHeight: 0,
        //if we want add menu drwaer on home screen after thiis below code add 
        // drawer: Drawer(
          //   child: Center(child: InkWell(
          //     onTap: (){
          //       Get.to(const LoginScreenNew());
          //     },
          //     child: const Text("Drawer content"))),
          // ),
          //to home screen
        // leading: IconButton(
        //     icon: const Icon(Icons.backup_table),  // Menu icon
        //     onPressed: () {
        //       // Open a drawer or some menu here
        //       Scaffold.of(context).openDrawer();
        //     },
        //   ),
        iconTheme: const IconThemeData(color:  AppColors.white),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
