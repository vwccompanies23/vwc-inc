import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Persistent storage helper for links
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

  static Future<void> deleteLink(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, String>> currentLinks = await getLinks();
    if (index >= 0 && index < currentLinks.length) {
      currentLinks.removeAt(index);
      final String encodedData = jsonEncode(currentLinks);
      await prefs.setString(_storageKey, encodedData);
    }
  }
}

class AdminLinksScreen extends StatefulWidget {
  // We can keep this parameter optional now so it works whether passed or loaded from disk
  final List<Map<String, String>>? generatedLinks;

  const AdminLinksScreen({
    super.key,
    this.generatedLinks,
  });

  @override
  State<AdminLinksScreen> createState() => _AdminLinksScreenState();
}

class _AdminLinksScreenState extends State<AdminLinksScreen> {
  late Future<List<Map<String, String>>> _linksFuture;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  void _loadLinks() {
    setState(() {
      _linksFuture = LinksDatabase.getLinks();
    });
  }

  Future<void> _deleteLinkAt(int index) async {
    await LinksDatabase.deleteLink(index);
    _loadLinks(); // Refresh list after deletion
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signing link deleted successfully.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Signing Links'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _linksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B1E24)),
            );
          }

          final links = snapshot.data ?? [];

          if (links.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No signing links generated yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generated links will persist here until you delete them.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: links.length,
            itemBuilder: (context, index) {
              final linkData = links[index];
              final signCode = linkData['code'] ?? 'N/A';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description, color: Color(0xFF8B1E24)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              linkData['title'] ?? 'Document Package',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete Link',
                            onPressed: () => _deleteLinkAt(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Company: ${linkData['company'] ?? 'VWC INC'}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          'Access Code: $signCode',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B1E24),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              linkData['url'] ?? '',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B1E24),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy Link'),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: linkData['url']!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Signing link copied to clipboard!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}