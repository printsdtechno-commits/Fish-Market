import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  
  double _currentWeight = 0.0;
  String? _machineId;

  @override
  void initState() {
    super.initState();
    _loadMachineData();
  }

  Future<void> _loadMachineData() async {
    final userData = await _authService.getUserData();
    if (userData?.machineId != null) {
      setState(() => _machineId = userData!.machineId);
      _subscribeToWeightUpdates();
    }
  }

  void _subscribeToWeightUpdates() {
    if (_machineId == null) return;
    
    _firestore
        .collection('weighing_machines')
        .doc(_machineId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        setState(() {
          _currentWeight = (data?['currentWeight'] ?? 0).toDouble();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userId = _authService.currentUser?.uid;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadMachineData();
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Current Weight',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_currentWeight.toStringAsFixed(2)} kg',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    if (_machineId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Machine: $_machineId',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Today\'s Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<QuerySnapshot>(
              stream: userId != null
                  ? _firestore
                      .collection('orders')
                      .where('merchantId', isEqualTo: userId)
                      .where('createdAt', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 1)))
                      .snapshots()
                  : null,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!.docs
                    .map((doc) => OrderModel.fromFirestore(doc))
                    .where((order) => DateFormat('yyyy-MM-dd').format(order.createdAt) == today)
                    .toList();

                final totalSales = orders
                    .where((o) => o.orderStatus != 'cancelled')
                    .fold<double>(0, (total, order) => total + order.totalAmount);
                
                final totalFishKg = orders
                    .where((o) => o.orderStatus != 'cancelled')
                    .fold<double>(0, (total, order) => total + order.weight);
                
                final paidOrders = orders.where((o) => o.paymentStatus == 'paid').length;
                final codOrders = orders.where((o) => o.paymentMethod == 'cod' && o.orderStatus != 'cancelled').length;
                final cancelledOrders = orders.where((o) => o.orderStatus == 'cancelled').length;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Sales',
                            value: '₹${totalSales.toStringAsFixed(2)}',
                            icon: Icons.currency_rupee,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Fish Sold',
                            value: '${totalFishKg.toStringAsFixed(1)} kg',
                            icon: Icons.scale,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Paid',
                            value: '$paidOrders',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'COD',
                            value: '$codOrders',
                            icon: Icons.money,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Cancelled',
                            value: '$cancelledOrders',
                            icon: Icons.cancel,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
