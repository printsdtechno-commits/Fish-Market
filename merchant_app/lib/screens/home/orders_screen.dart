import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _filterStatus == 'all',
                          onSelected: () => setState(() => _filterStatus = 'all'),
                        ),
                        _FilterChip(
                          label: 'Active',
                          selected: _filterStatus == 'active',
                          onSelected: () => setState(() => _filterStatus = 'active'),
                        ),
                        _FilterChip(
                          label: 'Paid',
                          selected: _filterStatus == 'paid',
                          onSelected: () => setState(() => _filterStatus = 'paid'),
                        ),
                        _FilterChip(
                          label: 'COD',
                          selected: _filterStatus == 'cod',
                          onSelected: () => setState(() => _filterStatus = 'cod'),
                        ),
                        _FilterChip(
                          label: 'Cancelled',
                          selected: _filterStatus == 'cancelled',
                          onSelected: () => setState(() => _filterStatus = 'cancelled'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: userId == null
                ? const Center(child: Text('Please login'))
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('orders')
                        .where('merchantId', isEqualTo: userId)
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
                              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No orders yet'),
                            ],
                          ),
                        );
                      }

                      var orders = snapshot.data!.docs
                          .map((doc) => OrderModel.fromFirestore(doc))
                          .toList();

                      if (_filterStatus == 'active') {
                        orders = orders.where((o) => o.orderStatus == 'active').toList();
                      } else if (_filterStatus == 'paid') {
                        orders = orders.where((o) => o.paymentStatus == 'paid').toList();
                      } else if (_filterStatus == 'cod') {
                        orders = orders.where((o) => o.paymentMethod == 'cod' && o.orderStatus != 'cancelled').toList();
                      } else if (_filterStatus == 'cancelled') {
                        orders = orders.where((o) => o.orderStatus == 'cancelled').toList();
                      }

                      if (orders.isEmpty) {
                        return const Center(
                          child: Text('No orders found'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _OrderCard(order: order);
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
        selectedColor: Colors.blue,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  Color _getStatusColor() {
    if (order.orderStatus == 'cancelled') return Colors.red;
    if (order.paymentStatus == 'paid') return Colors.green;
    if (order.paymentMethod == 'cod') return Colors.orange;
    return Colors.blue;
  }

  String _getStatusText() {
    if (order.orderStatus == 'cancelled') return 'Cancelled';
    if (order.paymentStatus == 'paid') return 'Paid';
    if (order.paymentMethod == 'cod') return 'COD';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image_not_supported),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.fishName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Weight: ${order.weight.toStringAsFixed(2)} kg'),
                      Text('Rate: ₹${order.ratePerKg.toStringAsFixed(2)}/kg'),
                      Text('Type: ${order.type}'),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fish Amount:'),
                Text('₹${order.fishAmount.toStringAsFixed(2)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fish GST (5%):'),
                Text('₹${order.fishGST.toStringAsFixed(2)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Charge:'),
                Text('₹${order.deliveryCharge.toStringAsFixed(2)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery GST (18%):'),
                Text('₹${order.deliveryGST.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (order.orderStatus == 'cancelled' && order.cancellationReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${order.cancellationReason}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
