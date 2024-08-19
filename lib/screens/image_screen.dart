import 'package:flutter/material.dart';

class ImageScreen extends StatelessWidget {
  final String imageUrl;

  const ImageScreen({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
