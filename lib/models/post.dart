import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Post {
  final String id;
  final String companyId;
  final String companyName;
  final String? title;
  final String? description;
  final String? imagePath;
  final String? externalUrl;
  final DateTime timestamp;

  Post({
    required this.id,
    required this.companyId,
    required this.companyName,
    this.title,
    this.description,
    this.imagePath,
    this.externalUrl,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert Post instance to JSON map for local storage persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'externalUrl': externalUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Construct Post instance from JSON map
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      companyId: json['companyId'],
      companyName: json['companyName'],
      title: json['title'],
      description: json['description'],
      imagePath: json['imagePath'],
      externalUrl: json['externalUrl'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// Global state holding community and company announcements with local storage persistence
class PostRepository {
  static const String _storageKey = 'saved_vwc_posts';

  // Default initial mock posts used on fresh app installs
  static final List<Post> _defaultPosts = [
    Post(
      id: '1',
      companyId: 'vwc',
      companyName: 'VWC Group',
      title: 'Safety Guidelines & Protocols',
      description: 'Please review the updated site safety standards and operational instructions.',
      externalUrl: 'https://youtube.com',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Post(
      id: '2',
      companyId: 'vwc',
      companyName: 'VWC Group',
      description: 'Quick announcement: All site offices will close early this Friday at 4 PM.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  // ValueNotifier triggers automatic UI updates when posts are loaded, added, or deleted
  static final ValueNotifier<List<Post>> postsNotifier = ValueNotifier<List<Post>>(_defaultPosts);

  // Getter for convenience
  static List<Post> get posts => postsNotifier.value;

  /// Loads saved posts from SharedPreferences on app launch
  static Future<void> loadPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(jsonString);
        final List<Post> loadedPosts =
        decodedList.map((item) => Post.fromJson(item)).toList();
        postsNotifier.value = loadedPosts;
      } else {
        // First run: save defaults into storage
        await _saveToStorage();
      }
    } catch (e) {
      debugPrint('Error loading posts from SharedPreferences: $e');
    }
  }

  /// Writes current postsNotifier state to persistent local storage
  static Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
      jsonEncode(postsNotifier.value.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving posts to SharedPreferences: $e');
    }
  }

  /// Method to add a new post dynamically and save to disk
  static Future<void> addPost(Post newPost) async {
    postsNotifier.value = [newPost, ...postsNotifier.value];
    await _saveToStorage();
  }

  /// Method to delete a post dynamically and update disk storage
  static Future<void> deletePost(String postId) async {
    final updatedList = List<Post>.from(postsNotifier.value)
      ..removeWhere((p) => p.id == postId);
    postsNotifier.value = updatedList;
    await _saveToStorage();
  }
}