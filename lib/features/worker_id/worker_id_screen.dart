import 'package:flutter/material.dart';
import 'package:vwc_app/models/company.dart';

class WorkerIdScreen extends StatefulWidget {
  const WorkerIdScreen({super.key});

  @override
  State<WorkerIdScreen> createState() => _WorkerIdScreenState();
}

class _WorkerIdScreenState extends State<WorkerIdScreen> {
  Company _selectedCompany = CompanyRepository.companies.first;
  String _selectedBadgeColor = 'VWC Crimson';

  final TextEditingController _nameController = TextEditingController(text: 'John Doe');
  final TextEditingController _roleController = TextEditingController(text: 'Site Manager');
  final TextEditingController _idNumberController = TextEditingController(text: 'VWC-88492');

  Color _getBadgeHeaderColor() {
    switch (_selectedBadgeColor) {
      case 'VWC Crimson':
        return const Color(0xFF8B1E24);
      case 'VWC Gold':
        return const Color(0xFFE5A93C);
      case 'VWC Olive Green':
        return const Color(0xFF6B8E3D);
      case 'VWC Warm Brown':
        return const Color(0xFF7A6248);
      case 'Silver':
        return const Color(0xFF9E9E9E);
      default:
        return _selectedCompany.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker ID Badge Generator'),
        backgroundColor: _selectedCompany.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Company Selector
            const Text('Select Company', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<Company>(
              value: _selectedCompany,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: CompanyRepository.companies.map((co) {
                return DropdownMenuItem(value: co, child: Text(co.name));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCompany = val;
                    _selectedBadgeColor = val.availableBadgeColors.first;
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            // Badge Color Selector
            const Text('Select Badge Theme Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedBadgeColor,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _selectedCompany.availableBadgeColors.map((colorName) {
                return DropdownMenuItem(value: colorName, child: Text(colorName));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedBadgeColor = val;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // Inputs
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Worker Full Name', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(labelText: 'Job Title / Role', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Live ID Badge Card Preview
            const Text('Live Badge Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _getBadgeHeaderColor(), width: 2),
              ),
              child: Column(
                children: [
                  // ID Header Band with Logo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _getBadgeHeaderColor(),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          _selectedCompany.logoPath,
                          height: 36,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.shield, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedCompany.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade200,
                          child: Icon(Icons.person, size: 50, color: _getBadgeHeaderColor()),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _nameController.text,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _roleController.text,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        Chip(
                          label: Text(
                            'Theme: $_selectedBadgeColor',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          backgroundColor: _getBadgeHeaderColor(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}