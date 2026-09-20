import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service & Privacy'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8B1E24)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome to VWC App. By using our application, you agree to comply with and be bound by the following terms of use. Please review them carefully.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Worker & ID Verification',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'All employee badges and generated worker IDs within this app are official property of VWC Group. Unauthorized distribution or duplication is strictly prohibited.',
              style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            const Text(
              '2. Contract & Document Signing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Digital signatures submitted through this platform are legally binding agreements under company policy.',
              style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            const Text(
              '3. Privacy Policy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'We respect your privacy. Personal worker data and uploaded documents are stored securely and used solely for internal VWC administrative purposes.',
              style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                '© VWC Group. All rights reserved.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}