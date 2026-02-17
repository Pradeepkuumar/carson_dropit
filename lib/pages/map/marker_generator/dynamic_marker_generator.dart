import 'dart:ui' as ui;
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

Future<ByteData> createCustomMarkerByteData(String title, String subtitle) async {
  const double width = 120;
  const double height = 100;
  const double pointerHeight = 20;

  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Paint paint = Paint()..color = subtitle=="DELIVERY"?AppColors.greenLight:AppColors.blue;


  final Rect rect = Rect.fromLTWH(0, 0, width, height);
  final RRect roundedRect = RRect.fromRectAndRadius(rect, Radius.circular(10));
  canvas.drawRRect(roundedRect, paint);

  final Path pointer = Path()
    ..moveTo(width / 2 - 10, height)
    ..lineTo(width / 2 + 10, height)
    ..lineTo(width / 2, height + pointerHeight)
    ..close();
  canvas.drawPath(pointer, paint);

  // Setup text
  final textSpan = TextSpan(
    text: '$title\n$subtitle',
    style: TextStyle(fontSize: 12.0, color: AppColors.white, height: 1.2),
  );

  final textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  textPainter.layout(
    maxWidth: width - 20,
  );

  // Paint text inside rectangle (centered)
  final offset = Offset(
    (width - textPainter.width) / 2,
    (height - textPainter.height) / 2,
  );
  textPainter.paint(canvas, offset);

  // Finish recording
  final image = await pictureRecorder.endRecording().toImage(
    width.toInt(),
    (height + pointerHeight).toInt(), // total height including pointer
  );

  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!;
}


