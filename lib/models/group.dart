import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String admin;
  
  Group({required this.id, required this.name, required this. admin});

  factory Group.fromDocument(DocumentSnapshot doc) {
    return Group(
      id: doc.id,
      name: doc['groupname'], 
      admin: doc['admin'],
    );
  }
}
