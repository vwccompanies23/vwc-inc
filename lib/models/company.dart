import 'package:flutter/material.dart';

class Company {
  final String id;
  final String name;
  final String logoPath;
  final Color primaryColor;
  final Color accentColor;
  final List<String> availableBadgeColors;

  const Company({
    required this.id,
    required this.name,
    required this.logoPath,
    required this.primaryColor,
    required this.accentColor,
    required this.availableBadgeColors,
  });
}

class CompanyRepository {
  static const List<Company> companies = [
    Company(
      id: 'vwc',
      name: 'VWC Group',
      logoPath: 'assets/logos/vwc_logo.png',
      primaryColor: Color(0xFF8B1E24), // VWC Crimson Red
      accentColor: Color(0xFFE5A93C),  // VWC Gold
      availableBadgeColors: [
        'VWC Crimson',
        'VWC Gold',
        'VWC Olive Green',
        'VWC Warm Brown',
        'Silver',
      ],
    ),
    Company(
      id: 'sub_co_1',
      name: 'Subsidiary Company A',
      logoPath: 'assets/images/sub_a_logo.png',
      primaryColor: Color(0xFF1E3A8A),
      accentColor: Color(0xFF94A3B8),
      availableBadgeColors: ['Silver', 'Navy Blue', 'Gold'],
    ),
  ];
}