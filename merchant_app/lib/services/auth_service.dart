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

  // Email/Password Sign In
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    }
  }

  // Email/Password Sign Up
  Future<User?> signUpWithEmailPassword(
    String email,
    String password,
    String name,
    String phone,
    String shopName,
  ) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Create user document in Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'name': name,
          'phoneNumber': phone,
          'shopName': shopName,
          'role': 'merchant',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'Login failed. Please try again';
    }
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
