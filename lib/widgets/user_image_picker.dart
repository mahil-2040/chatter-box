import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class UserImagePicker extends StatefulWidget {
  const UserImagePicker({super.key, required this.onPickImage});

  final void Function(File pickImage) onPickImage;

  @override
  State<StatefulWidget> createState() {
    return _UserImagePickerState();
  }
}

class _UserImagePickerState extends State<UserImagePicker> {
  File? _pickedImageFile;
  User? user = FirebaseAuth.instance.currentUser;
  String image = "";
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  void fetchUserData() async {
    if (user != null) {
      try {
        Map<String, dynamic>? userData = await getUserData(user!.uid);
        if (userData != null) {
          setState(() {
            image = userData['image_url'] ?? '';
            isLoading = false; // Set loading to false after fetching
          });
        }
      } catch (error) {
        setState(() {
          isLoading = false; // Set loading to false in case of error
        });
      }
    }
  }

  void _pickImage(String type) async {
    XFile? pickedImage;
    if (type == 'camera') {
      pickedImage = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );
    } else {
      pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
    }

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _pickedImageFile = File(pickedImage!.path);
    });

    widget.onPickImage(_pickedImageFile!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              foregroundImage: _pickedImageFile != null
                  ? FileImage(_pickedImageFile!)
                  : (image.isNotEmpty ? NetworkImage(image) : null),
              child: (_pickedImageFile == null && image == "")
                  ? const Icon(
                      Icons.account_circle,
                      size: 80,
                    )
                  : null,
            ),
            if (isLoading)
              const CircularProgressIndicator(
                color: Colors.white,
              ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                _pickImage('gallery');
              },
              icon: const Icon(
                Icons.image,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            IconButton(
              onPressed: () {
                _pickImage('camera');
              },
              icon: const Icon(
                Icons.camera_alt,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
