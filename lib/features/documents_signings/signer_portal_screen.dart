import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'signer_submission_model.dart'; // Make sure this points to your model file

class SignerPortalScreen extends StatefulWidget {
  final String documentTitle;
  final String companyName;
  final List<PlatformFile> files; // Added so the signer's files travel with the submission

  const SignerPortalScreen({
    super.key,
    required this.documentTitle,
    required this.companyName,
    required this.files,
  });

  @override
  State<SignerPortalScreen> createState() => _SignerPortalScreenState();
}

class _SignerPortalScreenState extends State<SignerPortalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isSigned = false;
  // In a real implementation with a signing package, you'd capture path points.
  // For now, this flag tracks that a signature was drawn and applied.

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _openSignaturePad() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Draw Your Signature'),
        content: SizedBox(
          width: 320,
          height: 220,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Sign Inside This Box\n(Signature Canvas)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E24),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSigned = true;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signature captured successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Apply Signature'),
          ),
        ],
      ),
    );
  }

  void _submitProfileAndFiles() {
    if (_formKey.currentState!.validate() && _isSigned) {
      // 1. Create the submission profile object
      final newSubmission = SignerSubmission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        documentTitle: widget.documentTitle,
        company: widget.companyName,
        submissionDate: DateTime.now(),
        signedFiles: widget.files,
      );

      // 2. Save it to your global/shared submission database
      SubmissionDatabase.submissions.add(newSubmission);

      // 3. Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Submission Complete'),
          content: Text(
            'Thank you, ${_nameController.text}! Your signed documents and profile have been securely saved and sent back to ${widget.companyName}.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E24),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return from signer portal
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign: ${widget.documentTitle}'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.documentTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requested by: ${widget.companyName}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Signer Information Inputs
              const Text(
                '1. Enter Your Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B1E24)),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your email address' : null,
              ),
              const SizedBox(height: 24),

              // Document & Signature Section
              const Text(
                '2. Review & Sign Required Fields',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B1E24)),
              ),
              const SizedBox(height: 10),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 48, color: Color(0xFF8B1E24)),
                      const SizedBox(height: 8),
                      Text('${widget.files.length} File Paper(s) Attached', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _isSigned
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Signature Applied', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      )
                          : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E24),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.edit),
                        label: const Text('Tap Here to Sign Document'),
                        onPressed: _openSignaturePad,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isSigned) ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSigned ? _submitProfileAndFiles : null,
                child: const Text(
                  'Submit Completed Document & Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}