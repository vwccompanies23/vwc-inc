import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class DocumentSigningScreen extends StatefulWidget {
  final String docId;
  final String docTitle;
  final String company;
  final List<String> pageUrls;
  final String signerName;
  final String signerEmail;
  final String selectedLanguage;

  const DocumentSigningScreen({
    super.key,
    required this.docId,
    required this.docTitle,
    required this.company,
    required this.pageUrls,
    required this.signerName,
    required this.signerEmail,
    required this.selectedLanguage,
  });

  @override
  State<DocumentSigningScreen> createState() => _DocumentSigningScreenState();
}

class _DocumentSigningScreenState extends State<DocumentSigningScreen> {
  int _currentPageIndex = 0;
  bool _isSubmitting = false;
  bool _isLoadingConfig = true;

  List<Map<String, dynamic>> _taggedFields = [];

  // Controllers mapped by absolute field index to prevent page cross-pollution
  final Map<int, TextEditingController> _textControllers = {};
  final Map<int, SignatureController> _signatureControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchTaggedFields();
  }

  Future<void> _fetchTaggedFields() async {
    try {
      // Ensure Firebase is ready before querying
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(widget.docId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>? ?? {};

        List<dynamic> rawFields = [];
        if (data.containsKey('taggedFields') && data['taggedFields'] is List) {
          rawFields = data['taggedFields'];
        } else if (data.containsKey('fields') && data['fields'] is List) {
          rawFields = data['fields'];
        }

        setState(() {
          _taggedFields = rawFields
              .map((f) => f is Map ? Map<String, dynamic>.from(f) : <String, dynamic>{})
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading tagged fields: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConfig = false;
        });
      }
    }
  }

  TextEditingController _getTextController(int absoluteIndex, String defaultText) {
    if (!_textControllers.containsKey(absoluteIndex)) {
      _textControllers[absoluteIndex] = TextEditingController(text: defaultText);
    }
    return _textControllers[absoluteIndex]!;
  }

  SignatureController _getSigController(int absoluteIndex) {
    if (!_signatureControllers.containsKey(absoluteIndex)) {
      _signatureControllers[absoluteIndex] = SignatureController(
        penStrokeWidth: 3,
        penColor: Colors.black,
        exportBackgroundColor: Colors.transparent,
      );
    }
    return _signatureControllers[absoluteIndex]!;
  }

  bool _isCurrentPageComplete() {
    for (int i = 0; i < _taggedFields.length; i++) {
      final field = _taggedFields[i];
      final fieldPage = field['page'] ?? 0;

      if (fieldPage == _currentPageIndex) {
        final type = field['type'] ?? 'text';
        if (type == 'text') {
          final val = _getTextController(i, '').text.trim();
          if (val.isEmpty) return false;
        } else if (type == 'signature') {
          final sigCtrl = _getSigController(i);
          if (!sigCtrl.isNotEmpty) return false;
        }
      }
    }
    return true;
  }

  void _nextPage() {
    if (!_isCurrentPageComplete()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields and signatures on this page before proceeding.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.pageUrls.isNotEmpty && _currentPageIndex < widget.pageUrls.length - 1) {
      setState(() {
        _currentPageIndex++;
      });
    } else {
      _submitContract();
    }
  }

  void _prevPage() {
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
      });
    }
  }

  Future<void> _submitContract() async {
    if (!_isCurrentPageComplete()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields and signatures on this page before proceeding.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      await FirebaseFirestore.instance.collection('signed_contracts').add({
        'docId': widget.docId,
        'docTitle': widget.docTitle,
        'company': widget.company,
        'signerName': widget.signerName.isNotEmpty ? widget.signerName : 'Worker',
        'signerEmail': widget.signerEmail.isNotEmpty ? widget.signerEmail : 'worker@vwc.com',
        'selectedLanguage': widget.selectedLanguage,
        'status': 'Completed',
        'signedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Contract Signed Successfully!'),
          content: const Text('Thank you! Your signed document and details have been securely recorded.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E24)),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting contract: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var c in _textControllers.values) {
      c.dispose();
    }
    for (var c in _signatureControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageUrls.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.docTitle), backgroundColor: const Color(0xFF8B1E24)),
        body: const Center(child: Text('No document pages available to display.')),
      );
    }

    final imageUrl = widget.pageUrls[_currentPageIndex];
    final isLastPage = _currentPageIndex == widget.pageUrls.length - 1;
    final safeSignerName = widget.signerName.isNotEmpty ? widget.signerName : 'Worker';

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('${widget.docTitle} (Page ${_currentPageIndex + 1} of ${widget.pageUrls.length})'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: _isLoadingConfig || _isSubmitting
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B1E24)))
          : SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text('Failed to load contract page image.', style: TextStyle(color: Colors.red[700])),
                                ),
                              ),
                            ),
                          ),
                          // Render only fields belonging to the current page using absolute global index i
                          for (int i = 0; i < _taggedFields.length; i++)
                            if ((_taggedFields[i]['page'] ?? 0) == _currentPageIndex)
                              Positioned(
                                left: ((_taggedFields[i]['x'] ?? 0.1) as num).toDouble() * constraints.maxWidth,
                                top: ((_taggedFields[i]['y'] ?? 0.1) as num).toDouble() * constraints.maxHeight,
                                child: SizedBox(
                                  width: 160,
                                  child: (_taggedFields[i]['type'] ?? 'text') == 'text'
                                      ? TextField(
                                    controller: _getTextController(i, i == 0 ? safeSignerName : ''),
                                    onChanged: (val) => setState(() {}),
                                    decoration: InputDecoration(
                                      hintText: 'Type here...',
                                      filled: true,
                                      fillColor: Colors.yellow.shade100.withOpacity(0.9),
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                    ),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  )
                                      : Container(
                                    width: 180,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.red, width: 1.5),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Sign here', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            InkWell(
                                              onTap: () {
                                                _getSigController(i).clear();
                                                setState(() {});
                                              },
                                              child: const Text('Clear', style: TextStyle(fontSize: 10, color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 50,
                                          child: Signature(
                                            controller: _getSigController(i),
                                            backgroundColor: Colors.grey.shade50,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPageIndex > 0)
                    OutlinedButton.icon(
                      onPressed: _prevPage,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _nextPage,
                    child: Text(
                      isLastPage ? 'SUBMIT CONTRACT' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}