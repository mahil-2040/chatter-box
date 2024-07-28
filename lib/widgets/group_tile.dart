import 'package:chatter_box/screens/chat.dart';
import 'package:flutter/material.dart';

class GroupTile extends StatefulWidget {
  const GroupTile({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.userName,
  });

  final String userName;
  final String groupName;
  final String groupId;

  @override
  State<GroupTile> createState() {
    return _GroupTileState();
  }
}

class _GroupTileState extends State<GroupTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => ChatScreen(
                groupId: widget.groupId,
                groupName: widget.groupName,
                userName: widget.userName,
              ),
            ),
          );
        },
        child: ListTile(
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: const Color.fromARGB(255, 107, 114, 128),
            child: Text(
              widget.groupName[0].toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          title: Text(
            widget.groupName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Join the conversation as ${widget.userName}',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }
}
