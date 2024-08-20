import 'dart:io';

import 'package:chatter_box/screens/home.dart';
import 'package:chatter_box/screens/image_preview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _groupnameController = TextEditingController();
  String grupnewName = "";
  File? _selectedGroupImage;
  String groupImage = "";
  String adminname = "";

  @override
  void initState() {
    super.initState();
    getMembers();
    fetchUserData();
    fetchGroupData();
    fetchAdminName();
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

  Future<void> fetchAdminName() async {
    String name =
        await getAdminName(widget.adminName); // Pass the admin ID here
    setState(() {
      adminname = name; // Update the state with the admin name
    });
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

  Future<String> getAdminName(String id) async {
    Map<String, dynamic>? userData = await getUserData(id);
    if (userData != null) {
      return userData['user_name'] as String;
    }
    return "";
  }

  Future<Map<String, dynamic>?> getGropData(String groupid) async {
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupid)
        .get();

    if (groupDoc.exists) {
      return groupDoc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  void fetchGroupData() async {
    Map<String, dynamic>? groupData = await getGropData(widget.groupId);
    if (groupData != null) {
      setState(() {
        groupImage = groupData['groupIcon'] ?? "";
      });
    }
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
    bool isAdmin = groupdocumentSnapshot['admin'] == user!.uid;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      if (groups.contains(groupId)) {
        if (isAdmin) {
          // Assign a new admin if the current user is the admin
          if (members.length > 1) {
            String newAdmin =
                members.firstWhere((member) => member != user!.uid);
            transaction.update(groupDocumentReference, {'admin': newAdmin});
          } else {
            transaction.update(groupDocumentReference, {'admin': null});
          }
        }
        transaction.update(userDocumentReference, {
          'groups': FieldValue.arrayRemove([groupId]),
        });
        transaction.update(groupDocumentReference, {
          'members': FieldValue.arrayRemove([(user!.uid)]),
        });
      }
    });
  }

  void _saveGroupName() async {
    if (_groupnameController.text.isNotEmpty &&
        _groupnameController.text != "") {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'groupName': _groupnameController.text,
      });

      setState(() {
        fetchGroupData();
      });
    }
  }

  void _imagePicker(String type) async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedImage;

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

    if (pickedImage == null) {
      return;
    }

    // Navigate to the image preview screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(
          imageFile: File(pickedImage!.path),
          onSend: () async {
            Navigator.of(context).pop();
            try {
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('group_images')
                  .child('${widget.groupId}.jpg');

              // Upload the image file
              await storageRef.putFile(File(pickedImage!.path));

              // Retrieve the image URL
              groupImage = await storageRef.getDownloadURL();

              setState(() {
                _selectedGroupImage = File(pickedImage!.path);
              });
              _saveGroupIcon();
            } catch (e) {
              // Handle any errors that occur during upload
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to upload image. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _saveGroupIcon() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      if (_selectedGroupImage != null) {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
          'groupIcon': groupImage,
        });

        setState(() {
          fetchGroupData();
        });

        Navigator.of(context).pop(); // Close the progress indicator dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group icon updated successfully')),
        );
      } else {
        Navigator.of(context).pop(); // Close the progress indicator dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
      }
    } catch (error) {
      Navigator.of(context).pop(); // Close the progress indicator dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update group icon: $error')),
      );
    }
  }

  void _editPhotoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
            color: Color.fromARGB(255, 27, 32, 45),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28), topRight: Radius.circular(28))),
        height: 250,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Group Icon",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 26,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 5,
                        ),
                        CircleAvatar(
                          radius: 30,
                          backgroundColor:
                              const Color.fromARGB(255, 122, 129, 148),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 30,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              Navigator.pop(context); // Close the bottom sheet
                              _imagePicker('Camera');
                            },
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Camera',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 5,
                        ),
                        CircleAvatar(
                          radius: 30,
                          backgroundColor:
                              const Color.fromARGB(255, 122, 129, 148),
                          child: IconButton(
                            icon: const Icon(
                              Icons.photo,
                              size: 30,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              Navigator.pop(context); // Close the bottom sheet
                              _imagePicker('Gallery');
                            },
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Gallery',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editNameSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 41, 47, 63),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enter group name",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20),
                ),
                const SizedBox(
                  height: 8,
                ),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _groupnameController,
                    decoration: InputDecoration(
                      labelText: 'GroupName',
                      labelStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _groupnameController.clear();
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 18),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _saveGroupName();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 32, 45),
      appBar: AppBar(
        bottomOpacity: 0.2,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 27, 32, 45),
        title: Text(
          widget.groupName,
          style: const TextStyle(
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color.fromARGB(255, 41, 47, 63),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Hero(
                    tag: widget.groupId,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor:
                              const Color.fromARGB(255, 27, 32, 45),
                          foregroundImage: groupImage.isNotEmpty
                              ? NetworkImage(groupImage)
                              : null,
                          child: groupImage.isEmpty
                              ? const Icon(Icons.group,
                                  size: 70, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.black,
                              ),
                              onPressed: _editPhotoSheet,
                              iconSize: 27,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.groupName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontSize: 20),
                      ),
                      // const SizedBox(width: 5,),
                      IconButton(
                        onPressed: _editNameSheet,
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    'Admin : $adminname',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17,
                        color: Color.fromARGB(255, 179, 185, 201)),
                  ),
                ],
              ),
            ),
            const Divider(
              color: Colors.white,
              thickness: 2,
              height: 30,
            ),
            const Text(
              'Members',
              textAlign: TextAlign.left,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 18),
            ),
            const SizedBox(
              height: 10,
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

  Future<String> getMemberName(String userId) async {
    Map<String, dynamic>? memberData = await getUserData(userId);
    if (memberData != null) {
      return memberData['user_name'] as String;
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
              child: ListView.builder(
                itemCount: membersList.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  String memberId = membersList[index];

                  return FutureBuilder(
                    future: Future.wait([
                      getMemberImage(memberId),
                      getMemberName(memberId),
                    ]),
                    builder:
                        (context, AsyncSnapshot<List<String>> futureSnapshot) {
                      if (futureSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return ListTile(
                          leading: const CircleAvatar(
                            radius: 30,
                            backgroundColor: Color.fromARGB(255, 27, 32, 45),
                            child: CircularProgressIndicator(),
                          ),
                          title: const Text(
                            'Loading...',
                            style: TextStyle(
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
                      } else if (futureSnapshot.hasData &&
                          futureSnapshot.data!.length == 2) {
                        final imageUrl = futureSnapshot.data![0];
                        final memberName = futureSnapshot.data![1];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                const Color.fromARGB(255, 27, 32, 45),
                            foregroundImage: imageUrl != null
                                ? NetworkImage(imageUrl)
                                : null,
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
                        return const ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor: Color.fromARGB(255, 27, 32, 45),
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                          title: Text(
                            'Error loading member data',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
