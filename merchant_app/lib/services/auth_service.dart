import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String? _verificationId;

  Future<bool> checkPhoneNumberExists(String phoneNumber) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) codeSent,
    required Function(String) verificationFailed,
    required Function() codeSentTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        verificationFailed(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        codeSentTimeout();
      },
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential?> verifyOTP(String otp) async {
    if (_verificationId == null) {
      throw Exception('Verification ID is null');
    }

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<UserModel?> createUser({
    required String phoneNumber,
    required String name,
    required String shopName,
    String? machineId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final exists = await checkPhoneNumberExists(phoneNumber);
    if (exists) {
      throw Exception('Phone number already registered');
    }

    final userData = {
      'phoneNumber': phoneNumber,
      'role': 'merchant',
      'name': name,
      'shopName': shopName,
      'machineId': machineId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(user.uid).set(userData);

    return UserModel(
      id: user.uid,
      phoneNumber: phoneNumber,
      role: 'merchant',
      name: name,
      shopName: shopName,
      machineId: machineId,
      createdAt: DateTime.now(),
    );
  }

  Future<UserModel?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateMachineId(String machineId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'machineId': machineId,
    });
  }
}
