import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vwc_app/models/post.dart';

class AdminManagePostsScreen extends StatefulWidget {
  const AdminManagePostsScreen({super.key});

  @override
  State<AdminManagePostsScreen> createState() => _AdminManagePostsScreenState();
}

class _AdminManagePostsScreenState extends State<AdminManagePostsScreen> {
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

  void _deletePost(Post post) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Post?'),
          content: Text(
            'Are you sure you want to delete "${post.title ?? 'this post'}"? It will be removed from the user feed immediately.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Close the confirm dialog first
                Navigator.of(dialogContext).pop();

                try {
                  // Permanently delete from Firestore database
                  await PostRepository.deletePost(post.id);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post deleted successfully from Firestore.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete post: $e'),
                        backgroundColor: Colors.black,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Published Posts'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: ValueListenableBuilder<List<Post>>(
        valueListenable: PostRepository.postsNotifier,
        builder: (context, posts, child) {
          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'No active posts found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Delete Action Button
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
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            tooltip: 'Delete Post',
                            onPressed: () => _deletePost(post),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      if (post.title != null && post.title!.isNotEmpty) ...[
                        Text(
                          post.title!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Description
                      if (post.description != null && post.description!.isNotEmpty) ...[
                        Text(
                          post.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Attached Image Preview
                      if (post.imagePath != null && post.imagePath!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: post.imagePath!.startsWith('http')
                              ? Image.network(
                            post.imagePath!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 100,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text('Image Unavailable',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          )
                              : Container(
                            height: 100,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Attached Image Saved',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Attached External Link
                      if (post.externalUrl != null && post.externalUrl!.isNotEmpty) ...[
                        InkWell(
                          onTap: () => _openLink(post.externalUrl!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link, color: Colors.blue, size: 18),
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
                      ],
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