import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String phoneNumber;
  final String role;
  final String name;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.role,
    required this.name,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      role: data['role'] ?? '',
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'role': role,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
