import 'dart:io';

import 'package:chatter_box/screens/contacts.dart';
import 'package:chatter_box/screens/image_preview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

enum MessageType { text, image, voice, location, contacts}

class NewMessage extends StatefulWidget {
  const NewMessage({super.key, required this.groupId});

  final String groupId;

  @override
  State<NewMessage> createState() {
    return _NewMessageState();
  }
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();
  File? _pickedImageFile;
  String imageUrl = "";
  var messageType = MessageType.text;
  final imageId = const Uuid().v1();
  double? lat;
  double? lng;

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
  }

  void _submit() async {
    String enteredMessage = "";
    if (messageType == MessageType.text) {
      enteredMessage = _messageController.text;
    } else if (messageType == MessageType.image) {
      enteredMessage = imageUrl;
    } else if (messageType == MessageType.location) {
      enteredMessage = "${lat.toString()}_${lng.toString()}";
    }
    if (enteredMessage.trim().isEmpty) {
      return;
    }

    _messageController.clear();
    FocusScope.of(context).unfocus();

    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'text': enteredMessage,
      'createdAt': Timestamp.now(),
      'userId': user.uid,
      'username': userData.data()!['user_name'],
      'userImage': userData.data()!['image_url'],
      'messageType': messageType.toString().split('.').last, // Store as string
    });

    FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'recentMessage': getmessagetype(enteredMessage, messageType),
      'recentMessageTime':
          '${DateFormat('d MMMM yyyy \'at\' HH:mm:ss').format(DateTime.now())} UTC+5:30',
    });

    setState(() {
      messageType = MessageType.text;
      imageUrl = ""; // Clear the image URL
      _pickedImageFile = null; // Clear the picked image file
    });
    
    if(messageType == MessageType.location){
      Navigator.of(context).pop();
    }
  }

  String getmessagetype(String message, MessageType messageType) {
    switch (messageType) {
      case MessageType.text:
        return message;
      case MessageType.image:
        return 'Image';
      case MessageType.contacts:
        return 'Contact';
      case MessageType.location:
        return 'Location';
      default:
        return message;
    }
  }
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
            color: Color.fromARGB(255, 27, 32, 45),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28), topRight: Radius.circular(28))),
        height: 150,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
          child: GridView.count(
            crossAxisCount: 4,
            children: [
              _buildBottomSheetItem(Icons.camera_alt, 'Camera'),
              _buildBottomSheetItem(Icons.photo, 'Gallery'),
              _buildBottomSheetItem(Icons.contact_mail, 'Contact'),
              _buildBottomSheetItem(Icons.location_on, 'Location'),
            ],
          ),
        ),
      ),
    );
  }

  void contactSelector() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ContactsScreen(
          groupId: widget.groupId,
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw "Location services are disabled.";
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw "Location permission denied.";
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw "Location permission is permanently denied.";
      }

      Position position = await Geolocator.getCurrentPosition();
      _updateLocation(position);
      _listenToLocationUpdates();
      setState(() {
        messageType = MessageType.location;
      });
      _submit();
    } catch (e) {
      throw 'something went wrong! Try again later';
    }
  }

  void _updateLocation(Position position) {
    setState(() {
      lat = position.latitude;
      lng = position.longitude;
    });
  }

  void _listenToLocationUpdates() {
    Geolocator.getPositionStream(
            locationSettings: const LocationSettings(distanceFilter: 100))
        .listen(_updateLocation);
  }

  void _imagePicker(String type) async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedImage;

    if (type == 'Camera') {
      pickedImage = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );
    } else if (type == 'Gallery') {
      pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
    }

    if (pickedImage == null) {
      return;
    }

    // Navigate to the image preview screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(
          imageFile: File(pickedImage!.path),
          onSend: () async {
            Navigator.of(context).pop(); // Close the preview screen
            try {
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('chat_images')
                  .child('$imageId.jpg');

              // Upload the image file
              await storageRef.putFile(File(pickedImage!.path));

              // Retrieve the image URL
              imageUrl = await storageRef.getDownloadURL();

              setState(() {
                messageType = MessageType.image;
                _pickedImageFile = File(pickedImage!.path);
              });

              _submit();
            } catch (e) {
              // Handle any errors that occur during upload
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to upload image. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          height: 5,
        ),
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color.fromARGB(255, 122, 129, 148),
          child: IconButton(
            icon: Icon(
              icon,
              size: 30,
              color: Colors.black,
            ),
            onPressed: () {
              label == 'Camera' || label == 'Gallery'
                  ? _imagePicker(label)
                  : (label == 'Contact'
                      ? contactSelector()
                      : _getCurrentLocation());
            },
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14, top: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: const Color.fromARGB(255, 61, 67, 84)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.keyboard_voice_rounded),
                    color: const Color.fromARGB(255, 147, 152, 167),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: TextFormField(
                        style: const TextStyle(color: Colors.white),
                        controller: _messageController,
                        autocorrect: true,
                        enableSuggestions: true,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                            hintText: 'Send a message',
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.6)),
                            border: InputBorder.none),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showAttachmentOptions,
                    icon: const Icon(Icons.attach_file),
                    color: const Color.fromARGB(255, 147, 152, 167),
                  ),
                  IconButton(
                    onPressed: () {
                      _imagePicker('Camera');
                    },
                    icon: const Icon(Icons.camera_alt),
                    color: const Color.fromARGB(255, 147, 152, 167),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 147, 152, 167),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _submit,
              icon: const Icon(
                Icons.send,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
