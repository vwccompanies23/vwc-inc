import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vwc_app/models/company.dart';
import 'package:vwc_app/models/post.dart';
import 'package:vwc_app/services/cloudinary_service.dart';

class AdminPostScreen extends StatefulWidget {
  const AdminPostScreen({super.key});

  @override
  State<AdminPostScreen> createState() => _AdminPostScreenState();
}

class _AdminPostScreenState extends State<AdminPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  Company _selectedCompany = CompanyRepository.companies.first;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  String? _selectedFilename;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedFilename = result.files.single.name;
        _selectedImageBytes = result.files.single.bytes;
        if (!kIsWeb && result.files.single.path != null) {
          _selectedImageFile = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);

      String? imageUrl;

      // 1. Upload to Cloudinary if an image is attached
      if (_selectedImageBytes != null || _selectedImageFile != null) {
        imageUrl = await CloudinaryService.uploadImage(
          file: _selectedImageFile,
          bytes: _selectedImageBytes,
          filename: _selectedFilename,
        );

        if (imageUrl == null) {
          setState(() => _isUploading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload image to Cloudinary. Check network connection.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // 2. Create post with Cloudinary image URL
      final newPost = Post(
        id: 'post_${DateTime.now().millisecondsSinceEpoch}',
        companyId: _selectedCompany.id,
        companyName: _selectedCompany.name,
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        imagePath: imageUrl,
        externalUrl: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
        timestamp: DateTime.now(),
      );

      try {
        // 3. Save to Firestore
        await PostRepository.addPost(newPost);

        setState(() {
          _isUploading = false;
          _selectedImageFile = null;
          _selectedImageBytes = null;
          _selectedFilename = null;
        });

        _titleController.clear();
        _descriptionController.clear();
        _urlController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Announcement published to ${_selectedCompany.name}!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to publish post: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Post Announcement'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Company>(
                value: _selectedCompany,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                  labelText: 'Select Company',
                ),
                items: CompanyRepository.companies
                    .map((co) => DropdownMenuItem(value: co, child: Text(co.name)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCompany = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Post Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description / Guidelines',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'External Link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),

              // Image Attachment Section
              InkWell(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImageBytes == null
                      ? const Column(
                    children: [
                      Icon(Icons.image, size: 36, color: Color(0xFF8B1E24)),
                      SizedBox(height: 6),
                      Text('Tap to attach an image'),
                    ],
                  )
                      : Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImageBytes!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Selected: ${_selectedFilename ?? 'Image Attached'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _selectedImageFile = null;
                                _selectedImageBytes = null;
                                _selectedFilename = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E24),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isUploading ? null : _submitPost,
                  child: _isUploading
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Uploading & Publishing...'),
                    ],
                  )
                      : const Text('Publish Announcement',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}