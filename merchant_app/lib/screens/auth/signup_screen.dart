import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _machineIdController = TextEditingController();
  final _authService = AuthService();
  
  bool _codeSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _shopNameController.dispose();
    _machineIdController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final shopName = _shopNameController.text.trim();

    if (phone.isEmpty || name.isEmpty || shopName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final fullPhone = phone.startsWith('+91') ? phone : '+91$phone';

    final exists = await _authService.checkPhoneNumberExists(fullPhone);
    if (exists) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number already registered. Please login.')),
      );
      return;
    }

    await _authService.verifyPhoneNumber(
      phoneNumber: fullPhone,
      codeSent: (verificationId) {
        setState(() {
          _codeSent = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully')),
        );
      },
      verificationFailed: (error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $error')),
        );
      },
      codeSentTimeout: () {
        setState(() => _isLoading = false);
      },
    );
  }

  Future<void> _verifyOTPAndSignup() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyOTP(otp);
      
      final fullPhone = _phoneController.text.trim().startsWith('+91')
          ? _phoneController.text.trim()
          : '+91${_phoneController.text.trim()}';

      await _authService.createUser(
        phoneNumber: fullPhone,
        name: _nameController.text.trim(),
        shopName: _shopNameController.text.trim(),
        machineId: _machineIdController.text.trim().isNotEmpty
            ? _machineIdController.text.trim()
            : null,
      );

      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Signup'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.store, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Create Merchant Account',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _nameController,
              enabled: !_codeSent,
              decoration: const InputDecoration(
                labelText: 'Your Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _shopNameController,
              enabled: !_codeSent,
              decoration: const InputDecoration(
                labelText: 'Shop Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_codeSent,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixText: '+91 ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _machineIdController,
              enabled: !_codeSent,
              decoration: const InputDecoration(
                labelText: 'Machine ID (Optional)',
                border: OutlineInputBorder(),
                helperText: 'Can be added later',
              ),
            ),
            
            if (_codeSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : (_codeSent ? _verifyOTPAndSignup : _sendOTP),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _codeSent ? 'Verify & Create Account' : 'Send OTP',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            
            if (_codeSent)
              TextButton(
                onPressed: () {
                  setState(() {
                    _codeSent = false;
                    _otpController.clear();
                  });
                },
                child: const Text('Change Phone Number'),
              ),
          ],
        ),
      ),
    );
  }
}
