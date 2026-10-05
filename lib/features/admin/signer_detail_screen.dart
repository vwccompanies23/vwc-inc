import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'signer_submission_model.dart';

class SignerDetailScreen extends StatelessWidget {
  final SignerSubmission submission;

  const SignerDetailScreen({super.key, required this.submission});

  void _downloadFile(dynamic file) {
    if (kIsWeb && file.bytes != null) {
      final blob = html.Blob([file.bytes!]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', file.name)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(submission.fullName),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full Name: ${submission.fullName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Email/Contact: ${submission.email}'),
                  const SizedBox(height: 4),
                  Text('Document Package: ${submission.documentTitle}'),
                  const SizedBox(height: 4),
                  Text('Company: ${submission.company}'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Signed File Papers:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B1E24)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: submission.signedFiles.length,
                itemBuilder: (context, index) {
                  final file = submission.signedFiles[index];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file, color: Color(0xFF8B1E24)),
                      title: Text(file.name),
                      subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} KB'),
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E24),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download'),
                        onPressed: () => _downloadFile(file),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}