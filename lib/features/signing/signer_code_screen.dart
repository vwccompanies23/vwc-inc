import 'package:flutter/material.dart';
import 'package:vwc_app/features/signing/sign_contract_screen.dart';

class SignerCodeScreen extends StatefulWidget {
  final String docTitle;
  final String company;
  final List<String> pageUrls;
  final String requiredCode;

  const SignerCodeScreen({
    super.key,
    required this.docTitle,
    required this.company,
    required this.pageUrls,
    required this.requiredCode,
  });

  @override
  State<SignerCodeScreen> createState() => _SignerCodeScreenState();
}

class _SignerCodeScreenState extends State<SignerCodeScreen> {
  final TextEditingController _codeController = TextEditingController();

  void _verifyCode() {
    final enteredCode = _codeController.text.trim();

    if (enteredCode == widget.requiredCode) {
      // Correct code! Navigate directly to the sign contract screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SignContractScreen(
            docTitle: widget.docTitle,
            company: widget.company,
            pageUrls: widget.pageUrls,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect Access Code. Please check with your administrator.'),
          backgroundColor: Colors.red,
        ),
      );
      _codeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Secure Document Access'),
        backgroundColor: const Color(0xFF8B1E24),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline, size: 70, color: Color(0xFF8B1E24)),
              const SizedBox(height: 16),
              Text(
                widget.docTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.company,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              const Text(
                'Please enter the 4-digit unique access code provided to you to view and sign this document.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 12),
                decoration: const InputDecoration(
                  hintText: '****',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onSubmitted: (_) => _verifyCode(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E24),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _verifyCode,
                  child: const Text(
                    'UNLOCK DOCUMENT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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