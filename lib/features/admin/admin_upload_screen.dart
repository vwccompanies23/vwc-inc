import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vwc_app/models/contract.dart';
import 'package:vwc_app/services/cloudinary_service.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedFile;
  String? _fileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _companyNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document file to upload.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Determine resource type based on file extension
      final extension = _fileName?.split('.').last.toLowerCase() ?? '';
      final resourceType = ['png', 'jpg', 'jpeg'].contains(extension) ? 'image' : 'raw';

      // 2. Upload file to Cloudinary (passes positional argument)
      final cloudinaryResponse = await CloudinaryService.uploadContract(_selectedFile!);

      if (cloudinaryResponse != null) {
        // 3. Create ContractDocument matching model parameters
        final newContract = ContractDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          companyName: _companyNameController.text.trim().isEmpty
              ? 'VWC Operations'
              : _companyNameController.text.trim(),
          description: _descriptionController.text.trim(),
          contractUrl: cloudinaryResponse['secure_url'] ?? cloudinaryResponse['url'] ?? '',
          publicId: cloudinaryResponse['public_id'] ?? '',
          resourceType: resourceType,
        );

        // 4. Save locally to repository state & persistent storage
        await ContractRepository.addContract(newContract);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document uploaded successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Cloudinary upload returned null response.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload Company Paper or Contract',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Document Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter document title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company / Unit Name',
                  hintText: 'e.g., VWC Operations',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description / Instructions',
                  hintText: 'Optional instructions for workers signing this document...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null ? Icons.insert_drive_file : Icons.cloud_upload_outlined,
                      size: 48,
                      color: const Color(0xFF8B1E24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fileName ?? 'No file selected (PDF, DOCX, or Image)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Select File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E24),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                  'Upload & Generate Deep Link',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}