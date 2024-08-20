import 'package:chatter_box/screens/chat.dart';
import 'package:flutter/material.dart';

class GroupTile extends StatefulWidget {
  const GroupTile({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.userName,
    required this.lastMessage,
    required this.lastMessageSender,
    required this.lastMessageTime,
    required this.groupImage,
  });

  final String userName;
  final String groupName;
  final String groupImage;
  final String groupId;
  final String lastMessage;
  final String lastMessageSender;
  final String lastMessageTime;

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
            backgroundColor: const Color.fromARGB(255, 27, 32, 45),
            foregroundImage: widget.groupImage != "" ? NetworkImage(widget.groupImage) : null,
            child: widget.groupImage == "" ? Text(
              widget.groupName[0].toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ) : null,
          ),
          title: Row(
            children: [
              Text(
                widget.groupName,
                textAlign: TextAlign.left,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              Text(
                widget.lastMessageTime,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          subtitle: Text(
            '${widget.lastMessageSender} : ${widget.lastMessage}',
            maxLines: 1, // Set the maximum number of lines to display
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 16, color: Color.fromARGB(255, 179, 185, 201)),
          ),
        ),
      ),
    );
  }
}
