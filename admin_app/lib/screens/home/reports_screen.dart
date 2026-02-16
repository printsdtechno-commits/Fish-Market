import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _period = 'daily';
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              const Text('Period: '),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'daily', label: Text('Daily')),
                    ButtonSegment(value: 'monthly', label: Text('Monthly')),
                    ButtonSegment(value: 'yearly', label: Text('Yearly')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => _period = newSelection.first);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Text(
                  _getPeriodLabel(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
            ],
          ),
          
          const Divider(height: 32),
          
          Expanded(
            child: _buildReportView(),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF export will be implemented')),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CSV export will be implemented')),
                    );
                  },
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_period) {
      case 'daily':
        return DateFormat('dd MMMM yyyy').format(_selectedDate);
      case 'monthly':
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case 'yearly':
        return DateFormat('yyyy').format(_selectedDate);
      default:
        return '';
    }
  }

  Widget _buildReportView() {
    return StreamBuilder<QuerySnapshot>(
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
            'deliveryCharge': (data['deliveryCharge'] ?? 0).toDouble(),
            'orderStatus': data['orderStatus'] ?? '',
            'paymentStatus': data['paymentStatus'] ?? '',
            'createdAt': (data['createdAt'] as Timestamp).toDate(),
            'fishName': data['fishName'] ?? '',
          };
        }).toList();

        final filteredOrders = allOrders.where((order) {
          final orderDate = order['createdAt'] as DateTime;
          switch (_period) {
            case 'daily':
              return DateFormat('yyyy-MM-dd').format(orderDate) ==
                  DateFormat('yyyy-MM-dd').format(_selectedDate);
            case 'monthly':
              return orderDate.year == _selectedDate.year &&
                  orderDate.month == _selectedDate.month;
            case 'yearly':
              return orderDate.year == _selectedDate.year;
            default:
              return false;
          }
        }).where((o) => o['orderStatus'] != 'cancelled').toList();

        final totalSales = filteredOrders.fold<double>(
            0, (total, order) => total + (order['totalAmount'] as double));
        final totalFishKg = filteredOrders.fold<double>(
            0, (total, order) => total + (order['weight'] as double));
        final totalGST = filteredOrders.fold<double>(0, (total, order) =>
            total + (order['fishGST'] as double) + (order['deliveryGST'] as double));
        final totalDeliveryCharges = filteredOrders.fold<double>(
            0, (total, order) => total + (order['deliveryCharge'] as double));

        return SingleChildScrollView(
          child: Column(
            children: [
              _ReportCard(
                title: 'Total Sales',
                value: '₹${totalSales.toStringAsFixed(2)}',
                icon: Icons.currency_rupee,
                color: Colors.green,
              ),
              _ReportCard(
                title: 'Total Fish Sold',
                value: '${totalFishKg.toStringAsFixed(2)} kg',
                icon: Icons.scale,
                color: Colors.blue,
              ),
              _ReportCard(
                title: 'Total GST Collected',
                value: '₹${totalGST.toStringAsFixed(2)}',
                icon: Icons.receipt,
                color: Colors.orange,
              ),
              _ReportCard(
                title: 'Delivery Charges',
                value: '₹${totalDeliveryCharges.toStringAsFixed(2)}',
                icon: Icons.local_shipping,
                color: Colors.purple,
              ),
              _ReportCard(
                title: 'Total Orders',
                value: '${filteredOrders.length}',
                icon: Icons.shopping_cart,
                color: Colors.teal,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
