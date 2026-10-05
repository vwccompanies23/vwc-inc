import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vwc_app/features/admin/admin_document_tagger_screen.dart'; // Make sure path matches your file tree
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // Used to safely open PDFs on web

class DocumentPreviewScreen extends StatefulWidget {
  final List<PlatformFile> files;
  final String title;
  final String company;
  final VoidCallback onConfirmUpload;

  const DocumentPreviewScreen({
    super.key,
    required this.files,
    required this.title,
    required this.company,
    required this.onConfirmUpload,
  });

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _isUploading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openPdfFile(PlatformFile file) {
    if (file.bytes != null && kIsWeb) {
      final blob = html.Blob([file.bytes!], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _handleConfirmAndTag() async {
    setState(() {
      _isUploading = true;
    });

    try {
      List<String> pageUrls = [];

      // 1. Upload each selected file page to Firebase Storage
      for (var file in widget.files) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        Reference storageRef = FirebaseStorage.instance.ref().child('contracts/$fileName');

        UploadTask uploadTask;
        if (kIsWeb) {
          uploadTask = storageRef.putData(file.bytes!);
        } else {
          if (file.path != null) {
            uploadTask = storageRef.putFile(File(file.path!));
          } else if (file.bytes != null) {
            uploadTask = storageRef.putData(file.bytes!);
          } else {
            throw Exception('File data missing');
          }
        }

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        pageUrls.add(downloadUrl);
      }

      // 2. Create document entry in Firestore to obtain a unique docId
      DocumentReference docRef = await FirebaseFirestore.instance.collection('contracts').add({
        'title': widget.title,
        'company': widget.company,
        'pageUrls': pageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      widget.onConfirmUpload(); // Trigger original callback if needed

      // 3. Seamlessly transition to the Admin Tagger Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDocumentTaggerScreen(
            docId: docRef.id,
            pageUrls: pageUrls,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview (${_currentPage + 1}/${widget.files.length})'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: _isUploading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF8B1E24)),
            SizedBox(height: 16),
            Text('Uploading contract pages to server...', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      )
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.description, color: Color(0xFF8B1E24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Company: ${widget.company}',
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.files.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final file = widget.files[index];
                final ext = file.extension?.toLowerCase() ?? '';
                final isImage = ['jpg', 'jpeg', 'png'].contains(ext);
                final isPdf = ext == 'pdf';

                return Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Page ${index + 1}: ${file.name}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Center(
                            child: isImage && !kIsWeb && file.path != null && File(file.path!).existsSync()
                                ? Image.file(
                              File(file.path!),
                              fit: BoxFit.contain,
                            )
                                : isImage && file.bytes != null
                                ? Image.memory(
                              file.bytes!,
                              fit: BoxFit.contain,
                            )
                                : isPdf
                                ? InkWell(
                              onTap: () => _openPdfFile(file),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF8B1E24), width: 1.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.picture_as_pdf,
                                      size: 64,
                                      color: Color(0xFF8B1E24),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      file.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF8B1E24),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Size: ${(file.size / 1024).toStringAsFixed(1)} KB',
                                      style: TextStyle(color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B1E24),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Tap to Open & Read PDF',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                                : Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.insert_drive_file,
                                    size: 64,
                                    color: Color(0xFF8B1E24),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${ext.toUpperCase()} File',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(file.size / 1024).toStringAsFixed(1)} KB',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E24),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _handleConfirmAndTag,
                    child: const Text('Confirm & Tag Fields'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}