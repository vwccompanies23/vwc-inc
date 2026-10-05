import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vwc_app/models/post.dart';
import 'package:vwc_app/features/documents_signings/document_signing_screen.dart';

class NotificationsScreen extends StatelessWidget {
  final bool hasPendingDocument;

  const NotificationsScreen({
    super.key,
    this.hasPendingDocument = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: ValueListenableBuilder<List<Post>>(
        valueListenable: PostRepository.postsNotifier,
        builder: (context, posts, child) {
          final bool hasNotifications = hasPendingDocument || posts.isNotEmpty;

          if (!hasNotifications) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No new notifications',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Real Document Signing Action Notification
              if (hasPendingDocument) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFF8B1E24), width: 1.5),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF8B1E24),
                      child: Icon(Icons.assignment_late, color: Colors.white),
                    ),
                    title: const Text(
                      'Action Required: Sign Contract',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'You have a pending contract/paper that requires your signature.',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF8B1E24),
                    ),
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
                                signerName: docData['signerName'] ?? 'Worker',
                                signerEmail:
                                docData['signerEmail'] ?? 'worker@vwc.com',
                                selectedLanguage:
                                docData['selectedLanguage'] ?? 'English',
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
                          SnackBar(content: Text('Error loading contract: $e')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Real Dynamic Post Notifications
              if (posts.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
                  child: Text(
                    'Company Announcements',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ...posts.map((post) {
                  final String title =
                  (post.title != null && post.title!.isNotEmpty)
                      ? post.title!
                      : 'New Announcement from ${post.companyName}';

                  final String subtitle =
                  (post.description != null && post.description!.isNotEmpty)
                      ? post.description!
                      : 'Tap to view post updates.';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF7A6248),
                        child: Icon(Icons.campaign, color: Colors.white),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        '${post.timestamp.hour}:${post.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}