import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:intl/intl.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late Future<List<Contact>> contactsFuture;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    contactsFuture = getContacts();
  }

  Future<List<Contact>> getContacts() async {
    try {
      if (await Permission.contacts.request().isGranted) {
        final contactsList =
            await ContactsService.getContacts(withThumbnails: false);
        return contactsList.toList();
      } else {
        throw Exception('Contacts permission denied');
      }
    } catch (e) {
      throw Exception('Failed to load contacts: $e');
    }
  }

  Future<void> submitContact(String name, String number) async {
    setState(() {
      isSubmitting = true; // Show loading indicator
    });

    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userData.data() != null) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'text': '${name}_$number',
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'username': userData.data()!['user_name'],
        'userImage': userData.data()!['image_url'],
        'messageType': 'contact',
      });

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'recentMessage': 'contact',
        'recentMessageSender': userData.data()!['user_name'],
        'recentMessageTime':
            '${DateFormat('d MMMM yyyy \'at\' HH:mm:ss').format(DateTime.now())} UTC+5:30',
      });

      setState(() {
        isSubmitting = false; // Hide loading indicator
      });

      Navigator.of(context).pop(); // Navigate back to chat screen
      Navigator.of(context).pop(); // Navigate back to chat screen
    } else {
      setState(() {
        isSubmitting = false; // Hide loading indicator in case of error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 32, 45),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 41, 47, 63),
        title: const Text(
          'Select Contact',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 28, color: Colors.white),
        ),
      ),
      body: isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Contact>>(
              future: contactsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No contacts found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                } else {
                  final contacts = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 14),
                    child: ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        final phoneNumbers = contact.phones
                                ?.map((item) => item.value)
                                .join(', ') ??
                            'No phone number';
                    
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                const Color.fromARGB(255, 122, 129, 148),
                            child: Text(
                              contact.givenName?.substring(0, 1).toUpperCase() ??
                                  '?',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          title: Text(
                            contact.givenName ?? 'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          subtitle: Text(
                            phoneNumbers,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color.fromARGB(255, 179, 185, 201)),
                          ),
                          onTap: () {
                            if (contact.phones != null &&
                                contact.phones!.isNotEmpty) {
                              submitContact(contact.givenName ?? 'Unknown',
                                  contact.phones!.first.value ?? 'No number');
                            } 
                          },
                          splashColor:
                              Colors.blue.withAlpha(30), // Splash effect color
                        );
                      },
                    ),
                  );
                }
              },
            ),
    );
  }
}
