// lib/Screens/force_update_screen.dart
import 'package:flutter/material.dart';
import 'package:harithapp/models/app_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class ForceUpdateScreen extends StatelessWidget {
  final AppInfo appInfo;

  const ForceUpdateScreen({
    super.key,
    required this.appInfo,
  });

  Future<void> _launchStore() async {
    try {
      if (Platform.isIOS) {
        if (await canLaunchUrl(Uri.parse(appInfo.appstoreUrl))) {
          await launchUrl(Uri.parse(appInfo.appstoreUrl));
        }
      } else if (Platform.isAndroid) {
        if (await canLaunchUrl(Uri.parse(appInfo.playstoreUrl))) {
          await launchUrl(Uri.parse(appInfo.playstoreUrl));
        }
      }
    } catch (e) {
      print('Error launching store: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon/Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 116, 190, 119),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.system_update,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Update Available',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Simple message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Please update the app for a better experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Store Icon with platform info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Platform.isIOS ? Icons.apple : Icons.android,
                        size: 48,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Platform.isIOS ? 'App Store' : 'Google Play Store',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _launchStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 116, 190, 119),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Update Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Optional: Only show "Maybe Later" if not forced update
                if (!appInfo.forceUpdate) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Not Now',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
                
                // Forced update note (subtle)
                if (appInfo.forceUpdate)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      'Update is required to continue using the app',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}