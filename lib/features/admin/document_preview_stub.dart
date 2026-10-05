import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

Widget renderPdf(PlatformFile file) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.picture_as_pdf, size: 56, color: Color(0xFF8B1E24)),
      const SizedBox(height: 12),
      Text(file.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text('${(file.size / 1024).toStringAsFixed(1)} KB'),
    ],
  );
}