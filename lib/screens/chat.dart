import 'package:chatter_box/screens/group_info.dart';
import 'package:chatter_box/widgets/chat_message.dart';
import 'package:chatter_box/widgets/new_message.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.userName,
  });

  final String userName;
  final String groupName;
  final String groupId;

  @override
  State<ChatScreen> createState() {
    return _ChatScreenState();
  }
}

class _ChatScreenState extends State<ChatScreen> {
  String admin = "";
  Stream<QuerySnapshot>? chats;

  @override
  void initState() {
    super.initState();
    getChatandAdmin();
  }

  getChatandAdmin() {
    // getChats(widget.groupId).then((val) {
    //   setState(() {
    //     chats = val;
    //   });
    // });

    getGroupAdmin(widget.groupId).then((val) {
      setState(() {
        admin = val;
      });
    });
  }

  // getChats(String groupId) async {
  //   return FirebaseFirestore.instance
  //       .collection('groups')
  //       .doc(groupId)
  //       .collection('messages')
  //       .orderBy('time')
  //       .snapshots();
  // }

  Future getGroupAdmin(String groupId) async {
    DocumentReference d =
        FirebaseFirestore.instance.collection('groups').doc(groupId);
    DocumentSnapshot documentSnapshot = await d.get();
    return documentSnapshot['admin'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 32, 45),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: const Color.fromARGB(255, 27, 32, 45),
        title: Row(
          children: [
            IconButton(
            icon: const Icon(Icons.arrow_back), // Back button icon
            onPressed: () {
              Navigator.of(context).pop(); // Go back to the previous screen
            },
          ),
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color.fromARGB(255, 41, 47, 63),
              child: Text(
                widget.groupName.isNotEmpty
                    ? widget.groupName[0].toUpperCase()
                    : '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            // const SizedBox(width: 48),
          ],
        ),
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: const Color.fromARGB(255, 27, 32, 45),
        // centerTitle: true,
        title: Text(
          widget.groupName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => GroupInfoScreen(
                    adminName: admin,
                    groupId: widget.groupId,
                    groupName: widget.groupName,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.info,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ChatMessage(
                groupId: widget.groupId,
              ),
            ),
            NewMessage(
              groupId: widget.groupId,
            ),
          ],
        ),
      ),
    );
  }
}
