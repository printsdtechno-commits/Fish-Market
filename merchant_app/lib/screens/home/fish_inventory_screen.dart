import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../models/fish_inventory_model.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class FishInventoryScreen extends StatefulWidget {
  const FishInventoryScreen({super.key});

  @override
  State<FishInventoryScreen> createState() => _FishInventoryScreenState();
}

class _FishInventoryScreenState extends State<FishInventoryScreen> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      body: userId == null
          ? const Center(child: Text('Please login'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('fish_inventory')
                  .where('merchantId', isEqualTo: userId)
                  .where('date', isEqualTo: today)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No fish added today'),
                        const SizedBox(height: 8),
                        const Text(
                          'Add fish to your inventory',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final fishList = snapshot.data!.docs
                    .map((doc) => FishInventoryModel.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: fishList.length,
                  itemBuilder: (context, index) {
                    final fish = fishList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: fish.imageUrl.isNotEmpty
                            ? Image.network(
                                fish.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported, size: 60),
                        title: Text(
                          fish.fishName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '₹${fish.ratePerKg}/kg (${fish.type})',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditDialog(fish: fish),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteFish(fish.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddEditDialog({FishInventoryModel? fish}) async {
    final nameController = TextEditingController(text: fish?.fishName ?? '');
    final rateController = TextEditingController(text: fish?.ratePerKg.toString() ?? '');
    String type = fish?.type ?? 'retail';
    String? imageUrl = fish?.imageUrl;
    File? imageFile;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(fish == null ? 'Add Fish' : 'Edit Fish'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageFile != null)
                  Image.file(imageFile!, height: 150, width: 150, fit: BoxFit.cover)
                else if (imageUrl != null && imageUrl.isNotEmpty)
                  Image.network(imageUrl, height: 150, width: 150, fit: BoxFit.cover)
                else
                  Container(
                    height: 150,
                    width: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50),
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setDialogState(() {
                        imageFile = File(pickedFile.path);
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Pick Image'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Fish Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rate per Kg (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'retail', child: Text('Retail')),
                    DropdownMenuItem(value: 'wholesale', child: Text('Wholesale')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => type = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final name = nameController.text.trim();
                final rateStr = rateController.text.trim();

                if (name.isEmpty || rateStr.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                final rate = double.tryParse(rateStr);
                if (rate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid rate')),
                  );
                  return;
                }

                String uploadedImageUrl = imageUrl ?? '';
                if (imageFile != null) {
                  uploadedImageUrl = await _uploadImage(imageFile!);
                }

                await _saveFish(
                  fishId: fish?.id,
                  name: name,
                  rate: rate,
                  type: type,
                  imageUrl: uploadedImageUrl,
                );

                if (!mounted) return;
                navigator.pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _uploadImage(File imageFile) async {
    final userId = _authService.currentUser!.uid;
    final fileName = const Uuid().v4();
    final ref = _storage.ref().child('fish_images/$userId/$fileName.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _saveFish({
    String? fishId,
    required String name,
    required double rate,
    required String type,
    required String imageUrl,
  }) async {
    final userId = _authService.currentUser!.uid;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final data = {
      'merchantId': userId,
      'fishName': name,
      'ratePerKg': rate,
      'type': type,
      'imageUrl': imageUrl,
      'date': today,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (fishId == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('fish_inventory').add(data);
    } else {
      await _firestore.collection('fish_inventory').doc(fishId).update(data);
    }
  }

  Future<void> _deleteFish(String fishId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fish'),
        content: const Text('Are you sure you want to delete this fish?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('fish_inventory').doc(fishId).delete();
    }
  }
}
