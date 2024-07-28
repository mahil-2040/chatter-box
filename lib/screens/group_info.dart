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

  Future leaveGroup(
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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 107, 114, 128),
        title: const Text(
          'Group Info',
          style: TextStyle(
            color: Colors.black,
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
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await leaveGroup(
                                  userName, widget.groupName, widget.groupId);

                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (ctx) => const HomeScreen()));
                            },
                            child: const Text('Confirm'),
                          ),
                        ],
                      );
                    });
              },
              icon: const Icon(Icons.exit_to_app))
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
                  const SizedBox(
                    width: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group : ${widget.groupName}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Admin : ${getName(widget.adminName)}',
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

  memberList() {
    return StreamBuilder(
      stream: members,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data['members'] != null) {
            if (snapshot.data['members'].length != 0) {
              return ListView.builder(
                itemCount: snapshot.data['members'].length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            const Color.fromARGB(255, 107, 114, 128),
                        child: Text(
                          getName(snapshot.data['members'][index])[0]
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(getName(snapshot.data['members'][index])),
                      subtitle: Text(getId(snapshot.data['members'][index])),
                    ),
                  );
                },
              );
            } else {
              return const Center(
                child: Text("NO MEMBERS"),
              );
            }
          } else {
            return const Center(
              child: Text("NO MEMBERS"),
            );
          }
        } else {
          return Center(
              child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ));
        }
      },
    );
  }
}
