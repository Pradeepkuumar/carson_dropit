import 'dart:ui' as ui;
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

// // Convert ByteData to Uint8List safely
// Uint8List byteDataToUint8List(ByteData byteData) {
//   final Uint8List list = Uint8List(byteData.lengthInBytes);
//   for (int i = 0; i < byteData.lengthInBytes; i++) {
//     list[i] = byteData.getUint8(i);
//   }
//   return list;
// }
//
// // Generate a dynamic marker bitmap
// Future<Uint8List> createCustomMarkerBitmap(String ordersCount, String locationName) async {
//   const int size = 150; // width and height of marker image
//
//   final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
//   final Canvas canvas = Canvas(pictureRecorder);
//   final Paint paint = Paint()..color = Colors.white;
//
//   // Draw circle
//   canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint);
//
//   // Draw border
//   final Paint borderPaint = Paint()
//     ..color = Colors.blueAccent
//     ..strokeWidth = 8
//     ..style = PaintingStyle.stroke;
//   canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, borderPaint);
//
//   // Draw text
//   final textPainter = TextPainter(
//     textAlign: TextAlign.center,
//     textDirection: TextDirection.ltr,
//     text: TextSpan(
//       text: '$ordersCount\n$locationName',
//       style: TextStyle(
//         fontSize: 20,
//         color: Colors.black,
//         fontWeight: FontWeight.bold,
//       ),
//     ),
//   );
//   textPainter.layout(minWidth: 0, maxWidth: size.toDouble());
//   textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));
//
//   final ui.Image image = await pictureRecorder.endRecording().toImage(size, size);
//   final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//
//   if (byteData == null) {
//     throw Exception("Failed to create marker image");
//   }
//
//   return byteDataToUint8List(byteData);
// }

// Future<ByteData> createCustomMarkerByteData(String title, String subtitle) async {
//   final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
//   final Canvas canvas = Canvas(pictureRecorder);
//   final Paint paint = Paint()..color = AppColors.primaryThemeColor;
//   const double size = 50.0;
//
//   canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
//
//   final textPainter = TextPainter(
//     textDirection: TextDirection.ltr,
//     text: TextSpan(
//       text: '$title\n$subtitle',
//       style: TextStyle(fontSize: 12.0, color: Colors.white),
//     ),
//   );
//
//   textPainter.layout(maxWidth: size);
//   textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));
//
//   final image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
//   final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//
//   return byteData!;
// }

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


