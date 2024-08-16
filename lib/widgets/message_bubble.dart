import 'package:chatter_box/screens/image_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum MessageType { text, image, voice, location, contact }

class MessageBubble extends StatefulWidget {
  const MessageBubble.first({
    super.key,
    required this.userImage,
    required this.username,
    required this.message,
    required this.isMe,
    required this.time,
    required this.messagetype,
  }) : isFirstInSequence = true;

  const MessageBubble.next({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
    required this.messagetype,
  })  : isFirstInSequence = false,
        userImage = null,
        username = null;

  final bool isFirstInSequence;
  final String? userImage;
  final String? username;
  final String message;
  final bool isMe;
  final Timestamp time;
  final String messagetype;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  String getMessageTime(Timestamp time) {
    String formattedTime =
        '${DateFormat('d MMMM yyyy \'at\' HH:mm:ss').format(DateTime.now())} UTC+5:30';
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
        if (widget.userImage != null)
          Positioned(
            top: 23,
            right: widget.isMe ? 0 : null,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              backgroundImage: widget.userImage != ""
                  ? NetworkImage(widget.userImage!)
                  : null,
              child: widget.userImage == null
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
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: widget.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (widget.isFirstInSequence) const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 290),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.isMe
                            ? const Color.fromARGB(255, 122, 129, 148)
                            : const Color.fromARGB(255, 55, 62, 78),
                        borderRadius: BorderRadius.only(
                          topLeft: !widget.isMe && widget.isFirstInSequence
                              ? Radius.zero
                              : const Radius.circular(12),
                          topRight: widget.isMe && widget.isFirstInSequence
                              ? Radius.zero
                              : const Radius.circular(12),
                          bottomLeft: const Radius.circular(12),
                          bottomRight: const Radius.circular(12),
                        ),
                      ),
                      padding: EdgeInsets.only(
                        top: 8,
                        bottom: 8,
                        left: widget.messagetype == 'text' ? 18 : 5,
                        right: widget.messagetype == 'text' ? 14 : 5,
                      ),
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 12),
                      child: buildMessageContent(
                          widget.message, widget.messagetype),
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

  Widget buildMessageContent(String message, String messageType) {
    switch (messageType) {
      case 'text':
        return textMessage(message);
      case 'image':
        return imageMessage(message);
      case 'contact':
        return contactMessage(message);
      default:
        return textMessage(message);
    }
  }

  Widget textMessage(String text) {
    return Column(
      crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (widget.username != null)
          Text(
            widget.username!,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          ),
        Text(
          text,
          style: const TextStyle(
              fontSize: 17, color: Color.fromARGB(255, 220, 220, 220)),
          softWrap: true,
        ),
        const SizedBox(height: 4),
        Text(
          getMessageTime(widget.time),
          style: const TextStyle(
              fontSize: 12, color: Color.fromARGB(255, 180, 180, 180)),
        ),
      ],
    );
  }

  Widget imageMessage(String url) {
    return Column(
      crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (widget.username != null)
          Text(
            textAlign: widget.isMe ? TextAlign.right : TextAlign.left,
            widget.username!,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
          ),
        if (widget.username != null)
          const SizedBox(
            height: 3,
          ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => ImageScreen(imageUrl: url)));
          },
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 3,
                child: Text(
                  getMessageTime(widget.time),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget contactMessage(String contactInfo) {
    // Assuming contactInfo is a string in the format "Contact Name: Contact Number"
    List<String> contactDetails = contactInfo.split('_');
    String contactName = contactDetails[0].trim();
    String contactNumber = contactDetails[1].trim();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.contact_phone, color: Colors.white, size: 50),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contactName,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  contactNumber,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                      fontSize: 15, color: Color.fromARGB(255, 220, 220, 220)),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    getMessageTime(widget.time),
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 180, 180, 180)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
