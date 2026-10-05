import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vwc_app/models/post.dart';
import 'package:vwc_app/features/documents_signings/document_signing_screen.dart';
import 'package:vwc_app/features/notifications/notifications_screen.dart';
import 'package:vwc_app/features/worker_id/my_worker_id_screen.dart';
import 'package:vwc_app/features/settings/terms_of_service_screen.dart';
import 'package:vwc_app/features/scanner/document_scanner_screen.dart';
import 'package:vwc_app/features/auth/passcode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _notificationCount = 1;
  final String _vwcLearnUrl = 'https://vwc-website-omega.vercel.app/';

  Future<void> _openLink(String urlString) async {
    final Uri url = Uri.parse(
        urlString.startsWith('http') ? urlString : 'https://$urlString');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
    }
  }

  void _sharePost(Post post) {
    final String content =
        '${post.title ?? ''}\n${post.description ?? ''}\n${post.externalUrl ?? ''}';
    Clipboard.setData(ClipboardData(text: content.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link and content copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
            'Are you sure you want to log out? You will need to enter the passcode again to re-enter.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E24)),
            onPressed: () async {
              // 1. Clear the persistent login states so it doesn't auto-login again
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('admin_logged_in', false);
              await prefs.setBool('worker_logged_in', false);

              if (!context.mounted) return;
              Navigator.pop(context); // Close dialog

              // 2. Clears the back stack and returns to PasscodeScreen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const PasscodeScreen(),
                ),
                    (route) => false, // Clears navigation history
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VWC Home'),
        backgroundColor: const Color(0xFF8B1E24),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Terms of Service',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TermsOfServiceScreen()),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(
                        hasPendingDocument: _notificationCount > 0,
                      ),
                    ),
                  );
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(
                        color: Color(0xFF8B1E24),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Log Out Button in AppBar
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            const Text(
              'Welcome to VWC',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B1E24),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Official portal for company guidelines, contracts, and IDs.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // About VWC Banner Link Card
            InkWell(
              onTap: () => _openLink(_vwcLearnUrl),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B1E24), Color(0xFFB03038)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learn About VWC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap to discover VWC mission, projects & guidelines',
                            style:
                            TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions Navigation Grid
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: 'Sign Contracts',
                        icon: Icons.assignment_turned_in,
                        color: const Color(0xFF8B1E24),
                        onTap: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF8B1E24)),
                            ),
                          );

                          try {
                            final snapshot = await FirebaseFirestore.instance
                                .collection('contracts')
                                .limit(1)
                                .get();

                            if (!context.mounted) return;
                            Navigator.pop(context); // Dismiss loading dialog

                            if (snapshot.docs.isNotEmpty) {
                              final docData = snapshot.docs.first.data();
                              final docId = snapshot.docs.first.id;

                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DocumentSigningScreen(
                                    docId: docId,
                                    docTitle:
                                    docData['title'] ?? 'Company Contract',
                                    company: docData['company'] ?? 'VWC',
                                    pageUrls: List<String>.from(
                                        docData['pageUrls'] ?? []),
                                    signerName:
                                    docData['signerName'] ?? 'Worker',
                                    signerEmail: docData['signerEmail'] ??
                                        'worker@vwc.com',
                                    selectedLanguage:
                                    docData['selectedLanguage'] ??
                                        'English',
                                  ),
                                ),
                              );
                            } else {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'No pending contracts found to sign.')),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            Navigator.pop(context); // Dismiss loading dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error loading contract: $e')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: 'My Worker ID',
                        icon: Icons.badge,
                        color: const Color(0xFF7A6248),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyWorkerIdScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: 'Scan Paper File',
                        icon: Icons.document_scanner,
                        color: const Color(0xFF8B1E24),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const DocumentScannerScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Dynamic Company Posts & Guidelines Feed
            const Text(
              'Company Posts & Guidelines',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ValueListenableBuilder<List<Post>>(
              valueListenable: PostRepository.postsNotifier,
              builder: (context, posts, child) {
                if (posts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('No guidelines or posts published yet.'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final bool hasImage = post.imagePath != null &&
                        post.imagePath!.trim().isNotEmpty;
                    final bool isNetworkImage = hasImage &&
                        (post.imagePath!.startsWith('http://') ||
                            post.imagePath!.startsWith('https://'));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(
                                    post.companyName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: const Color(0xFF8B1E24),
                                ),
                                Text(
                                  '${post.timestamp.hour}:${post.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (post.title != null && post.title!.isNotEmpty) ...[
                              Text(
                                post.title!,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                            ],
                            if (post.description != null &&
                                post.description!.isNotEmpty) ...[
                              Text(
                                post.description!,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.3),
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (hasImage) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: isNetworkImage
                                    ? Image.network(
                                  post.imagePath!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child,
                                      loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return Container(
                                      height: 200,
                                      color: Colors.grey.shade100,
                                      child: const Center(
                                        child:
                                        CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                      Container(
                                        height: 200,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                                    : (!kIsWeb &&
                                    File(post.imagePath!).existsSync()
                                    ? Image.file(
                                  File(post.imagePath!),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error,
                                      stackTrace) =>
                                      Container(
                                        height: 200,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                                    : Container(
                                  height: 100,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image,
                                          color: Colors.grey),
                                      SizedBox(width: 8),
                                      Text('Image Saved Off-Device',
                                          style: TextStyle(
                                              color: Colors.grey)),
                                    ],
                                  ),
                                )),
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (post.externalUrl != null &&
                                post.externalUrl!.isNotEmpty) ...[
                              InkWell(
                                onTap: () => _openLink(post.externalUrl!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.blue.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.open_in_new,
                                          color: Colors.blue, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          post.externalUrl!,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _sharePost(post),
                                  icon: const Icon(Icons.share,
                                      color: Colors.grey),
                                  label: const Text('Share',
                                      style: TextStyle(color: Colors.grey)),
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

            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TermsOfServiceScreen()),
                  );
                },
                child: const Text(
                  'Terms of Service & Privacy Policy',
                  style: TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}