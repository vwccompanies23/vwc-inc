import 'package:flutter/material.dart';
import 'package:vwc_app/models/post.dart';
import 'package:vwc_app/models/contract.dart';
import 'package:vwc_app/features/home/home_screen.dart';
import 'package:vwc_app/features/admin/admin_dashboard_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized before using SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved posts and contract documents from persistent local storage
  await PostRepository.loadPosts();
  await ContractRepository.loadContracts();

  runApp(const VwcApp());
}

class VwcApp extends StatelessWidget {
  const VwcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VWC App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: Colors.red,
        ),
      ),
      home: const PasscodeScreen(),
    );
  }
}

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  static const String _workerPin = "2019";
  static const String _adminPin = "2026"; // Secret admin PIN

  String _enteredPin = "";

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
      });
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == _adminPin) {
      // Direct access to Admin Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else if (_enteredPin == _workerPin) {
      // Direct access to Worker Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect Secret Code'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _enteredPin = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.security, size: 70, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'VWC Access Control',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter secret code to proceed',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _enteredPin.length
                        ? Colors.red
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            const Spacer(),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 40),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) return const SizedBox.shrink();
                if (index == 10) return _buildKeypadButton('0');
                if (index == 11) {
                  return IconButton(
                    icon: const Icon(Icons.backspace, color: Colors.red),
                    onPressed: _onDelete,
                  );
                }
                return _buildKeypadButton('${index + 1}');
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String text) {
    return TextButton(
      onPressed: () => _onKeyPress(text),
      style: TextButton.styleFrom(
        shape: const CircleBorder(),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}