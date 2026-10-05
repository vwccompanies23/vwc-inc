import 'dart:io';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:vwc_app/services/cloudinary_service.dart';

// Model to represent dynamic fields on each paper page
class DocumentField {
  final String id;
  final String label;
  final String type; // 'text', 'checkbox', 'signature'
  bool isRequired;
  dynamic value;

  DocumentField({
    required this.id,
    required this.label,
    required this.type,
    this.isRequired = true,
    this.value,
  });
}

// Model representing a single page of a multi-page document
class DocumentPageData {
  final int pageNumber;
  final String pageTitle;
  final String contentText;
  final List<DocumentField> fields;

  DocumentPageData({
    required this.pageNumber,
    required this.pageTitle,
    required this.contentText,
    required this.fields,
  });
}

class DocumentSigningScreen extends StatefulWidget {
  final Map<String, dynamic>? activeContract;

  const DocumentSigningScreen({
    super.key,
    this.activeContract,
  });

  @override
  State<DocumentSigningScreen> createState() => _DocumentSigningScreenState();
}

class _DocumentSigningScreenState extends State<DocumentSigningScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  bool _isSubmitting = false;

  // Controllers for signature pads and text input
  final Map<String, SignatureController> _signatureControllers = {};
  final Map<String, TextEditingController> _textControllers = {};

  late List<DocumentPageData> _documentPages;

  @override
  void initState() {
    super.initState();
    _initializeDocument();
  }

  void _initializeDocument() {
    final String docTitle = widget.activeContract?['title'] ?? 'Terms of Agreement';
    final String companyName = widget.activeContract?['companyName'] ?? 'VWC Operations';
    final String instructions = widget.activeContract?['description'] ??
        'Please review the company rules, work schedules, and standard safety operational procedures outlined below.';

    _documentPages = [
      DocumentPageData(
        pageNumber: 1,
        pageTitle: 'Page 1: $docTitle',
        contentText: 'Welcome to $companyName.\n\n$instructions',
        fields: [
          DocumentField(
            id: 'p1_name',
            label: 'Full Legal Name',
            type: 'text',
          ),
          DocumentField(
            id: 'p1_agree',
            label: 'I have read and agree to $companyName rules & regulations',
            type: 'checkbox',
            value: false,
          ),
        ],
      ),
      DocumentPageData(
        pageNumber: 2,
        pageTitle: 'Page 2: Liability & Digital Signature',
        contentText:
        'By signing below, you acknowledge and confirm that all submitted details are valid and accurate to the best of your knowledge.',
        fields: [
          DocumentField(
            id: 'p2_date',
            label: 'Date of Signing (MM/DD/YYYY)',
            type: 'text',
          ),
          DocumentField(
            id: 'p2_signature',
            label: 'Worker Digital Signature',
            type: 'signature',
          ),
        ],
      ),
    ];

    // Initialize individual controllers for each field
    for (var page in _documentPages) {
      for (var field in page.fields) {
        if (field.type == 'text') {
          _textControllers[field.id] = TextEditingController();
        } else if (field.type == 'signature') {
          _signatureControllers[field.id] = SignatureController(
            penStrokeWidth: 3,
            penColor: Colors.black,
            exportBackgroundColor: Colors.white,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    for (var controller in _signatureControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _validateAllPages() {
    for (var page in _documentPages) {
      for (var field in page.fields) {
        if (!field.isRequired) continue;

        if (field.type == 'text') {
          final text = _textControllers[field.id]?.text ?? '';
          if (text.trim().isEmpty) return false;
        } else if (field.type == 'checkbox') {
          if (field.value != true) return false;
        } else if (field.type == 'signature') {
          final sigController = _signatureControllers[field.id];
          if (sigController == null || sigController.isEmpty) return false;
        }
      }
    }
    return true;
  }

  Future<void> _submitDocument() async {
    if (!_validateAllPages()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields and signatures across all pages.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 1. Generate text summary/document
    final directory = await getApplicationDocumentsDirectory();
    final String fileName =
        "Signed_${widget.activeContract?['title'] ?? 'VWC_Contract'}_${DateTime.now().millisecondsSinceEpoch}.txt";
    final File savedFile = File('${directory.path}/$fileName');

    StringBuffer content = StringBuffer();
    content.writeln("=== COMPLETED & SIGNED VWC CONTRACT ===");
    content.writeln("Contract Title: ${widget.activeContract?['title'] ?? 'Standard Contract'}");
    content.writeln("Company: ${widget.activeContract?['companyName'] ?? 'VWC'}");
    content.writeln("Date: ${DateTime.now().toIso8601String()}");

    for (var page in _documentPages) {
      content.writeln("\n--- ${page.pageTitle} ---");
      for (var field in page.fields) {
        if (field.type == 'text') {
          content.writeln("${field.label}: ${_textControllers[field.id]?.text}");
        } else if (field.type == 'checkbox') {
          content.writeln("${field.label}: ${field.value ? 'AGREED' : 'NOT AGREED'}");
        } else if (field.type == 'signature') {
          content.writeln("${field.label}: [DIGITALLY SIGNED]");
        }
      }
    }

    await savedFile.writeAsString(content.toString());

    // 2. Upload signed document back to Cloudinary
    final signedUploadResult = await CloudinaryService.uploadContract(savedFile);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (signedUploadResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contract signed & uploaded to Cloudinary successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OPEN FILE',
            textColor: Colors.white,
            onPressed: () {
              OpenFile.open(savedFile.path);
            },
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved locally, but failed to upload to Cloudinary.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(savedFile.path),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.activeContract != null
              ? '${widget.activeContract!['title']} (${_currentPageIndex + 1}/${_documentPages.length})'
              : 'VWC Contract (${_currentPageIndex + 1}/${_documentPages.length})',
        ),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPageIndex + 1) / _documentPages.length,
            backgroundColor: Colors.grey.shade300,
            color: const Color(0xFF8B1E24),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              itemCount: _documentPages.length,
              itemBuilder: (context, pageIndex) {
                final page = _documentPages[pageIndex];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        page.pageTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B1E24),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 1,
                        color: Colors.grey.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            page.contentText,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Required Actions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...page.fields.map((field) => _buildFieldWidget(field)),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPageIndex > 0)
                  OutlinedButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  )
                else
                  const SizedBox.shrink(),
                if (_currentPageIndex < _documentPages.length - 1)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E24),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next Page'),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isSubmitting ? null : _submitDocument,
                    icon: _isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.check_circle),
                    label: Text(_isSubmitting ? 'Uploading...' : 'Submit & Sign Paper'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldWidget(DocumentField field) {
    if (field.type == 'text') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: TextField(
          controller: _textControllers[field.id],
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.edit, color: Color(0xFF8B1E24)),
          ),
        ),
      );
    } else if (field.type == 'checkbox') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: CheckboxListTile(
          title: Text(field.label, style: const TextStyle(fontSize: 14)),
          value: field.value ?? false,
          activeColor: const Color(0xFF8B1E24),
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            setState(() {
              field.value = val;
            });
          },
        ),
      );
    } else if (field.type == 'signature') {
      final sigController = _signatureControllers[field.id];
      return Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Signature(
                controller: sigController!,
                height: 150,
                backgroundColor: Colors.grey.shade100,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => sigController.clear(),
                icon: const Icon(Icons.clear, color: Colors.red, size: 18),
                label: const Text('Clear Signature', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}