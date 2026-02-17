import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to track value changes in order fields
class ValueChange<T> {
  final T originalValue;
  T _currentValue;

  ValueChange(this.originalValue) : _currentValue = originalValue;

  T get value => _currentValue;

  bool get hasChanged => originalValue != _currentValue;

  void update(T newValue) {
    if (newValue != originalValue) {
      _currentValue = newValue;
    }
  }

  void reset() {
    _currentValue = originalValue;
  }
}

class OrderModel {
  final String id;
  final String merchantId;
  final String clientId;
  final String fishName;
  final String fishImageUrl;
  final double weight;
  final double ratePerKg;
  final String type;

  final double fishAmount;
  final double fishGST;
  final double deliveryCharge;
  final double deliveryGST;
  final double totalAmount;

  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String? cancellationReason;

  final String invoiceNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  OrderModel({
    required this.id,
    required this.merchantId,
    required this.clientId,
    required this.fishName,
    required this.fishImageUrl,
    required this.weight,
    required this.ratePerKg,
    required this.type,
    required this.fishAmount,
    required this.fishGST,
    required this.deliveryCharge,
    required this.deliveryGST,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    this.cancellationReason,
    required this.invoiceNumber,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      merchantId: data['merchantId'] ?? '',
      clientId: data['clientId'] ?? '',
      fishName: data['fishName'] ?? '',
      fishImageUrl: data['fishImageUrl'] ?? '',
      weight: (data['weight'] ?? 0).toDouble(),
      ratePerKg: (data['ratePerKg'] ?? 0).toDouble(),
      type: data['type'] ?? 'retail',
      fishAmount: (data['fishAmount'] ?? 0).toDouble(),
      fishGST: (data['fishGST'] ?? 0).toDouble(),
      deliveryCharge: (data['deliveryCharge'] ?? 35).toDouble(),
      deliveryGST: (data['deliveryGST'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'cod',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      orderStatus: data['orderStatus'] ?? 'active',
      cancellationReason: data['cancellationReason'],
      invoiceNumber: data['invoiceNumber'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'clientId': clientId,
      'fishName': fishName,
      'fishImageUrl': fishImageUrl,
      'weight': weight,
      'ratePerKg': ratePerKg,
      'type': type,
      'fishAmount': fishAmount,
      'fishGST': fishGST,
      'deliveryCharge': deliveryCharge,
      'deliveryGST': deliveryGST,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'cancellationReason': cancellationReason,
      'invoiceNumber': invoiceNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  static double calculateFishAmount(double weight, double ratePerKg) {
    return weight * ratePerKg;
  }

  static double calculateFishGST(double fishAmount) {
    return fishAmount * 0.05;
  }

  static double calculateDeliveryGST(double deliveryCharge) {
    return deliveryCharge * 0.18;
  }

  static double calculateTotal(
    double fishAmount,
    double fishGST,
    double deliveryCharge,
    double deliveryGST,
  ) {
    return fishAmount + fishGST + deliveryCharge + deliveryGST;
  }
}
