import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String? admin;

  Group({
    required this.id,
    required this.name,
    this.admin,
  });

  factory Group.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle null values and provide default values if necessary
    return Group(
      id: doc.id,
      name: data['groupName'] ?? 'Unknown Group', // Provide default value if null
      admin: data['admin'] as String?, // Ensure it's nullable
    );
  }
}
