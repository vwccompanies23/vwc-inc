import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InteractiveSignContractScreen extends StatefulWidget {
  final String docId;
  final String docTitle;
  final String company;
  final List<String> pageUrls;
  final String signerName;
  final String signerEmail;
  final String signerAge;
  final String signerYear;
  final String signerMonthDate;
  final String signerCountry;
  final String signerAddress;
  final String selectedLanguage;

  const InteractiveSignContractScreen({
    super.key,
    required this.docId,
    required this.docTitle,
    required this.company,
    required this.pageUrls,
    required this.signerName,
    required this.signerEmail,
    required this.signerAge,
    required this.signerYear,
    required this.signerMonthDate,
    required this.signerCountry,
    required this.signerAddress,
    required this.selectedLanguage,
  });

  @override
  State<InteractiveSignContractScreen> createState() => _InteractiveSignContractScreenState();
}

class _InteractiveSignContractScreenState extends State<InteractiveSignContractScreen> {
  int _currentPageIndex = 0;
  bool _isSubmitting = false;
  bool _isLoadingConfig = true;

  List<Map<String, dynamic>> _taggedFields = [];

  final Map<int, Map<int, TextEditingController>> _textControllers = {};
  final Map<int, Map<int, SignatureController>> _signatureControllers = {};

  final Map<String, Map<String, String>> _localizedText = {
    'English': {
      'pageIndicator': 'Page',
      'of': 'of',
      'textHint': 'Type here...',
      'signatureTitle': 'Sign here',
      'clearButton': 'Clear',
      'prevButton': 'Previous',
      'nextButton': 'Next',
      'submitButton': 'SUBMIT CONTRACT',
      'errIncomplete': 'Please complete all required fields and signatures on this page before proceeding.',
      'successTitle': 'Contract Signed Successfully!',
      'successMsg': 'Thank you! Your signed document and details have been securely recorded.',
      'doneButton': 'Done',
    },
    'Swahili': {
      'pageIndicator': 'Ukurasa',
      'of': 'ya',
      'textHint': 'Andika hapa...',
      'signatureTitle': 'Weka saini hapa',
      'clearButton': 'Futa',
      'prevButton': 'Ukurasa uliopita',
      'nextButton': 'Inayofuata',
      'submitButton': 'WASILISHA MKATABA',
      'errIncomplete': 'Tafadhali jaza sehemu zote zinazohitajika kabla ya kuendelea.',
      'successTitle': 'Mkataba Umesainiwa!',
      'successMsg': 'Asante! Mkataba wako umehifadhiwa salama.',
      'doneButton': 'Nimemaliza',
    },
    'French': {
      'pageIndicator': 'Page',
      'of': 'sur',
      'textHint': 'Tapez ici...',
      'signatureTitle': 'Signer ici',
      'clearButton': 'Effacer',
      'prevButton': 'Précédent',
      'nextButton': 'Suivant',
      'submitButton': 'SOUMETTRE LE CONTRAT',
      'errIncomplete': 'Veuillez remplir tous les champs requis avant de continuer.',
      'successTitle': 'Contrat Signé avec Succès !',
      'successMsg': 'Merci ! Vos informations ont été enregistrées.',
      'doneButton': 'Terminé',
    },
  };

  String t(String key) {
    final lang = widget.selectedLanguage;
    return _localizedText[lang]?[key] ?? _localizedText['English']![key]!;
  }

  @override
  void initState() {
    super.initState();
    _fetchTaggedFields();
  }

