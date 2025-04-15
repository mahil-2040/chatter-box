import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:chatter_box/screens/gemini_chat.dart';
import 'package:chatter_box/screens/profile.dart';
import 'package:chatter_box/screens/search.dart';
import 'package:chatter_box/widgets/group_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = "";
  String email = "";
  Stream? groups;
  bool _isLoading = false;
  String groupName = "";
  User? user = FirebaseAuth.instance.currentUser;
  String userImage = "";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getGroupData(String groupId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .get();

    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<String> getGroupImages(String groupId) async {
    Map<String, dynamic>? groupData = await getGroupData(groupId);
    if (groupData != null) {
      return groupData['groupIcon'] as String;
    }

    return "";
  }

  Future<String> getLastMessage(String groupId) async {
    Map<String, dynamic>? groupData = await getGroupData(groupId);

    if (groupData != null) {
      return groupData['recentMessage'] as String;
    }
    return "";
  }

  Future<String> getGroupNames(String groupId) async {
    Map<String, dynamic>? groupData = await getGroupData(groupId);

    if (groupData != null) {
      return groupData['groupName'] as String;
    }
    return "";
  }

  Future<String> getLastMessageTime(String groupId) async {
    Map<String, dynamic>? groupData = await getGroupData(groupId);

    if (groupData != null) {
      String time = groupData['recentMessageTime'] as String;

      try {
        DateFormat inputFormat =
            DateFormat("d MMMM yyyy 'at' HH:mm:ss 'UTC+5:30'");
        DateTime dateTime = inputFormat.parse(time);

        DateTime istTime = dateTime;

        String formattedTime = DateFormat.jm().format(istTime);

        return formattedTime;
      } catch (e) {
        return "Error parsing time";
      }
    }
    return "";
  }

  Future<String> getLastMessageSender(String groupId) async {
    Map<String, dynamic>? groupData = await getGroupData(groupId);

    if (groupData != null) {
      return groupData['recentMessageSender'] as String;
    }
    return "";
  }

  void fetchUserData() async {
    if (user != null) {
      Map<String, dynamic>? userData = await getUserData(user!.uid);

      if (userData != null) {
        setState(() {
          username = userData['user_name'];
          userImage = userData['image_url'];
        });
      }
    }
    final snapshots = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .snapshots();

    setState(() {
      groups = snapshots;
    });
  }

  Future createGroup(String userName, String id, String groupName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentReference groupDocumentReference =
          await FirebaseFirestore.instance.collection('groups').add({
        'groupName': groupName,
        'admin': id,
        'members': [],
        'groupIcon': '',
        'groupId': '',
        'recentMessage': 'Group Created by $userName',
        'recentMessageSender': userName,
        'recentMessageTime':
            '${DateFormat('d MMMM yyyy \'at\' HH:mm:ss').format(DateTime.now())} UTC+5:30',
      });

      await groupDocumentReference.update({
        'members': FieldValue.arrayUnion([(user!.uid)]),
        'groupId': groupDocumentReference.id,
      });

      DocumentReference userDocumentReference =
          FirebaseFirestore.instance.collection('users').doc(user!.uid);

      await userDocumentReference.update({
        'groups': FieldValue.arrayUnion([(groupDocumentReference.id)])
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 32, 45),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 27, 32, 45),
        title: const Text(
          'Messages',
          style: TextStyle(
              // fontFamily: "Poppins",
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => const SearchScreen(),
              ));
            },
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
            color: Colors.black,
            iconSize: 28,
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 41, 47, 63),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 50),
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  foregroundImage:
                      userImage.isNotEmpty ? NetworkImage(userImage) : null,
                ),
                if (_isLoading) const CircularProgressIndicator(),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            Text(
              username,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(
              height: 30,
            ),
            const Divider(
              height: 2,
            ),
            ListTile(
              onTap: () {
                Navigator.of(context).pop();
              },
              selectedColor: const Color.fromARGB(255, 27, 32, 45),
              selected: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: Icon(
                Icons.group,
                color: selectedColor(context, true),
                size: 30,
              ),
              title: const Text(
                'Groups',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            ListTile(
              onTap: () async {
                Navigator.of(context).pop();
                await Future.delayed(const Duration(milliseconds: 300));
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const ProfileScreen()));
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(
                Icons.account_circle,
                color: Colors.white,
              ),
              title: const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            ListTile(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
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
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            await FirebaseAuth.instance.signOut();
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    );
                  },
                );
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: groupList(),
      floatingActionButton: Stack(
        children: [
          Positioned(
            right: 10,
            bottom: 100,
            child: FloatingActionButton(
              mini: true,
              child: Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(15),
                ),
                child:
                    const Image(image: AssetImage('assets/images/google-gemini-icon.png')),
              ),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const GeminiChatScreen()));
              },
            ),
          ),
          Positioned(
            right: 5,
            bottom: 30,
            child: FloatingActionButton(
              onPressed: () {
                popUpDialog(context);
              },
              backgroundColor: const Color.fromARGB(255, 147, 152, 167),
              child: const Icon(
                Icons.add,
                color: Colors.black,
                size: 40,
              ),
            ),
          )
        ],
      ),
    );
  }

  Color selectedColor(BuildContext context, bool isSelected) {
    return isSelected ? Colors.black : Colors.white;
  }

  popUpDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 122, 129, 148),
          title: const Text(
            'Create a group',
            textAlign: TextAlign.left,
            style: TextStyle(color: Color.fromARGB(255, 27, 32, 45)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : TextField(
                      onChanged: (val) {
                        setState(() {
                          groupName = val;
                        });
                      },
                      style: const TextStyle(
                          color: Color.fromARGB(255, 27, 32, 45)),
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.black,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.red,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 27, 32, 45),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromARGB(255, 27, 32, 45)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (groupName.trim() != "") {
                  setState(() {
                    _isLoading = true;
                  });
                  createGroup(username, user!.uid, groupName).whenComplete(() {
                    _isLoading = false;
                  });
                  Navigator.of(context).pop();
                  final snackBar = const SnackBar(
                    elevation: 0,
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.transparent,
                    content: AwesomeSnackbarContent(
                      color: Color.fromARGB(255, 3, 116, 6),
                      title: 'Congratulations!',
                      message: 'Group created successfully!',
                      contentType: ContentType.success,
                    ),
                  );

                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(snackBar);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 27, 32, 45),
              ),
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        );
      },
    );
  }

  groupList() {
    return StreamBuilder(
      stream: groups,
      builder: (context, AsyncSnapshot snapshot) {
        if (_isLoading) {
          return const Center(
            child: SpinKitWaveSpinner(
              waveColor: Color.fromARGB(255, 97, 166, 223),
              color: Color.fromARGB(255, 66, 149, 216),
              size: 80, // Adjust the size as needed
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitWaveSpinner(
              waveColor: Color.fromARGB(255, 97, 166, 223),
              color: Color.fromARGB(255, 66, 149, 216),
              size: 80.0, // Adjust the size as needed
            ),
          );
        }

        if (snapshot.hasData) {
          if (snapshot.data['groups'] != null) {
            if (snapshot.data['groups'].length != 0) {
              return Container(
                margin: const EdgeInsets.only(top: 30),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                  color: Color.fromARGB(255, 41, 47, 63),
                ),
                child: ListView.builder(
                  itemCount: snapshot.data['groups'].length,
                  itemBuilder: (context, index) {
                    int reverseIndex =
                        snapshot.data['groups'].length - index - 1;
                    String groupId = snapshot.data['groups'][reverseIndex];

                    return FutureBuilder(
                      future: Future.wait([
                        getLastMessage(groupId),
                        getLastMessageSender(groupId),
                        getLastMessageTime(groupId),
                        getGroupNames(groupId),
                        getGroupImages(groupId),
                      ]),
                      builder: (context,
                          AsyncSnapshot<List<String>> futureSnapshot) {
                        if (futureSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center();
                        }
                        if (futureSnapshot.hasError) {
                          return const Center(
                            child: Text("Error loading messages"),
                          );
                        }

                        String lastMessage = futureSnapshot.data![0];
                        String lastMessageSender = futureSnapshot.data![1];
                        String lastMessageTime = futureSnapshot.data![2];
                        String groupName = futureSnapshot.data![3];
                        String groupImage = futureSnapshot.data![4];

                        return GroupTile(
                          groupId: groupId,
                          groupName: groupName,
                          userName: username,
                          lastMessage: lastMessage,
                          lastMessageSender: lastMessageSender,
                          lastMessageTime: lastMessageTime,
                          groupImage: groupImage,
                        );
                      },
                    );
                  },
                ),
              );
            } else {
              return noGroupWidget();
            }
          } else {
            return noGroupWidget();
          }
        } else {
          return const Center(
            child: SpinKitWaveSpinner(
              waveColor: Color.fromARGB(255, 97, 166, 223),
              color: Color.fromARGB(255, 66, 149, 216),
              size: 80, // Adjust the size as needed
            ),
          );
        }
      },
    );
  }

  noGroupWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              popUpDialog(context);
            },
            icon: const Icon(
              Icons.add_circle,
              size: 75,
            ),
            color: Colors.grey[500],
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            'You have not joined any group yet, tap on add icon to create a group or search from top search button',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// Route _createRoute() {
//   return PageRouteBuilder(
//     pageBuilder: (context, animation, secondaryAnimation) =>
//         const ProfileScreen(),
//     transitionsBuilder: (context, animation, secondaryAnimation, child) {
//       const begin = Offset(1.0, 0.0);
//       const end = Offset.zero;
//       const curve = Curves.ease;

//       var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

//       return SlideTransition(
//         position: animation.drive(tween),
//         child: child,
//       );
//     },
//   );
// }
