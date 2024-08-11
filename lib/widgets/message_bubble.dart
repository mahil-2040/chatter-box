import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble.first({
    super.key,
    required this.userImage,
    required this.username,
    required this.message,
    required this.isMe,
    required this.time,
  }) : isFirstInSequence = true;

  const MessageBubble.next({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
  })  : isFirstInSequence = false,
        userImage = null,
        username = null;

  final bool isFirstInSequence;
  final String? userImage;
  final String? username;
  final String message;
  final bool isMe;
  final Timestamp time;

  String getMessageTime(Timestamp time) {
    
    String formattedTime = '${DateFormat('d MMMM yyyy \'at\' HH:mm:ss').format(DateTime.now())} UTC+5:30';
    DateFormat inputFormat = DateFormat("d MMMM yyyy 'at' HH:mm:ss 'UTC+5:30'");
    DateTime dateTime = inputFormat.parse(formattedTime);

    DateTime istTime = dateTime;

    String currentTime = DateFormat.jm().format(istTime);

    return currentTime;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (userImage != null)
          Positioned(
            top: 23,
            right: isMe ? 0 : null,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              backgroundImage: userImage != "" ? NetworkImage(userImage!) : null,
              child: userImage == null
                  ? const Icon(
                      Icons.account_circle,
                      size: 40,
                      color: Colors.grey,
                    )
                  : null,
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 46),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (isFirstInSequence) const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isMe ? const Color.fromARGB(255, 122, 129, 148) : const Color.fromARGB(255, 55, 62, 78),
                        borderRadius: BorderRadius.only(
                          topLeft: !isMe && isFirstInSequence ? Radius.zero : const Radius.circular(12),
                          topRight: isMe && isFirstInSequence ? Radius.zero : const Radius.circular(12),
                          bottomLeft: const Radius.circular(12),
                          bottomRight: const Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.only(
                        top: 8,
                        bottom: 8,
                        left: 18,
                        right: 14,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (username != null)
                            Text(
                              textAlign: isMe ? TextAlign.right : TextAlign.left,
                              username!,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                            ),
                          Text(
                            message,
                            textAlign: isMe ? TextAlign.right : TextAlign.left,
                            style: const TextStyle(fontSize: 15, color: Color.fromARGB(255, 220, 220, 220)),
                            softWrap: true,
                          ),
                          const SizedBox(height: 4),
                          Text(
                              getMessageTime(time),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 180, 180, 180)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
