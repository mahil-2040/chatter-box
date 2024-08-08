import 'package:chatter_box/screens/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen(
      {super.key,
      required this.adminName,
      required this.groupId,
      required this.groupName});

  final String groupName;
  final String groupId;
  final String adminName;
  @override
  State<GroupInfoScreen> createState() {
    return _GroupInfoScreenState();
  }
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  Stream? members;
  User? user = FirebaseAuth.instance.currentUser;
  String userName = "";

  @override
  void initState() {
    super.initState();
    getMembers();
    fetchUserData();
  }

  getMembers() async {
    getgroupMembers(widget.groupId).then((val) {
      setState(() {
        members = val;
      });
    });
  }

  getgroupMembers(String groupId) async {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .snapshots();
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

  String getName(String res) {
    return res.substring(res.indexOf('_') + 1);
  }

  String getId(String res) {
    return res.substring(0, res.indexOf("_"));
  }

  Future leaveGroup(String userName, String groupName, String groupId) async {
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
    List<dynamic> members = groupdocumentSnapshot['members'];

    // Check if the user is the admin
    bool isAdmin = groupdocumentSnapshot['admin'] == '${user!.uid}_$userName';

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      if (groups.contains('${groupId}_$groupName')) {
        if (isAdmin) {
          // Assign a new admin if the current user is the admin
          if (members.length > 1) {
            String newAdmin = members
                .firstWhere((member) => member != '${user!.uid}_$userName');
            transaction.update(groupDocumentReference, {'admin': newAdmin});
          } else {
            transaction.update(groupDocumentReference, {'admin': null});
          }
        }
        transaction.update(userDocumentReference, {
          'groups': FieldValue.arrayRemove(['${groupId}_$groupName']),
        });
        transaction.update(groupDocumentReference, {
          'members': FieldValue.arrayRemove(['${user!.uid}_$userName']),
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 32, 45),
      appBar: AppBar(
        bottomOpacity: 0.2,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 27, 32, 45),
        title: const Text(
          'Group Info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Leave'),
                        content: const Text(
                            'Are you sure you want to leave the group?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return FutureBuilder(
                                    future: leaveGroup(userName,
                                        widget.groupName, widget.groupId),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        // Close the loading dialog
                                        Navigator.of(context).pop();
                                        // Navigate to HomeScreen
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                              builder: (ctx) =>
                                                  const HomeScreen(),
                                            ),
                                          );
                                        });
                                        return const SizedBox
                                            .shrink(); // Return an empty widget
                                      } else {
                                        // Display the loading indicator
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            },
                            child: const Text('Confirm'),
                          ),
                        ],
                      );
                    });
              },
              icon: const Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ))
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        margin: const EdgeInsets.only(top: 30),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          color: Color.fromARGB(255, 41, 47, 63),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color:
                    const Color.fromARGB(255, 107, 114, 128).withOpacity(0.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color.fromARGB(255, 27, 32, 45),
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
                  const SizedBox(
                    width: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group : ${widget.groupName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Admin : ${getName(widget.adminName)}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 179, 185, 201)),
                      ),
                    ],
                  )
                ],
              ),
            ),
            memberList(),
          ],
        ),
      ),
    );
  }

  Future<String> getMemberImage(String userId) async {
    Map<String, dynamic>? memberData = await getUserData(userId);
    if (memberData != null) {
      return memberData['image_url'] as String;
    }
    return "";
  }

  memberList() {
    return StreamBuilder(
      stream: members,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }

        if (snapshot.hasData && snapshot.data['members'] != null) {
          var membersList = snapshot.data['members'];

          if (membersList.isNotEmpty) {
            return Expanded(
              // Wrap ListView in Expanded
              child: ListView.builder(
                itemCount: membersList.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  String memberId = getId(membersList[index]);
                  String memberName = getName(membersList[index]);

                  return FutureBuilder<String>(
                    future: getMemberImage(memberId),
                    builder: (context, imageSnapshot) {
                      if (imageSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return ListTile(
                          leading: const CircleAvatar(
                            radius: 30,
                            backgroundColor: Color.fromARGB(255, 27, 32, 45),
                            child: CircularProgressIndicator(),
                          ),
                          title: Text(
                            memberName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            memberId,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color.fromARGB(255, 179, 185, 201),
                            ),
                          ),
                        );
                      } else if (imageSnapshot.hasData) {
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                const Color.fromARGB(255, 27, 32, 45),
                            foregroundImage: NetworkImage(imageSnapshot.data!),
                            child: Text(
                              memberName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            memberName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            memberId,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color.fromARGB(255, 179, 185, 201),
                            ),
                          ),
                        );
                      } else {
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                const Color.fromARGB(255, 27, 32, 45),
                            child: Text(
                              memberName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            memberName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            memberId,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color.fromARGB(255, 179, 185, 201),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            );
          } else {
            return const Center(
              child: Text("No members in this group."),
            );
          }
        } else {
          return const Center(
            child: Text("No members found."),
          );
        }
      },
    );
  }
}
