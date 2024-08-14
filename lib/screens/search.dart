import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:chatter_box/screens/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() {
    return _SearchScreenState();
  }
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  QuerySnapshot? searchSnapshot;
  bool hasUserSearched = false;
  User? user = FirebaseAuth.instance.currentUser;
  String userName = "";
  bool isJoined = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // String getName(String res) {
  //   return res.substring(res.indexOf('_') + 1);
  // }

  // String getId(String res) {
  //   return res.substring(0, res.indexOf("_"));
  // }

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
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                  color: const Color.fromARGB(255, 41, 47, 63),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search Groups',
                        hintStyle: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      initiateSearchMethod();
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : groupList(),
          ],
        ),
      ),
    );
  }

  Future<bool> isUserJoined(
      String userName, String groupName, String groupId) async {
    DocumentReference userDocumentReference =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);
    DocumentSnapshot documentSnapshot = await userDocumentReference.get();

    List<dynamic> groups = await documentSnapshot['groups'];

    if (groups.contains(groupId)) {
      return true;
    } else {
      return false;
    }
  }

  joinedOrNot(String userName, String groupName, String groupId) async {
    await isUserJoined(userName, groupName, groupId).then((val) {
      setState(() {
        isJoined = val;
      });
    });
  }

  initiateSearchMethod() async {
    if (searchController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      await searchByName(searchController.text).then((snapshot) {
        setState(() {
          searchSnapshot = snapshot;
          isLoading = false;
          hasUserSearched = true;
        });
      });
    }
  }

  searchByName(String groupName) {
    return FirebaseFirestore.instance
        .collection('groups')
        .where('groupName', isEqualTo: groupName)
        .get();
  }

  groupList() {
    return hasUserSearched
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: searchSnapshot!.docs.length,
            itemBuilder: (context, index) {
              return groupTile(
                userName,
                searchSnapshot!.docs[index]['groupName'],
                searchSnapshot!.docs[index]['groupId'],
                searchSnapshot!.docs[index]['admin'],
              );
            },
          )
        : Container();
  }

  Future joinGroup(String userName, String groupName, String groupId) async {
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
          transaction.update(
              groupDocumentReference, {'admin': user!.uid});
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
  getAdminName(String id) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .get();
    return userDoc['admin'] as String;
    
  }

  Widget groupTile(
      String userName, String groupName, String groupId, String? admin) {
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
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          subtitle: admin == null || admin.isEmpty
              ? const Text('No members in the group', style: TextStyle(color: Color.fromARGB(255, 179, 185, 201)),)
              : Text('Admin: ${getAdminName(admin)}', style: const TextStyle(color: Color.fromARGB(255, 179, 185, 201))),
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
                    setState(() {
                      isJoined = !isJoined;
                    });
                    _showErrorDialog(
                      'Successfully joined the group $groupName',
                      'Joined',
                      const Color.fromARGB(255, 3, 116, 6),
                    );
                    Future.delayed(const Duration(seconds: 1), () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (ctx) => ChatScreen(
                            groupId: groupId,
                            groupName: groupName,
                            userName: userName,
                          ),
                        ),
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 107, 114, 128),
                    ),
                    child: const Text(
                      'Join',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
