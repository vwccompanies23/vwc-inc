import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vwc_app/features/auth/passcode_screen.dart';
import 'package:vwc_app/features/signing/signer_details_screen.dart';

// If you have firebase_options.dart, make sure it's imported:
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure we don't crash or hang if already initialized
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        // If you generated firebase_options.dart, uncomment below:
        // options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }

  runApp(const VwcApp());
}

class VwcApp extends StatelessWidget {
  const VwcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VWC INC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
      ),
      onGenerateRoute: (settings) {
        String routeName = settings.name ?? '';

        // Handle web deep links including hash fragments
        if (routeName == '/' || routeName.isEmpty) {
          final uri = Uri.base;
          if (uri.path.contains('/sign') || uri.fragment.contains('/sign')) {
            routeName = uri.path.contains('/sign')
                ? uri.path + (uri.query.isNotEmpty ? '?' + uri.query : '')
                : uri.fragment;
          }
        }

        if (routeName.contains('/sign')) {
          Uri uri;
          if (routeName.startsWith('http')) {
            uri = Uri.parse(routeName);
          } else {
            final cleanRoute = routeName.startsWith('/') ? routeName : '/$routeName';
            uri = Uri.parse('https://dummy.com$cleanRoute');
          }

          final queryParameters = uri.queryParameters.isNotEmpty
              ? uri.queryParameters
              : Uri.parse(routeName.replaceFirst('#', '?')).queryParameters;

          final docId = queryParameters['docId'] ?? '';
          final docTitle = queryParameters['docTitle'] ?? 'Contract Document';
          final company = queryParameters['company'] ?? 'VWC Operations';
          final requiredCode = queryParameters['code'] ?? '';
          final urlsString = queryParameters['urls'] ?? '';
          final pageUrls = urlsString.isNotEmpty ? urlsString.split(',') : <String>[];

          return MaterialPageRoute(
            builder: (context) => SignerDetailsScreen(
              docId: Uri.decodeComponent(docId),
              docTitle: Uri.decodeComponent(docTitle),
              company: Uri.decodeComponent(company),
              requiredCode: requiredCode,
              pageUrls: pageUrls.map((u) => Uri.decodeComponent(u)).toList(),
            ),
          );
        }

        // Default admin/worker passcode login entry
        return MaterialPageRoute(
          builder: (context) => const PasscodeScreen(),
        );
      },
    );
  }
}