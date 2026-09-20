import 'package:flutter/material.dart';
import 'package:vwc_app/features/admin/admin_upload_screen.dart';
import 'package:vwc_app/features/admin/admin_post_screen.dart';
import 'package:vwc_app/features/admin/admin_manage_posts_screen.dart';
import 'package:vwc_app/features/worker_id/worker_id_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VWC Admin Control Center'),
        backgroundColor: const Color(0xFF8B1E24),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Operations',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Manage company papers, post guidelines, and generate worker IDs.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildAdminCard(
                    context,
                    title: 'Upload Paper & Share Link',
                    subtitle: 'Upload contract files and generate signing deep links',
                    icon: Icons.cloud_upload,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminUploadScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAdminCard(
                    context,
                    title: 'Posting Guidelines & Announcements',
                    subtitle: 'Publish updates, photos, and files to worker feed',
                    icon: Icons.campaign,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminPostScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAdminCard(
                    context,
                    title: 'Worker ID Badge Generator',
                    subtitle: 'Create official digital IDs with QR codes',
                    icon: Icons.badge,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkerIdScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAdminCard(
                    context,
                    title: 'Manage & Delete Saved Content',
                    subtitle: 'View all saved posts, pictures, and delete unwanted posts',
                    icon: Icons.delete_sweep,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminManagePostsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF8B1E24).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF8B1E24), size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}