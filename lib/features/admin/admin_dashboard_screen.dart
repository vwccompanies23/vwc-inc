import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vwc_app/features/admin/admin_upload_screen.dart';
import 'package:vwc_app/features/admin/admin_post_screen.dart';
import 'package:vwc_app/features/admin/admin_manage_posts_screen.dart';
import 'package:vwc_app/features/worker_id/worker_id_screen.dart';
import 'package:vwc_app/features/auth/passcode_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Admin Mode'),
        content: const Text(
          'Are you sure you want to log out of the admin dashboard? You will need to enter the passcode again to re-enter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E24),
            ),
            onPressed: () async {
              // 1. Clear both login states from SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('admin_logged_in', false);
              await prefs.setBool('worker_logged_in', false);

              if (!context.mounted) return;
              Navigator.pop(context); // Close the dialog box

              // 2. Clears the navigation stack and sends them back to the PasscodeScreen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const PasscodeScreen(),
                ),
                    (route) => false,
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
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF8B1E24),
        actions: [
          // Logout button added here inside the AppBar
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Management Tools',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B1E24),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildDashboardTile(
                    context,
                    title: 'Upload Paper & Contracts',
                    subtitle: 'Upload files and configure paper signatures',
                    icon: Icons.cloud_upload,
                    color: const Color(0xFF8B1E24),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminUploadScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDashboardTile(
                    context,
                    title: 'Create Announcement Post',
                    subtitle: 'Publish updates, guidelines & links',
                    icon: Icons.post_add,
                    color: const Color(0xFF8B1E24),
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
                  _buildDashboardTile(
                    context,
                    title: 'Worker ID Generator',
                    subtitle: 'Generate & manage digital worker passes',
                    icon: Icons.badge,
                    color: const Color(0xFF7A6248),
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
                  _buildDashboardTile(
                    context,
                    title: 'Manage Guidelines & Posts',
                    subtitle: 'Edit or remove published announcements',
                    icon: Icons.manage_search,
                    color: const Color(0xFF7A6248),
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

  Widget _buildDashboardTile(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: color,
          radius: 24,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}