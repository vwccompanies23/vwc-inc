import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'companyName': companyName,
    'description': description,
    'contractUrl': contractUrl,
    'publicId': publicId,
    'resourceType': resourceType,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ContractDocument.fromJson(Map<String, dynamic> json) => ContractDocument(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    companyName: json['companyName'] ?? 'VWC Operations',
    description: json['description'] ?? 'Please review and complete the signing process below.',
    contractUrl: json['contractUrl'] ?? '',
    publicId: json['publicId'] ?? '',
    resourceType: json['resourceType'] ?? 'raw',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );
}

// Typedef alias in case any file references "Contract" instead of "ContractDocument"
typedef Contract = ContractDocument;

class ContractRepository {
  static const String _storageKey = 'saved_contracts';
  static final ValueNotifier<List<ContractDocument>> contractsNotifier =
  ValueNotifier<List<ContractDocument>>([]);

  static Future<void> loadContracts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      contractsNotifier.value =
          decoded.map((item) => ContractDocument.fromJson(item)).toList();
    }
  }

  static Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
        contractsNotifier.value.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static Future<void> addContract(ContractDocument contract) async {
    contractsNotifier.value = [contract, ...contractsNotifier.value];
    await _saveToStorage();
  }

  static Future<bool> deleteContract(ContractDocument contract) async {
    // 1. Delete from Cloudinary
    final deletedFromCloud = await CloudinaryService.deleteContract(
      contract.publicId,
      contract.resourceType,
    );

    // 2. Remove locally
    final updatedList = List<ContractDocument>.from(contractsNotifier.value)
      ..removeWhere((c) => c.id == contract.id);
    contractsNotifier.value = updatedList;
    await _saveToStorage();

    return deletedFromCloud;
  }
}