import 'package:flutter/material.dart';
import '../../global/global.dart';
import '../../utils/colors.dart';

Widget popUpWindowItem<T>(T item,String name,void Function(T) onClick) {
  return InkWell(
    child: Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        decoration: utils.roundedBorder(AppColors.greyColor4, 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                name.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.fade,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    onTap: () {
      onClick(item);
    },
  );
}
