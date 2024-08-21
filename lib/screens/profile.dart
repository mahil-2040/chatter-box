import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:chatter_box/screens/home.dart';
import 'package:chatter_box/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = "";
  String email = "";
  final _usernameController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  String userImage = "";

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
      Map<String, dynamic>? userData = await getUserData(user!.uid);

      if (userData != null) {
        setState(() {
          username = userData['user_name'];
          email = userData['email'];
          userImage = userData['image_url'];
        });
      }
    }
  }

  void _showErrorDialog(String message, String title, Color color) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: color,
        title: title,
        message: message,
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
  void _pickImage(File pickedImage) {
    setState(() {
      _selectedImage = pickedImage;
    });
  }

  void _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: SpinKitWaveSpinner(
                waveColor: Color.fromARGB(255, 97, 166, 223),
                color: Color.fromARGB(255, 66, 149, 216),
                size: 80, // Adjust the size as needed
              ),
            );
          },
        );

        if (_selectedImage != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child('${user!.uid}.jpg');

          await storageRef.putFile(_selectedImage!);
          final imageUrl = await storageRef.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .update({
            'image_url': imageUrl,
          });
        }
        if (_usernameController.text.isNotEmpty &&
            _usernameController.text != "") {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .update({
            'user_name': _usernameController.text,
          });
        }

        setState(() {
          // username = _usernameController.text;
          fetchUserData();
        });

        _usernameController.clear();
        Navigator.pop(context);
        Navigator.pop(context);

        _showErrorDialog('Profile updated successfully', 'Updated', Colors.green);
      } catch (error) {
        Navigator.pop(context);
        _showErrorDialog('Failed to update profile: $error', 'Error', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 32, 45),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 27, 32, 45),
        title: const Text(
          'Profile',
          style: TextStyle(
              color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 41, 47, 63),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 50),
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  foregroundImage:
                      userImage.isNotEmpty ? NetworkImage(userImage) : null,
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            Text(
              username,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(
              height: 30,
            ),
            const Divider(
              height: 2,
            ),
            ListTile(
              onTap: () async {
                Navigator.of(context).pop();
                await Future.delayed(const Duration(milliseconds: 300));
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (ctx) => const HomeScreen()));
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(
                Icons.group,
                color: Colors.white,
              ),
              title: const Text(
                'Groups',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.of(context).pop();
              },
              selectedColor: const Color.fromARGB(255, 27, 32, 45),
              selected: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: Icon(
                Icons.account_circle,
                color: selectedColor(context, true),
                size: 30,
              ),
              title: const Text(
                'Profile',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            ListTile(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            FirebaseAuth.instance.signOut();
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    );
                  },
                );
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.exit_to_app, color: Colors.white),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          color: Color.fromARGB(255, 41, 47, 63),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 170),
        margin: const EdgeInsets.only(top: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 90,
              foregroundImage: userImage != '' ? NetworkImage(userImage) : null,
            ),
            const SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Username :',
                  style: TextStyle(fontSize: 17, color: Colors.white),
                ),
                Text(
                  username,
                  style: const TextStyle(fontSize: 17, color: Colors.white),
                ),
              ],
            ),
            const Divider(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Email :',
                  style: TextStyle(fontSize: 17, color: Colors.white),
                ),
                Text(
                  email,
                  style: const TextStyle(fontSize: 17, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: _editProfileSheet,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.pressed)) {
                      return const Color.fromARGB(
                          255, 100, 107, 125); // Pressed color
                    } else if (states.contains(WidgetState.hovered)) {
                      return const Color.fromARGB(
                          255, 140, 147, 165); // Hovered color
                    } else {
                      return const Color.fromARGB(
                          255, 122, 129, 148); // Default color
                    }
                  },
                ),
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 41, 47, 63),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserImagePicker(onPickImage: _pickImage),
                const SizedBox(
                  height: 20,
                ),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      labelText: 'UserName',
                      labelStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () {
                        _usernameController.clear();
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                            const Color.fromARGB(255, 122, 129, 148)),
                      ),
                      onPressed: () {
                        setState(() {
                          _submitProfile();
                        });
                      },
                      child: const Text(
                        'Save Profile',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color selectedColor(BuildContext context, bool isSelected) {
    return isSelected ? Colors.black : Colors.white;
  }
}
