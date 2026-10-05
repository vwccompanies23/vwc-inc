import 'package:flutter/material.dart';
import 'signer_submission_model.dart';
import 'signer_detail_screen.dart';

class AdminSubmissionsScreen extends StatefulWidget {
  const AdminSubmissionsScreen({super.key});

  @override
  State<AdminSubmissionsScreen> createState() => _AdminSubmissionsScreenState();
}

class _AdminSubmissionsScreenState extends State<AdminSubmissionsScreen> {
  @override
  Widget build(BuildContext context) {
    final submissions = SubmissionDatabase.submissions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signed Submissions'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: submissions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No completed submissions yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Profiles will appear here once signers submit their papers.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: submissions.length,
        itemBuilder: (context, index) {
          final sub = submissions[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF8B1E24),
                child: Text(
                  sub.fullName.isNotEmpty ? sub.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                sub.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Document: ${sub.documentTitle}'),
                  Text('Files attached: ${sub.signedFiles.length} page(s)'),
                  Text(
                    'Submitted: ${sub.submissionDate.toLocal().toString().split('.').first}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Confirm deletion
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Profile'),
                      content: Text('Are you sure you want to delete ${sub.fullName}? All associated information and files will be permanently removed.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() {
                              SubmissionDatabase.submissions.removeAt(index);
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile and files deleted successfully.')),
                            );
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              onTap: () {
                // Navigate to detail view to see files & download
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignerDetailScreen(submission: sub),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}