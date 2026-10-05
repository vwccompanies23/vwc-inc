import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Convert Post instance to Map for Firestore persistence
  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'externalUrl': externalUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Construct Post instance from Firestore DocumentSnapshot
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      title: data['title'],
      description: data['description'],
      imagePath: data['imagePath'],
      externalUrl: data['externalUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// Global state holding community and company announcements synchronized with Firestore
class PostRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _postsRef = _firestore.collection('posts');

  // ValueNotifier triggers automatic UI updates when posts are loaded, added, or deleted
  static final ValueNotifier<List<Post>> postsNotifier = ValueNotifier<List<Post>>([]);

  // Getter for convenience
  static List<Post> get posts => postsNotifier.value;

  /// Loads posts from Firestore and listens for real-time updates across all devices
  static Future<void> loadPosts() async {
    try {
      _postsRef.orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
        final List<Post> loadedPosts = snapshot.docs
            .map((doc) => Post.fromFirestore(doc))
            .toList();
        postsNotifier.value = loadedPosts;
      }, onError: (e) {
        debugPrint('Error listening to Firestore posts stream: $e');
      });
    } catch (e) {
      debugPrint('Error loading posts from Firestore: $e');
    }
  }

  /// Method to add a new post dynamically directly to Firestore
  static Future<void> addPost(Post newPost) async {
    try {
      await _postsRef.add(newPost.toMap());
    } catch (e) {
      debugPrint('Error adding post to Firestore: $e');
      rethrow;
    }
  }

  /// Method to delete a post permanently from Firestore
  static Future<void> deletePost(String postId) async {
    try {
      // Deletes the document directly from Firestore cloud storage
      await _postsRef.doc(postId).delete();

      // Update local notifier state immediately
      final updatedList = List<Post>.from(postsNotifier.value)
        ..removeWhere((p) => p.id == postId);
      postsNotifier.value = updatedList;

      debugPrint('Post $postId permanently deleted from everywhere.');
    } catch (e) {
      debugPrint('Error deleting post from Firestore: $e');
      rethrow;
    }
  }
}