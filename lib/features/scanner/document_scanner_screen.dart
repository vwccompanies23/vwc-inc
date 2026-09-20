import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  DocumentScanner? _documentScanner;
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _documentScanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormat: DocumentFormat.pdf,
        // Full mode gives users built-in image cleaning, shadow removal, and contrast filters
        mode: ScannerMode.full,
        pageLimit: 10,
      ),
    );
  }

  @override
  void dispose() {
    _documentScanner?.close();
    super.dispose();
  }

  Future<void> _startScan() async {
    try {
      final result = await _documentScanner?.scanDocument();
      if (result == null || result.pdf == null) return;

      setState(() {
        _pdfPath = result.pdf!.uri;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document scanned and enhanced!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during scan: $e')),
        );
      }
    }
  }

  // Action to View/Open the scanned PDF
  Future<void> _viewDocument() async {
    if (_pdfPath != null) {
      final result = await OpenFile.open(_pdfPath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    }
  }

  // Action to Download / Export / Save the file
  Future<void> _downloadDocument() async {
    if (_pdfPath != null) {
      // Opens system share/save sheet so user can save to Downloads, Drive, or Files app
      await Share.shareXFiles([XFile(_pdfPath!)], text: 'My Clean Scanned Document');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Paper File'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.document_scanner, size: 80, color: Color(0xFF8B1E24)),
              const SizedBox(height: 16),
              const Text(
                'Document Scanner Ready',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _pdfPath != null
                    ? 'Scanned PDF ready for preview or download!'
                    : 'Tap below to scan and automatically clean your paper.',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _startScan,
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  'Start Scan',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              if (_pdfPath != null) ...[
                const SizedBox(height: 28),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ListTile(
                          leading: Icon(Icons.picture_as_pdf, color: Color(0xFF8B1E24), size: 40),
                          title: Text(
                            'Scanned Document.pdf',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Status: Cleaned & PDF formatted'),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // View Button
                            TextButton.icon(
                              onPressed: _viewDocument,
                              icon: const Icon(Icons.visibility, color: Color(0xFF8B1E24)),
                              label: const Text('View', style: TextStyle(color: Color(0xFF8B1E24))),
                            ),
                            const SizedBox(width: 8),
                            // Download / Save Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B1E24),
                              ),
                              onPressed: _downloadDocument,
                              icon: const Icon(Icons.download, color: Colors.white),
                              label: const Text('Download', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}