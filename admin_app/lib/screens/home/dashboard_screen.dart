import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('orders').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allOrders = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'totalAmount': (data['totalAmount'] ?? 0).toDouble(),
                    'weight': (data['weight'] ?? 0).toDouble(),
                    'fishGST': (data['fishGST'] ?? 0).toDouble(),
                    'deliveryGST': (data['deliveryGST'] ?? 0).toDouble(),
                    'orderStatus': data['orderStatus'] ?? '',
                    'paymentStatus': data['paymentStatus'] ?? '',
                    'paymentMethod': data['paymentMethod'] ?? '',
                    'createdAt': (data['createdAt'] as Timestamp).toDate(),
                  };
                }).toList();

                final todayOrders = allOrders.where((order) {
                  return DateFormat('yyyy-MM-dd').format(order['createdAt'] as DateTime) == today;
                }).toList();

                final totalSales = todayOrders
                    .where((o) => o['orderStatus'] != 'cancelled')
                    .fold<double>(0, (total, order) => total + (order['totalAmount'] as double));

                final totalFishKg = todayOrders
                    .where((o) => o['orderStatus'] != 'cancelled')
                    .fold<double>(0, (total, order) => total + (order['weight'] as double));

                final totalGST = todayOrders
                    .where((o) => o['orderStatus'] != 'cancelled')
                    .fold<double>(0, (total, order) => 
                        total + (order['fishGST'] as double) + (order['deliveryGST'] as double));

                final paidOrders = todayOrders.where((o) => o['paymentStatus'] == 'paid').length;
                final codOrders = todayOrders.where((o) => 
                    o['paymentMethod'] == 'cod' && o['orderStatus'] != 'cancelled').length;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Sales',
                            value: '₹${totalSales.toStringAsFixed(2)}',
                            icon: Icons.currency_rupee,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
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
                          child: _StatCard(
                            title: 'Total GST',
                            value: '₹${totalGST.toStringAsFixed(2)}',
                            icon: Icons.receipt,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Total Orders',
                            value: '${todayOrders.length}',
                            icon: Icons.shopping_cart,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Paid Orders',
                            value: '$paidOrders',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'COD Orders',
                            value: '$codOrders',
                            icon: Icons.money,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'All-Time Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').where('role', isEqualTo: 'merchant').snapshots(),
              builder: (context, snapshot) {
                final merchantCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _StatCard(
                  title: 'Total Merchants',
                  value: '$merchantCount',
                  icon: Icons.store,
                  color: Colors.indigo,
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').where('role', isEqualTo: 'client').snapshots(),
              builder: (context, snapshot) {
                final clientCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _StatCard(
                  title: 'Total Clients',
                  value: '$clientCount',
                  icon: Icons.people,
                  color: Colors.cyan,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
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
