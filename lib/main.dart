import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harithapp/Screens/FORCE_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:harithapp/Auth/splashscreen.dart';
import 'package:harithapp/models/app_info.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harithagramam',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color.fromARGB(255, 116, 190, 119),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 116, 190, 119),
        ),
      ),
      home: const VersionCheckWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VersionCheckWrapper extends StatefulWidget {
  const VersionCheckWrapper({super.key});

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  bool _isChecking = true;
  bool _updateRequired = false;
  AppInfo? _appInfo;
  String? _currentVersion;

  @override
  void initState() {
    super.initState();
    _checkAppVersion();
  }

 Future<void> _checkAppVersion() async {
  try {
    // Get current app version
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    
    print('Current app version: $currentVersion');
    
    // Fetch app settings from Firestore
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection('harith-settings').doc('app_settings').get();
    
    print('Firestore document exists: ${doc.exists}');
    
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      print('Firestore data: $data');
      
      final appInfo = AppInfo.fromMap(data);
      
      print('Parsed appInfo:');
      print('- minimumVersion: ${appInfo.minimumVersion}');
      print('- forceUpdate: ${appInfo.forceUpdate}');
      print('- appstoreUrl: ${appInfo.appstoreUrl}');
      print('- playstoreUrl: ${appInfo.playstoreUrl}');
      
      // Check if update is required
      final updateRequired = appInfo.isUpdateRequired(currentVersion);
      print('Update required? $updateRequired');
      
      setState(() {
        _currentVersion = currentVersion;
        _appInfo = appInfo;
        _updateRequired = updateRequired;
        _isChecking = false;
      });
    } else {
      // If no settings found, continue to app
      print('No app_settings document found in Firestore');
      setState(() {
        _isChecking = false;
        _updateRequired = false;
      });
    }
  } catch (e) {
    print('Error checking version: $e');
    // If there's an error, continue to app
    setState(() {
      _isChecking = false;
      _updateRequired = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color.fromARGB(255, 116, 190, 119),
              ),
              SizedBox(height: 20),
              Text(
                'Checking for updates...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

   // In main.dart, update this part:
if (_updateRequired && _appInfo != null && _currentVersion != null) {
  return ForceUpdateScreen(
    appInfo: _appInfo!, // Don't need to pass currentVersion anymore
  );
}

    return const SplashPage();
  }
}