import 'package:flutter/material.dart';

class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start from the top-left corner
    path.moveTo(0, 0);

    // Draw line to the bottom of the green part (adjust height if needed)
    path.lineTo(0, size.height * 0.6); 

    // Draw diagonal line to the right side
    path.lineTo(size.width, size.height * 0.4);

    // Close the path back to top-right corner
    path.lineTo(size.width, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
