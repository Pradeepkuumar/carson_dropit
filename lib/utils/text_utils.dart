import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/material.dart';
class TextUtil extends StatelessWidget {
  String text;
  Color? color;
  double? size;
  bool? weight;
  TextUtil({super.key,required this.text,this.size,this.color,this.weight});

  @override
  Widget build(BuildContext context) {
    return  Text(text,

      style: TextStyle(color:color??AppColors.primaryThemeColor,fontSize:size?? 16,
          fontWeight:weight==null?FontWeight.w600: FontWeight.w700
      ),);
  }
}