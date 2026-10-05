import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

Widget renderPdf(PlatformFile file) {
  if (file.bytes == null) {
    return const Text('Unable to load PDF bytes.');
  }

  final blob = html.Blob([file.bytes!], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final viewId = 'pdf-view-${file.name.hashCode}-${DateTime.now().millisecondsSinceEpoch}';

  // Register the iframe view factory
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
    final iframe = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    return iframe;
  });

  return HtmlElementView(viewType: viewId);
}