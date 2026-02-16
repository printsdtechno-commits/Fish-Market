import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/order_model.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await _firestore.collection('orders').doc(widget.order.id).update({
      'paymentStatus': 'paid',
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment successful!'), backgroundColor: Colors.green),
    );
    
    Navigator.pop(context);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}'), backgroundColor: Colors.red),
    );
    setState(() => _isProcessing = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  Future<void> _initiatePayment(String method) async {
    setState(() => _isProcessing = true);

    if (method == 'razorpay') {
      var options = {
        'key': 'YOUR_RAZORPAY_KEY',
        'amount': (widget.order.totalAmount * 100).toInt(),
        'name': 'Fish Shop',
        'description': 'Order #${widget.order.invoiceNumber}',
        'prefill': {
          'contact': '',
          'email': ''
        }
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isProcessing = false);
      }
    } else if (method == 'cod') {
      await _firestore.collection('orders').doc(widget.order.id).update({
        'paymentMethod': 'cod',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      setState(() => _isProcessing = false);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order confirmed with Cash on Delivery')),
      );
    }
  }

  Future<void> _cancelOrder() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.collection('orders').doc(widget.order.id).update({
        'orderStatus': 'cancelled',
        'cancellationReason': reasonController.text.trim().isEmpty 
            ? 'Not specified' 
            : reasonController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled'), backgroundColor: Colors.red),
      );
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('orders').doc(widget.order.id).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = OrderModel.fromFirestore(snapshot.data!);

          return SingleChildScrollView(
            child: Column(
              children: [
                if (order.fishImageUrl.isNotEmpty)
                  Image.network(
                    order.fishImageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 80),
                  ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.fishName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _StatusBadge(
                            status: order.orderStatus == 'cancelled' 
                                ? 'Cancelled' 
                                : order.paymentStatus == 'paid' 
                                    ? 'Paid' 
                                    : 'Pending',
                            color: order.orderStatus == 'cancelled'
                                ? Colors.red
                                : order.paymentStatus == 'paid'
                                    ? Colors.green
                                    : Colors.orange,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      Text(
                        'Invoice: ${order.invoiceNumber}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      
                      const Divider(height: 32),
                      
                      _DetailRow('Weight', '${order.weight.toStringAsFixed(2)} kg'),
                      _DetailRow('Rate per kg', '₹${order.ratePerKg.toStringAsFixed(2)}'),
                      _DetailRow('Type', order.type),
                      
                      const Divider(height: 32),
                      
                      const Text(
                        'Price Breakdown',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      _DetailRow('Fish Amount', '₹${order.fishAmount.toStringAsFixed(2)}'),
                      _DetailRow('Fish GST (5%)', '₹${order.fishGST.toStringAsFixed(2)}'),
                      _DetailRow('Delivery Charge', '₹${order.deliveryCharge.toStringAsFixed(2)}'),
                      _DetailRow('Delivery GST (18%)', '₹${order.deliveryGST.toStringAsFixed(2)}'),
                      
                      const Divider(height: 24),
                      
                      _DetailRow(
                        'Total Amount',
                        '₹${order.totalAmount.toStringAsFixed(2)}',
                        bold: true,
                        valueColor: Colors.green,
                      ),
                      
                      const Divider(height: 32),
                      
                      _DetailRow('Payment Method', order.paymentMethod.toUpperCase()),
                      _DetailRow(
                        'Order Date',
                        DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                      ),
                      
                      if (order.orderStatus == 'cancelled' && order.cancellationReason != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cancellation Reason',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    Text(order.cancellationReason!),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      if (order.orderStatus != 'cancelled' && order.paymentStatus != 'paid') ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Payment Options',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        
                        _PaymentButton(
                          label: 'Pay with UPI / Cards / Banking',
                          icon: Icons.payment,
                          onPressed: _isProcessing ? null : () => _initiatePayment('razorpay'),
                          color: Colors.blue,
                        ),
                        
                        _PaymentButton(
                          label: 'Cash on Delivery',
                          icon: Icons.money,
                          onPressed: _isProcessing ? null : () => _initiatePayment('cod'),
                          color: Colors.orange,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        ElevatedButton(
                          onPressed: order.orderStatus == 'cancelled' ? null : _cancelOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'Cancel Order',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _DetailRow(
    this.label,
    this.value, {
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 18 : 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _PaymentButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }
}
