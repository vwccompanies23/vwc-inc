import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AdminDocumentTaggerScreen extends StatefulWidget {
  final String docId;
  final List<String> pageUrls;

  const AdminDocumentTaggerScreen({
    super.key,
    required this.docId,
    required this.pageUrls,
  });

  @override
  State<AdminDocumentTaggerScreen> createState() => _AdminDocumentTaggerScreenState();
}

class _AdminDocumentTaggerScreenState extends State<AdminDocumentTaggerScreen> {
  int _activePageTagIndex = 0;
  String _selectedFieldType = 'text'; // 'text' or 'signature'
  bool _isSaving = false;

  // Stores coordinates relative to the image size (0.0 to 1.0)
  final List<Map<String, dynamic>> _taggedFields = [];

  void _onTapCanvas(TapDownDetails details, BoxConstraints constraints) {
    // Get relative click coordinates on the image paper
    double relativeX = details.localPosition.dx / constraints.maxWidth;
    double relativeY = details.localPosition.dy / constraints.maxHeight;

    setState(() {
      _taggedFields.add({
        'page': _activePageTagIndex,
        'x': relativeX,
        'y': relativeY,
        'type': _selectedFieldType, // 'text' or 'signature'
      });
    });
  }

  Future<void> _saveTaggedFieldsAndGenerateLink() async {
    setState(() => _isSaving = true);

    try {
      // 1. Update Firestore with the tagged fields coordinates
      await FirebaseFirestore.instance.collection('contracts').doc(widget.docId).update({
        'taggedFields': _taggedFields,
      });

      // 2. Fetch contract details from Firestore to build the deep link
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance.collection('contracts').doc(widget.docId).get();
      Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;

      String title = data?['title'] ?? 'Contract';
      String company = data?['company'] ?? 'VWC Operations';
      String code = data?['code'] ?? '1234';

      final encodedTitle = Uri.encodeComponent(title);
      final encodedCompany = Uri.encodeComponent(company);
      final encodedUrls = Uri.encodeComponent(widget.pageUrls.join(','));

      final generatedLink = 'https://vwc-inc.web.app/#/sign?docId=${widget.docId}&docTitle=$encodedTitle&company=$encodedCompany&code=$code&urls=$encodedUrls';

      setState(() => _isSaving = false);

      if (!mounted) return;

      // 3. Show Success & Link Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Fields Tagged Successfully!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The signing boxes have been mapped to your paper contract. Copy the link below for your signers:'),
              const SizedBox(height: 12),
              SelectableText(generatedLink, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E24)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: generatedLink));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
              },
              child: const Text('Copy Link', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving tags: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageUrls.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('No Pages Found'), backgroundColor: const Color(0xFF8B1E24)),
        body: const Center(child: Text('No document pages found to tag.')),
      );
    }

    final currentUrl = widget.pageUrls[_activePageTagIndex];
    final pageFields = _taggedFields.where((f) => f['page'] == _activePageTagIndex).toList();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Tag Paper (Page ${_activePageTagIndex + 1}/${widget.pageUrls.length})'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B1E24)))
          : Column(
        children: [
          // Top Action Toolbar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Select Tool:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Text Box'),
                  selected: _selectedFieldType == 'text',
                  onSelected: (selected) => setState(() => _selectedFieldType = 'text'),
                  selectedColor: Colors.amber.shade200,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Signature Pad'),
                  selected: _selectedFieldType == 'signature',
                  onSelected: (selected) => setState(() => _selectedFieldType = 'signature'),
                  selectedColor: Colors.red.shade200,
                ),
                const SizedBox(width: 24),
                if (_activePageTagIndex > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _activePageTagIndex--),
                    child: const Text('Prev Page'),
                  ),
                const SizedBox(width: 8),
                if (_activePageTagIndex < widget.pageUrls.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E24)),
                    onPressed: () => setState(() => _activePageTagIndex++),
                    child: const Text('Next Page', style: TextStyle(color: Colors.white)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _saveTaggedFieldsAndGenerateLink,
                    child: const Text('FINISH & GENERATE LINK', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Interactive Paper Document Canvas
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapDown: (details) => _onTapCanvas(details, constraints),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              currentUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                          // Render your placed markers right on the paper preview
                          for (int i = 0; i < pageFields.length; i++)
                            Positioned(
                              left: (pageFields[i]['x'] * constraints.maxWidth) - 40,
                              top: (pageFields[i]['y'] * constraints.maxHeight) - 15,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: pageFields[i]['type'] == 'text' ? Colors.amber : Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      pageFields[i]['type'] == 'text' ? 'Text' : 'Sign',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _taggedFields.remove(pageFields[i]);
                                        });
                                      },
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}