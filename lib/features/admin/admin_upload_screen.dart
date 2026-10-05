import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vwc_app/services/cloudinary_service.dart';
import 'package:vwc_app/features/admin/admin_links_screen.dart';
import 'package:vwc_app/features/admin/admin_submissions_screen.dart';
import 'package:vwc_app/features/admin/admin_document_tagger_screen.dart';
// TODO: Import your login screen file here if needed, e.g.:
// import 'package:vwc_app/features/auth/login_screen.dart';

class LinksDatabase {
  static const String _storageKey = 'persistent_admin_links_v1';

  static Future<List<Map<String, String>>> getLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_storageKey);
    if (encodedData == null) return [];

    try {
      final List<dynamic> decodedList = jsonDecode(encodedData);
      return decodedList.map((item) => Map<String, String>.from(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addLink(Map<String, String> newLink) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, String>> currentLinks = await getLinks();
    currentLinks.insert(0, newLink);
    final String encodedData = jsonEncode(currentLinks);
    await prefs.setString(_storageKey, encodedData);
  }
}

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyController =
  TextEditingController(text: 'VWC Operations');
  final TextEditingController _descriptionController = TextEditingController();

  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  bool _uploadSuccess = false;
  String? _generatedDeepLink;
  String? _latestCode;
  String? _createdDocId;
  List<String> _uploadedUrls = [];
  bool _isConfirmed = false;

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your admin account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E24)),
            onPressed: () {
              Navigator.pop(context); // Close dialog

              // Clears entire route stack and takes admin back to login screen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlaceholderLoginScreen(), // Replace with your actual LoginScreen()
                ),
                    (route) => false,
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.files);
          _uploadSuccess = false;
          _generatedDeepLink = null;
          _isConfirmed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _previewFile(PlatformFile file, int index) {
    final extension = file.extension?.toLowerCase() ?? '';
    final isImage = ['jpg', 'jpeg', 'png'].contains(extension);
    final hasValidPath = !kIsWeb && file.path != null && file.path!.isNotEmpty;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Preview Page ${index + 1}: ${file.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Center(
                  child: isImage && hasValidPath && File(file.path!).existsSync()
                      ? InteractiveViewer(
                    child: Image.file(File(file.path!), fit: BoxFit.contain),
                  )
                      : isImage && file.bytes != null
                      ? InteractiveViewer(
                    child: Image.memory(file.bytes!, fit: BoxFit.contain),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf,
                          size: 64, color: Color(0xFF8B1E24)),
                      const SizedBox(height: 12),
                      Text(
                        '${extension.toUpperCase()} Document File',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E24),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        setState(() {
                          _isConfirmed = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('File confirmed successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateFinalDeepLink() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Document Title first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one document or image file.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadedUrls.clear();
    });

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyBDWAqNEqQMvvflcc-hAf228djSCuAaVDy",
            appId: "1:392278695897:web:6236358a380b74573883c8",
            messagingSenderId: "392278695897",
            projectId: "vwc-inc",
            authDomain: "vwc-inc.firebaseapp.com",
            storageBucket: "vwc-inc.firebasestorage.app",
            measurementId: "G-4YVSM3JR5",
          ),
        );
      }

      for (final platformFile in _selectedFiles) {
        File? fileToUpload;
        Uint8List? fileBytes = platformFile.bytes;

        if (!kIsWeb && platformFile.path != null && platformFile.path!.isNotEmpty) {
          fileToUpload = File(platformFile.path!);
          if (fileBytes == null && fileToUpload.existsSync()) {
            fileBytes = await fileToUpload.readAsBytes();
          }
        }

        final Map<String, String>? uploadResult =
        await CloudinaryService.uploadContract(
          file: fileToUpload,
          bytes: fileBytes,
          filename: platformFile.name,
        );

        if (uploadResult != null) {
          final String? secureUrl = uploadResult['secure_url'];
          final String? fallbackUrl = uploadResult['url'];
          final String finalUrl = secureUrl ?? fallbackUrl ?? '';

          if (finalUrl.isNotEmpty) {
            _uploadedUrls.add(finalUrl);
          }
        }
      }

      if (_uploadedUrls.isEmpty) {
        throw Exception('Cloudinary upload failed: No files returned a valid URL.');
      }

      final String uniqueSignCode =
      (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('contracts')
          .add({
        'title': _titleController.text.trim(),
        'company': _companyController.text.trim(),
        'code': uniqueSignCode,
        'pageUrls': _uploadedUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'isTagged': false,
      });

      final String encodedTitle = Uri.encodeComponent(_titleController.text.trim());
      final String encodedCompany = Uri.encodeComponent(_companyController.text.trim());
      final String encodedUrls = Uri.encodeComponent(_uploadedUrls.join(','));

      final String deepLink =
          "https://vwc-inc.web.app/#/sign?docId=${docRef.id}&docTitle=$encodedTitle&company=$encodedCompany&code=$uniqueSignCode&urls=$encodedUrls";

      setState(() {
        _isUploading = false;
        _uploadSuccess = true;
        _latestCode = uniqueSignCode;
        _createdDocId = docRef.id;
        _generatedDeepLink = deepLink;
      });

      await LinksDatabase.addLink({
        'title': _titleController.text.trim(),
        'company': _companyController.text.trim(),
        'url': deepLink,
        'code': uniqueSignCode,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link generated & saved to Firebase successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  void _openTaggerCanvas() {
    if (_createdDocId == null || _uploadedUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate the link first so the document is saved!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminDocumentTaggerScreen(
          docId: _createdDocId!,
          pageUrls: _uploadedUrls,
        ),
      ),
    );
  }

  void _copyLink() {
    if (_generatedDeepLink != null) {
      Clipboard.setData(ClipboardData(text: _generatedDeepLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signing link copied to clipboard!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _shareLink() {
    if (_generatedDeepLink != null) {
      Share.share(
        'Please review and sign the contract papers.\nLink: $_generatedDeepLink\nAccess Code: ${_latestCode ?? '1234'}',
        subject: 'Contract Signing Request - ${_titleController.text}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload & Tag Document'),
        backgroundColor: const Color(0xFF8B1E24),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View All Links',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminLinksScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'View Submissions',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminSubmissionsScreen(),
                ),
              );
            },
          ),
          // Logout Button Added Here
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Enter Document Details & Select Files',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Document Title *',
                  hintText: 'e.g. Employment Contract 2026',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title, color: Color(0xFF8B1E24)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company / Unit Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business, color: Color(0xFF8B1E24)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description / Instructions',
                  hintText: 'Notes for the signer...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description, color: Color(0xFF8B1E24)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A6065),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.library_add),
                  label: Text(_selectedFiles.isEmpty
                      ? 'Select Files (1 to 100+)'
                      : 'Add More Files (${_selectedFiles.length} Selected)'),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedFiles.isNotEmpty) ...[
                const Text(
                  '2. Tap file to Preview & Confirm:',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B1E24)),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    final extension = file.extension?.toLowerCase() ?? '';
                    final isImage = ['jpg', 'jpeg', 'png'].contains(extension);
                    final hasValidPath =
                        !kIsWeb && file.path != null && file.path!.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      child: ListTile(
                        onTap: () => _previewFile(file, index),
                        leading: isImage &&
                            hasValidPath &&
                            File(file.path!).existsSync()
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(file.path!),
                            width: 45,
                            height: 45,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1E24),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              'P${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        ),
                        title: Text(
                          'Page ${index + 1}: ${file.name}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _isConfirmed
                              ? 'Confirmed ✓'
                              : 'Tap here to Preview & Confirm',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isConfirmed ? Colors.green : Colors.blueGrey,
                            fontWeight:
                            _isConfirmed ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _removeFile(index),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E24),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isUploading ? null : _generateFinalDeepLink,
                  child: _isUploading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Generate Final Signing Link & Save',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_uploadSuccess && _generatedDeepLink != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _openTaggerCanvas,
                    icon: const Icon(Icons.edit_location_alt),
                    label: const Text(
                      'Open Tagging Canvas (Place Signatures)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.link_sharp, color: Colors.green, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Signing Link Successfully Generated!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Signer Access Code:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _latestCode ?? '1234',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B1E24),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        _generatedDeepLink!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _copyLink,
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('Copy Link'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B1E24),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _shareLink,
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share Link'),
                            ),
                          ),
                        ],
                      ),
                    ],
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

// Placeholder widget for your login screen. Replace with your actual LoginScreen() class.
class PlaceholderLoginScreen extends StatelessWidget {
  const PlaceholderLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(
        child: Text('Password / Login Screen'),
      ),
    );
  }
}