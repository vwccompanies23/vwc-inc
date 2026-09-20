import 'package:flutter/material.dart';
import 'package:vwc_app/features/home/home_screen.dart';
import 'package:vwc_app/features/admin/admin_dashboard_screen.dart';

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  final TextEditingController _pinController = TextEditingController();

  // Defined Access Codes
  static const String _workerPin = "2019";
  static const String _adminPin = "2026"; // Your private secret code

  void _verifyPin() {
    final enteredPin = _pinController.text.trim();

    if (enteredPin == _adminPin) {
      // Secret Admin Access -> Opens Admin Dashboard directly
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else if (enteredPin == _workerPin) {
      // Standard Employee Access -> Opens Employee Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Access Code! Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'VWC Internal Portal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your assigned access code to continue',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, letterSpacing: 16),
                decoration: const InputDecoration(
                  hintText: '****',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onSubmitted: (_) => _verifyPin(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _verifyPin,
                  child: const Text(
                    'ENTER APP',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}