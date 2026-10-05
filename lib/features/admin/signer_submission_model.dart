import 'package:file_picker/file_picker.dart';

class SignerSubmission {
  final String id;
  final String fullName;
  final String email;
  final String documentTitle;
  final String company;
  final DateTime submissionDate;
  final List<PlatformFile> signedFiles;

  SignerSubmission({
    required this.id,
    required this.fullName,
    required this.email,
    required this.documentTitle,
    required this.company,
    required this.submissionDate,
    required this.signedFiles,
  });
}

// Global list to store submitted profiles in memory (can later be synced with backend/database)
class SubmissionDatabase {
  static final List<SignerSubmission> submissions = [];
}