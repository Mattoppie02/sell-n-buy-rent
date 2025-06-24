import 'package:flutter/material.dart';

class SneakerCard extends StatelessWidget {
  final String imagePath;
  final String name;
  final String price;

  const SneakerCard({
    super.key,
    required this.imagePath,
    required this.name,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(price, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
