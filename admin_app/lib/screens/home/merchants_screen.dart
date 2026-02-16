import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class MerchantsScreen extends StatelessWidget {
  const MerchantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('users').where('role', isEqualTo: 'merchant').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No merchants registered'),
              ],
            ),
          );
        }

        final merchants = snapshot.data!.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: merchants.length,
          itemBuilder: (context, index) {
            final merchant = merchants[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.store),
                ),
                title: Text(
                  merchant.shopName ?? merchant.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Owner: ${merchant.name}'),
                    Text('Phone: ${merchant.phoneNumber}'),
                    if (merchant.machineId != null)
                      Text('Machine: ${merchant.machineId}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.analytics),
                  onPressed: () {
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
