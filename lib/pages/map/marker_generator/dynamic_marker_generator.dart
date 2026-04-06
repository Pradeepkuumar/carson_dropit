

// import 'dart:ui' as ui;
// import 'package:carson_zyppy/utils/colors.dart';
// import 'package:flutter/material.dart';
// import 'dart:typed_data';

// Future<ByteData> createCustomMarkerByteData(String title, String subtitle) async {
//   const double width = 120;
//   const double height = 80;
//   const double pointerHeight = 10;

//   final bool isDelivery = subtitle == "DELIVERY";

//   final Color accentColor =
//       isDelivery ? AppColors.greenLight : AppColors.primaryThemeColor;

//   final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
//   final Canvas canvas = Canvas(pictureRecorder);

//   final Paint bgPaint = Paint()..color = accentColor;

//   final Rect bgRect = Rect.fromLTWH(0, 0, width, height);
//   final RRect bgRRect =
//       RRect.fromRectAndRadius(bgRect, const Radius.circular(16));

//   canvas.drawRRect(bgRRect, bgPaint);

//   final TextSpan titleSpan = TextSpan(
//     text: title,
//     style: const TextStyle(
//       fontSize: 16,
//       fontWeight: FontWeight.w600,
//       color: Colors.white,
//     ),
//   );

//   final TextSpan subtitleSpan = TextSpan(
//     text: subtitle,
//     style: const TextStyle(
//       fontSize: 11,
//       fontWeight: FontWeight.w500,
//       color: Colors.white,
//     ),
//   );

//   final TextPainter titlePainter = TextPainter(
//     text: titleSpan,
//     textDirection: TextDirection.ltr,
//     textAlign: TextAlign.center,
//   );

//   final TextPainter subtitlePainter = TextPainter(
//     text: subtitleSpan,
//     textDirection: TextDirection.ltr,
//     textAlign: TextAlign.center,
//   );

//   titlePainter.layout(maxWidth: width - 20);
//   subtitlePainter.layout(maxWidth: width - 20);

//   final double totalTextHeight =
//       titlePainter.height + subtitlePainter.height + 4;

//   final double startY = (height - totalTextHeight) / 2;

//   titlePainter.paint(
//       canvas, Offset((width - titlePainter.width) / 2, startY));

//   subtitlePainter.paint(
//       canvas,
//       Offset((width - subtitlePainter.width) / 2,
//           startY + titlePainter.height + 4));

//   final Path pointer = Path()
//     ..moveTo(width / 2 - 10, height)
//     ..lineTo(width / 2 + 10, height)
//     ..lineTo(width / 2, height + pointerHeight)
//     ..close();

//   final Paint pointerPaint = Paint()..color = accentColor;

//   canvas.drawPath(pointer, pointerPaint);

//   final image = await pictureRecorder.endRecording().toImage(
//         width.toInt(),
//         (height + pointerHeight).toInt(),
//       );

//   final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

//   return byteData!;
// }

import 'dart:ui' as ui;
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

Future<ByteData> createCustomMarkerByteData(String title, String subtitle) async {
  const double width = 120;
  const double height = 90;
  const double pointerHeight = 15;

  final bool isDelivery = subtitle == "DELIVERY";

  final Color accentColor =
      isDelivery ? AppColors.greenLight : AppColors.primaryThemeColor;

  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  final Rect bgRect = Rect.fromLTWH(0, 0, width, height);
  final RRect bgRRect =
      RRect.fromRectAndRadius(bgRect, const Radius.circular(16));

  final Paint bgPaint = Paint()..color = accentColor;
  canvas.drawRRect(bgRRect, bgPaint);

  final Paint glossPaint = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, height),
      [
        Colors.white.withOpacity(0.35),
        Colors.white.withOpacity(0.12),
        Colors.transparent,
      ],
      [0.0, 0.35, 1.0],
    );

  canvas.drawRRect(bgRRect, glossPaint);

  final Paint innerShadow = Paint()
    ..shader = ui.Gradient.linear(
      Offset(0, height * 0.6),
      Offset(0, height),
      [
        Colors.transparent,
        Colors.white.withOpacity(0.18),
      ],
    );

  canvas.drawRRect(bgRRect, innerShadow);

  final Paint borderPaint = Paint()
    ..color = Colors.white.withOpacity(0.35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  canvas.drawRRect(bgRRect, borderPaint);

  final TextSpan titleSpan = TextSpan(
    text: title,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );

  final TextSpan subtitleSpan = TextSpan(
    text: subtitle,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  );

  final TextPainter titlePainter = TextPainter(
    text: titleSpan,
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  final TextPainter subtitlePainter = TextPainter(
    text: subtitleSpan,
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  titlePainter.layout(maxWidth: width - 20);
  subtitlePainter.layout(maxWidth: width - 20);

  final double totalTextHeight =
      titlePainter.height + subtitlePainter.height + 4;

  final double startY = (height - totalTextHeight) / 2;

  titlePainter.paint(
      canvas, Offset((width - titlePainter.width) / 2, startY));

  subtitlePainter.paint(
      canvas,
      Offset((width - subtitlePainter.width) / 2,
          startY + titlePainter.height + 4));

  final Path pointer = Path()
    ..moveTo(width / 2 - 10, height)
    ..lineTo(width / 2 + 10, height)
    ..lineTo(width / 2, height + pointerHeight)
    ..close();

  final Paint pointerPaint = Paint()..color = accentColor;
  canvas.drawPath(pointer, pointerPaint);

  final Paint pointerBorder = Paint()
    ..color = Colors.white.withOpacity(0.35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  canvas.drawPath(pointer, pointerBorder);

  final image = await pictureRecorder.endRecording().toImage(
        width.toInt(),
        (height + pointerHeight).toInt(),
      );

  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return byteData!;
}