  Future<void> _fetchTaggedFields() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('contracts').doc(widget.docId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        List<dynamic> rawFields = [];
        if (data.containsKey('taggedFields')) {
          rawFields = data['taggedFields'];
        } else if (data.containsKey('fields')) {
          rawFields = data['fields'];
        }

        setState(() {
          _taggedFields = rawFields.map((f) => Map<String, dynamic>.from(f)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading tagged fields: $e');
    } finally {
      setState(() {
        _isLoadingConfig = false;
      });
    }
  }

  TextEditingController _getTextController(int fieldIndex, String defaultText) {
    _textControllers.putIfAbsent(_currentPageIndex, () => {});
    if (!_textControllers[_currentPageIndex]!.containsKey(fieldIndex)) {
      _textControllers[_currentPageIndex]![fieldIndex] = TextEditingController(text: defaultText);
    }
    return _textControllers[_currentPageIndex]![fieldIndex]!;
  }

  SignatureController _getSigController(int fieldIndex) {
    _signatureControllers.putIfAbsent(_currentPageIndex, () => {});
    if (!_signatureControllers[_currentPageIndex]!.containsKey(fieldIndex)) {
      _signatureControllers[_currentPageIndex]![fieldIndex] = SignatureController(
        penStrokeWidth: 3,
        penColor: Colors.black,
        exportBackgroundColor: Colors.transparent,
      );
    }
    return _signatureControllers[_currentPageIndex]![fieldIndex]!;
  }

  bool _isCurrentPageComplete() {
    final pageFields = _taggedFields.where((f) => (f['page'] ?? 0) == _currentPageIndex).toList();
    for (int i = 0; i < pageFields.length; i++) {
      final field = pageFields[i];
      final type = field['type'] ?? 'text';
      if (type == 'text') {
        final val = _getTextController(i, '').text.trim();
        if (val.isEmpty) return false;
      } else if (type == 'signature') {
        final sigCtrl = _getSigController(i);
        if (!sigCtrl.isNotEmpty) return false;
      }
    }
    return true;
  }

  void _nextPage() {
    if (!_isCurrentPageComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('errIncomplete')), backgroundColor: Colors.red),
      );
      return;
    }

    if (_currentPageIndex < widget.pageUrls.length - 1) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('errIncomplete')), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('signed_contracts').add({
        'docId': widget.docId,
        'docTitle': widget.docTitle,
        'company': widget.company,
        'signerName': widget.signerName,
        'signerEmail': widget.signerEmail,
        'signerAge': widget.signerAge,
        'signerYear': widget.signerYear,
        'signerMonthDate': widget.signerMonthDate,
        'signerCountry': widget.signerCountry,
        'signerAddress': widget.signerAddress,
        'selectedLanguage': widget.selectedLanguage,
        'status': 'Completed',
        'signedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(t('successTitle')),
          content: Text(t('successMsg')),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E24)),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(t('doneButton'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
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
    for (var pageMap in _textControllers.values) {
      for (var c in pageMap.values) {
        c.dispose();
      }
    }
    for (var pageMap in _signatureControllers.values) {
      for (var c in pageMap.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.pageUrls[_currentPageIndex];
    final isLastPage = _currentPageIndex == widget.pageUrls.length - 1;
    final pageFields = _taggedFields.where((f) => (f['page'] ?? 0) == _currentPageIndex).toList();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('${widget.docTitle} (${t('pageIndicator')} ${_currentPageIndex + 1} ${t('of')} ${widget.pageUrls.length})'),
        backgroundColor: const Color(0xFF8B1E24),
        automaticallyImplyLeading: false,
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
                          for (int i = 0; i < pageFields.length; i++)
                            Positioned(
                              left: (pageFields[i]['x'] ?? 0.1) * constraints.maxWidth,
                              top: (pageFields[i]['y'] ?? 0.1) * constraints.maxHeight,
                              child: SizedBox(
                                width: 160,
                                child: (pageFields[i]['type'] ?? 'text') == 'text'
                                    ? TextField(
                                  controller: _getTextController(i, i == 0 ? widget.signerName : ''),
                                  onChanged: (val) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: t('textHint'),
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
                                          Text(t('signatureTitle'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          InkWell(
                                            onTap: () {
                                              _getSigController(i).clear();
                                              setState(() {});
                                            },
                                            child: Text(t('clearButton'), style: const TextStyle(fontSize: 10, color: Colors.red)),
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
                      label: Text(t('prevButton')),
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
                      isLastPage ? t('submitButton') : t('nextButton'),
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