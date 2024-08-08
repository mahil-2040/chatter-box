import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
  }

  void _submit() async {
    final enteredMessage = _messageController.text;
    if (enteredMessage.trim().isEmpty) {
      return;
    }

    // FocusScope.of(context).unfocus();
    _messageController.clear();

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
    });

    FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'recentMessage': enteredMessage,
      'recentMessageSender': userData.data()!['user_name'],
      'recentMessageTime' : '${DateFormat('d MMMM yyyy \'at\' HH:mm:ss').format(DateTime.now())} UTC+5:30',
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color:  Color.fromARGB(255, 27, 32, 45),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))
        ),
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

  Widget _buildBottomSheetItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 5,),
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color.fromARGB(255,122, 129, 148),
          child: IconButton(
            icon: Icon(icon, size: 30, color: Colors.black,),
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 3),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white),),
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
                    color: const Color.fromARGB(255,147, 152, 167),
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
                    color: const Color.fromARGB(255,147, 152, 167),
                  ),
                  IconButton(
                    onPressed: () {},
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
