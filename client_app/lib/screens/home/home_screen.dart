import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import 'package:intl/intl.dart';
import 'order_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  String _filter = 'active';

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Filter: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Active',
                          selected: _filter == 'active',
                          onSelected: () => setState(() => _filter = 'active'),
                        ),
                        _FilterChip(
                          label: 'Paid',
                          selected: _filter == 'paid',
                          onSelected: () => setState(() => _filter = 'paid'),
                        ),
                        _FilterChip(
                          label: 'Pending',
                          selected: _filter == 'pending',
                          onSelected: () => setState(() => _filter = 'pending'),
                        ),
                        _FilterChip(
                          label: 'Cancelled',
                          selected: _filter == 'cancelled',
                          onSelected: () =>
                              setState(() => _filter = 'cancelled'),
                        ),
                        _FilterChip(
                          label: 'All',
                          selected: _filter == 'all',
                          onSelected: () => setState(() => _filter = 'all'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('orders')
                  .where('clientId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('No orders yet'),
                      ],
                    ),
                  );
                }

                var orders = snapshot.data!.docs
                    .map((doc) => OrderModel.fromFirestore(doc))
                    .toList();

                if (_filter == 'active') {
                  orders = orders
                      .where((o) => o.orderStatus == 'active')
                      .toList();
                } else if (_filter == 'paid') {
                  orders = orders
                      .where((o) => o.paymentStatus == 'paid')
                      .toList();
                } else if (_filter == 'pending') {
                  orders = orders
                      .where(
                        (o) =>
                            o.paymentStatus == 'pending' &&
                            o.orderStatus != 'cancelled',
                      )
                      .toList();
                } else if (_filter == 'cancelled') {
                  orders = orders
                      .where((o) => o.orderStatus == 'cancelled')
                      .toList();
                }

                if (orders.isEmpty) {
                  return const Center(child: Text('No orders found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _OrderCard(
                      order: order,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: order),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: Colors.teal,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  Color _getStatusColor() {
    if (order.orderStatus == 'cancelled') return Colors.red;
    if (order.paymentStatus == 'paid') return Colors.green;
    return Colors.orange;
  }

  String _getStatusText() {
    if (order.orderStatus == 'cancelled') return 'Cancelled';
    if (order.paymentStatus == 'paid') return 'Paid';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice: ${order.invoiceNumber}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (order.fishImageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order.fishImageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image_not_supported),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.fishName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.weight.toStringAsFixed(2)} kg × ₹${order.ratePerKg.toStringAsFixed(2)}',
                        ),
                        Text(
                          DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(order.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
