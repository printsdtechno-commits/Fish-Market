import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String phoneNumber;
  final String role;
  final String name;
  final String? shopName;
  final String? machineId;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.role,
    required this.name,
    this.shopName,
    this.machineId,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      role: data['role'] ?? '',
      name: data['name'] ?? '',
      shopName: data['shopName'],
      machineId: data['machineId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
