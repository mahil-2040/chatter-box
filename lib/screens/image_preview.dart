import 'dart:io';

import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatelessWidget {
  final File imageFile;
  final VoidCallback onSend;

  const ImagePreviewScreen({
    super.key,
    required this.imageFile,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: onSend,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Image.file(imageFile),
      ),
    );
  }
}
