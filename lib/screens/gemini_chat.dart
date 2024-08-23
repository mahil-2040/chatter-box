import 'dart:io';
import 'dart:typed_data';
import 'package:chatter_box/screens/image_preview.dart';
import 'package:chatter_box/screens/image_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GeminiChatScreenState();
  }
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 41, 47, 63),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 27, 32, 45),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 8),
            const CircleAvatar(
              foregroundImage:
                  AssetImage('assets/images/google-gemini-icon.png'),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemini AI',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                Text(
                  'By Google',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: const Column(
        children: [
          Expanded(
            child: GeminiChat(),
          ),
          NewPrompt(),
        ],
      ),
    );
  }
}

class GeminiChat extends StatefulWidget {
  const GeminiChat({super.key});
  @override
  State<StatefulWidget> createState() {
    return _GeminiChatState();
  }
}

class _GeminiChatState extends State<GeminiChat> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
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
          .collection('users')
          .doc(user.uid)
          .collection('geminiMessages')
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
              'Start Conversation with Gemini!',
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return ListView.builder(
          controller: _scrollController,
          itemCount: loadedMessages.length,
          padding:
              const EdgeInsets.only(bottom: 13, left: 13, right: 13, top: 8),
          itemBuilder: (ctx, index) {
            final chatMessage = loadedMessages[index].data();
            return PromptBubble(
              message: chatMessage['text'],
              isMe: chatMessage['isMe'],
              time: chatMessage['createdAt'],
              messageType: chatMessage['messageType'],
            );
          },
        );
      },
    );
  }
}

class PromptBubble extends StatelessWidget {
  const PromptBubble({
    super.key,
    required this.isMe,
    required this.message,
    required this.messageType,
    required this.time,
  });

  final bool isMe;
  final String message;
  final String messageType;
  final Timestamp time;

  String getMessageTime(Timestamp time) {
    DateTime dateTimeUtc = time.toDate();
    String formattedTime = DateFormat.jm().format(dateTimeUtc);
    return formattedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? const Color.fromARGB(255, 122, 129, 148)
              : const Color.fromARGB(255, 55, 62, 78),
          borderRadius: BorderRadius.only(
            topLeft: !isMe ? Radius.zero : const Radius.circular(12),
            topRight: isMe ? Radius.zero : const Radius.circular(12),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          ),
        ),
        padding: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: messageType == 'text' ? 18 : 5,
          right: messageType == 'text' ? 14 : 5,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: messageType == 'text'
            ? Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                        fontSize: 17,
                        color: Color.fromARGB(255, 220, 220, 220)),
                    softWrap: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getMessageTime(time),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => ImageScreen(imageUrl: message)));
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 350,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.network(
                              message,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 3,
                          child: Text(
                            getMessageTime(time),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class NewPrompt extends StatefulWidget {
  const NewPrompt({super.key});

  @override
  State<StatefulWidget> createState() {
    return _NewPromptState();
  }
}

class _NewPromptState extends State<NewPrompt> {
  final _promptController = TextEditingController();
  String messageType = 'text';
  final Gemini gemini = Gemini.instance;
  bool _isLoading = false;

  void _sendMessage() async {
    String enteredMessage = _promptController.text;
    if (enteredMessage.trim().isEmpty) {
      return;
    }
    _promptController.clear();
    FocusScope.of(context).unfocus();

    final user = FirebaseAuth.instance.currentUser!;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('geminiMessages')
        .add({
      'text': enteredMessage,
      'createdAt': Timestamp.now(),
      'messageType': 'text',
      'isMe': true,
    });

    setState(() {
      _isLoading = true;
    });

    try {
      String responseText = '';

      await for (final response
          in gemini.streamGenerateContent(enteredMessage)) {
        responseText +=
            response.content!.parts!.map((part) => part.text).join();
      }

      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('geminiMessages')
          .add({
        'text': responseText,
        'createdAt': Timestamp.now(),
        'messageType': 'text',
        'isMe': false,
      });
    } catch (e) {
      // Handle error if needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _imagePicker(String type) async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedImage;

    // Pick the image from camera or gallery
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

    // If no image is picked, return early
    if (pickedImage == null) {
      return;
    }

    // Navigate to the Image Preview Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(
          imageFile: File(pickedImage!.path),
          onSend: () async {
            Navigator.of(context).pop(); // Close preview screen

            final user = FirebaseAuth.instance.currentUser!;
            final imageId = DateTime.now().millisecondsSinceEpoch.toString();
            String imageUrl;

            try {
              // Upload the image to Firebase Storage
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('chat_images')
                  .child('$imageId.jpg');
              await storageRef.putFile(File(pickedImage!.path));

              // Get the image URL from Firebase Storage
              imageUrl = await storageRef.getDownloadURL();
              setState(() {
                _isLoading = true;
              });
              // Send the image message to Firestore
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('geminiMessages')
                  .add({
                'text': imageUrl,
                'createdAt': Timestamp.now(),
                'messageType': 'image',
                'isMe': true,
              });

              // Convert the picked image to Uint8List
              Uint8List imageBytes = await File(pickedImage.path).readAsBytes();

              // Description prompt for Gemini
              const descriptionMessage =
                  'Please analyze the following image and provide a detailed description.';

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('geminiMessages')
                  .add({
                'text': descriptionMessage,
                'createdAt': Timestamp.now(),
                'messageType': 'text',
                'isMe': true,
              });
              // Send the image bytes to Gemini and receive the response
              String responseText = '';
              await for (final response in gemini.streamGenerateContent(
                descriptionMessage,
                images: [imageBytes],
              )) {
                responseText +=
                    response.content!.parts!.map((part) => part.text).join();
              }

              // Store the response in Firestore as a message
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('geminiMessages')
                  .add({
                'text': responseText,
                'createdAt': Timestamp.now(),
                'messageType': 'text',
                'isMe': false,
              });
            } catch (e) {
              // Handle any errors that occur
              print('Error processing image: $e');
            } finally {
              // Ensure loading indicator is hidden after processing
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 15, bottom: 10, top: 10),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 27, 32, 45),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_camera, color: Colors.white),
              onPressed: () => _imagePicker('Camera'),
            ),
            IconButton(
              icon: const Icon(Icons.photo_library, color: Colors.white),
              onPressed: () => _imagePicker('Gallery'),
            ),
            Expanded(
              child: TextField(
                controller: _promptController,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: true,
                enableSuggestions: true,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Ask Gemini...',
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color.fromARGB(255, 47, 54, 67),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
