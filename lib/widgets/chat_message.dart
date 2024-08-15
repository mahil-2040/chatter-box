import 'package:chatter_box/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessage extends StatefulWidget {
  const ChatMessage({super.key, required this.groupId});

  final String groupId;

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Ensure that we scroll to the bottom when messages are first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    // Check if the scroll controller is attached before scrolling
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots(),
      builder: (ctx, snapshots) {
        if (snapshots.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshots.hasData || snapshots.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No Messages yet!',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshots.hasError) {
          return const Center(
            child: Text('Something went wrong!'),
          );
        }

        final loadedMessages = snapshots.data!.docs;

        // Always scroll to the bottom whenever the message list updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return ListView.builder(
          controller: _scrollController,
          itemCount: loadedMessages.length,
          padding: const EdgeInsets.only(bottom: 40, left: 13, right: 13),
          itemBuilder: (ctx, index) {
            final chatMessage = loadedMessages[index].data();
            final prevMessage =
                index - 1 >= 0 ? loadedMessages[index - 1] : null;

            final currentMessageUserId = chatMessage['userId'];
            final prevmessageUserId =
                prevMessage != null ? prevMessage['userId'] : null;

            final prevUserSame = currentMessageUserId == prevmessageUserId;

            if (prevUserSame) {
              return MessageBubble.next(
                message: chatMessage['text'],
                isMe: user.uid == currentMessageUserId,
                time: chatMessage['createdAt'],
                messagetype: chatMessage['messageType'],
              );
            } else {
              return MessageBubble.first(
                userImage: chatMessage['userImage'],
                username: chatMessage['username'],
                message: chatMessage['text'],
                isMe: user.uid == currentMessageUserId,
                time: chatMessage['createdAt'],
                messagetype: chatMessage['messageType'],
              );
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
