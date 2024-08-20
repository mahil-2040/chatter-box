import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:chatter_box/screens/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:searchfield/searchfield.dart';

import '../models/group.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  QuerySnapshot? searchSnapshot;
  bool hasUserSearched = false;
  User? user = FirebaseAuth.instance.currentUser;
  String userName = "";
  bool isJoined = false;
  List<Group> groups = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('groups').get();

      List<Group> fetchedGroups = snapshot.docs.map((doc) {
        return Group.fromDocument(doc);
      }).toList();

      setState(() {
        groups = fetchedGroups;
      });
    } catch (e) {
      throw ('Error fetching groups: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  void fetchUserData() async {
    if (user != null) {
      Map<String, dynamic>? userData = await getUserData(user!.uid);

      if (userData != null) {
        setState(() {
          userName = userData['user_name'];
        });
      }
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 32, 45),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 27, 32, 45),
        title: const Text(
          'Search',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 28, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SearchField<Group>(
          maxSuggestionsInViewPort: 5,
          itemHeight: 80,
          hint: 'Search for groups',
          searchStyle: const TextStyle(color: Colors.white),
          suggestionsDecoration: SuggestionDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(12),
            ),
            color: const Color.fromARGB(255, 122, 129, 148),
            border: Border.all(
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          suggestionItemDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              shape: BoxShape.rectangle,
              color: const Color.fromARGB(255, 122, 129, 148),
              border: Border.all(
                  color: Colors.transparent,
                  style: BorderStyle.solid,
                  width: 1.0)),
          searchInputDecoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.withOpacity(0.2),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            hintStyle: const TextStyle(color: Colors.white),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Colors.white,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            border: const OutlineInputBorder(),
          ),
          marginColor: const Color.fromARGB(255, 122, 129, 148),
          suggestions: groups
              .map((group) => SearchFieldListItem<Group>(
                    group.name,
                    child: GroupTiles(
                      userName: userName,
                      groupName: group.name,
                      groupId: group.id,
                      admin: group.admin,
                      isUserJoined: isUserJoined,
                      joinGroup: joinGroup,
                      showErrorDialog: _showErrorDialog,
                      parentContext: context,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }


  Future<bool> isUserJoined(
      String userName, String groupName, String groupId) async {
    DocumentReference userDocumentReference =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);
    DocumentSnapshot documentSnapshot = await userDocumentReference.get();

    List<dynamic> groups = documentSnapshot['groups'];

    return groups.contains(groupId);
  }

  Future<void> joinGroup(
      String userName, String groupName, String groupId) async {
    if (user == null) {
      throw Exception("No user is signed in");
    }

    DocumentReference userDocumentReference =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);
    DocumentReference groupDocumentReference =
        FirebaseFirestore.instance.collection('groups').doc(groupId);

    DocumentSnapshot userdocumentSnapshot = await userDocumentReference.get();
    DocumentSnapshot groupdocumentSnapshot = await groupDocumentReference.get();

    List<dynamic> groups = userdocumentSnapshot['groups'];

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      if (!groups.contains(groupId)) {
        if (groupdocumentSnapshot['admin'] == null) {
          transaction.update(groupDocumentReference, {'admin': user!.uid});
        }
        transaction.update(userDocumentReference, {
          'groups': FieldValue.arrayUnion([groupId]),
        });
        transaction.update(groupDocumentReference, {
          'members': FieldValue.arrayUnion([(user!.uid)]),
        });
      }
    });
  }

  void _showErrorDialog(String message, String title, Color color) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: color,
        title: title,
        message: message,
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future<String> getAdminName(String id) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(id).get();
    return userDoc['user_name'];
  }
}

class GroupTiles extends StatelessWidget {
  final String userName;
  final String groupName;
  final String groupId;
  final String? admin;
  final Future<bool> Function(String, String, String) isUserJoined;
  final Future<void> Function(String, String, String) joinGroup;
  final void Function(String, String, Color) showErrorDialog;
  final BuildContext parentContext;

  const GroupTiles({
    super.key,
    required this.userName,
    required this.groupName,
    required this.groupId,
    required this.admin,
    required this.isUserJoined,
    required this.joinGroup,
    required this.showErrorDialog,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isUserJoined(userName, groupName, groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            title: Text('Loading...'),
          );
        }
        if (snapshot.hasError) {
          return const ListTile(
            title: Text('Error loading group'),
          );
        }
        bool isJoined = snapshot.data ?? false;
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: const Color.fromARGB(255, 41, 47, 63),
            child: Text(
              groupName.isNotEmpty ? groupName[0].toUpperCase() : '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          title: Text(
            groupName,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white54),
          ),
          subtitle: admin == null || admin!.isEmpty
              ? const Text(
                  'No members in the group',
                  style: TextStyle(color: Color.fromARGB(255, 179, 185, 201)),
                )
              : FutureBuilder<String>(
                  future: _SearchScreenState().getAdminName(admin!),
                  builder: (context, adminSnapshot) {
                    if (adminSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Text(
                        'Loading admin name...',
                        style: TextStyle(
                            color: Color.fromARGB(255, 179, 185, 201)),
                      );
                    }

                    if (adminSnapshot.hasError) {
                      return const Text(
                        'Error loading admin name',
                        style: TextStyle(
                            color: Color.fromARGB(255, 179, 185, 201)),
                      );
                    }

                    return Text(
                      'Admin: ${adminSnapshot.data}',
                      style: const TextStyle(
                          color: Color.fromARGB(255, 179, 185, 201)),
                    );
                  },
                ),
          trailing: isJoined
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black,
                  ),
                  child: const Text(
                    'Joined',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : InkWell(
                  onTap: () async {
                    await joinGroup(userName, groupName, groupId);
                    showErrorDialog(
                      'You have joined the group $groupName successfully!',
                      'Group Joined',
                      Colors.green,
                    );
                    Navigator.of(parentContext).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          groupId: groupId,
                          groupName: groupName,
                          userName: userName,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 41, 47, 63),
                    ),
                    child: const Text(
                      'Join Now',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
