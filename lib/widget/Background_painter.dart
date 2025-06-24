import 'package:flutter/material.dart';

class DiagonalBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Top diagonal section gradient
    final topGradient = LinearGradient(
      colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 166, 236, 123)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = topGradient.createShader(rect);

    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.6);
    path.lineTo(size.width, size.height * 0.4);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);

    // Bottom diagonal section gradient
    final bottomGradient = LinearGradient(
      colors: [Color.fromARGB(255, 166, 236, 123), Color.fromARGB(255, 255, 255, 255)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    paint.shader = bottomGradient.createShader(rect);

    path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.6);
    path.lineTo(size.width, size.height * 0.4);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
