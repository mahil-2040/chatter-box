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
  String groupImage = "";

  @override
  void initState() {
    super.initState();
    getChatandAdmin();
    fetchGroupData();
  }

  getChatandAdmin() {
    getGroupAdmin(widget.groupId).then((val) {
      setState(() {
        admin = val;
      });
    });
  }

  Future<Map<String, dynamic>?> getGropData(String groupid) async {
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupid)
        .get();

    if (groupDoc.exists) {
      return groupDoc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  void fetchGroupData() async {
    Map<String, dynamic>? groupData = await getGropData(widget.groupId);
    if (groupData != null) {
      setState(() {
        groupImage = groupData['groupIcon'] ?? "";
      });
    }
  }

  Future getGroupAdmin(String groupId) async {
    DocumentReference d =
        FirebaseFirestore.instance.collection('groups').doc(groupId);
    DocumentSnapshot documentSnapshot = await d.get();
    return documentSnapshot['admin'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 41, 47, 63),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: const Color.fromARGB(255, 27, 32, 45),
        title: GestureDetector(
          onTap: () {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back), // Back button icon
                onPressed: () {
                  Navigator.of(context).pop(); // Go back to the previous screen
                },
              ),
              Hero(
                tag: widget.groupId,
                child: CircleAvatar(
                  radius: 18, 
                  backgroundColor: const Color.fromARGB(255, 122, 129, 148),
                  foregroundImage: groupImage != "" ? NetworkImage(groupImage) : null,
                  child: groupImage == "" ? Text(
                    widget.groupName.isNotEmpty
                        ? widget.groupName[0].toUpperCase()
                        : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Reduce the font size to fit better
                    ),
                  ) : null ,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                widget.groupName,
                overflow: TextOverflow.ellipsis, // Prevent title overflow
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
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
