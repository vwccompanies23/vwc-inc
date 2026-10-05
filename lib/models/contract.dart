import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vwc_app/services/cloudinary_service.dart';

class ContractDocument {
  final String id;
  final String title;
  final String companyName;
  final String description;
  final String contractUrl;
  final String publicId; // Stored to allow deletion on Cloudinary
  final String resourceType; // 'raw' for PDF, 'image' for images
  final DateTime createdAt;

  ContractDocument({
    required this.id,
    required this.title,
    this.companyName = 'VWC Operations',
    this.description = 'Please review and complete the signing process below.',
    required this.contractUrl,
    required this.publicId,
    required this.resourceType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'title': title,
    'companyName': companyName,
    'description': description,
    'contractUrl': contractUrl,
    'publicId': publicId,
    'resourceType': resourceType,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory ContractDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContractDocument(
      id: doc.id,
      title: data['title'] ?? '',
      companyName: data['companyName'] ?? 'VWC Operations',
      description: data['description'] ?? 'Please review and complete the signing process below.',
      contractUrl: data['contractUrl'] ?? '',
      publicId: data['publicId'] ?? '',
      resourceType: data['resourceType'] ?? 'raw',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// Typedef alias in case any file references "Contract" instead of "ContractDocument"
typedef Contract = ContractDocument;

class ContractRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _contractsRef = _firestore.collection('contracts');

  static final ValueNotifier<List<ContractDocument>> contractsNotifier =
  ValueNotifier<List<ContractDocument>>([]);

  /// Loads contracts from Firestore and listens for real-time updates across all devices
  static Future<void> loadContracts() async {
    try {
      _contractsRef.orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
        final List<ContractDocument> loadedContracts = snapshot.docs
            .map((doc) => ContractDocument.fromFirestore(doc))
            .toList();
        contractsNotifier.value = loadedContracts;
      }, onError: (e) {
        debugPrint('Error listening to Firestore contracts stream: $e');
      });
    } catch (e) {
      debugPrint('Error loading contracts from Firestore: $e');
    }
  }

  /// Adds a new contract document directly to Firestore
  static Future<void> addContract(ContractDocument contract) async {
    try {
      await _contractsRef.add(contract.toMap());
    } catch (e) {
      debugPrint('Error adding contract to Firestore: $e');
      rethrow;
    }
  }

  /// Deletes a contract permanently from Cloudinary and Firestore
  static Future<bool> deleteContract(ContractDocument contract) async {
    try {
      // 1. Permanently delete file from Cloudinary storage
      final deletedFromCloud = await CloudinaryService.deleteContract(
        contract.publicId,
        contract.resourceType,
      );

      // 2. Permanently delete metadata document from Firestore
      await _contractsRef.doc(contract.id).delete();

      // 3. Update local notifier state immediately
      final updatedList = List<ContractDocument>.from(contractsNotifier.value)
        ..removeWhere((c) => c.id == contract.id);
      contractsNotifier.value = updatedList;

      debugPrint('Contract ${contract.id} permanently removed from Firestore and Cloudinary.');
      return deletedFromCloud;
    } catch (e) {
      debugPrint('Error deleting contract: $e');
      return false;
    }
  }
}