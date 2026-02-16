import 'package:cloud_firestore/cloud_firestore.dart';

class FishInventoryModel {
  final String id;
  final String merchantId;
  final String fishName;
  final String imageUrl;
  final double ratePerKg;
  final String type;
  final String date;
  final DateTime createdAt;
  final DateTime updatedAt;

  FishInventoryModel({
    required this.id,
    required this.merchantId,
    required this.fishName,
    required this.imageUrl,
    required this.ratePerKg,
    required this.type,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FishInventoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FishInventoryModel(
      id: doc.id,
      merchantId: data['merchantId'] ?? '',
      fishName: data['fishName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      ratePerKg: (data['ratePerKg'] ?? 0).toDouble(),
      type: data['type'] ?? 'retail',
      date: data['date'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'fishName': fishName,
      'imageUrl': imageUrl,
      'ratePerKg': ratePerKg,
      'type': type,
      'date': date,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
