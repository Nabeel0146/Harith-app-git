// lib/models/app_info.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppInfo {
  final String minimumVersion;
  final String appstoreUrl;
  final String playstoreUrl;
  final bool forceUpdate;
  final Timestamp? updatedAt;
  final String? currentVersion;

  AppInfo({
    required this.minimumVersion,
    required this.appstoreUrl,
    required this.playstoreUrl,
    required this.forceUpdate,
    this.updatedAt,
    this.currentVersion,
  });

  factory AppInfo.fromMap(Map<String, dynamic> data) {
    return AppInfo(
      minimumVersion: _cleanVersionString(data['minimumVersion']?.toString() ?? '1.0.0'),
      appstoreUrl: data['appstoreUrl']?.toString() ?? '',
      playstoreUrl: data['playstoreUrl']?.toString() ?? '',
      forceUpdate: data['forceUpdate'] == true,
      updatedAt: data['updatedAt'] as Timestamp?,
      currentVersion: data['currentVersion']?.toString(),
    );
  }

  static String _cleanVersionString(String version) {
    // Remove extra quotes if present
    return version.replaceAll(RegExp(r'"'), '').trim();
  }

  // Method to check if update is required
  bool isUpdateRequired(String currentAppVersion) {
    try {
      final currentClean = _cleanVersionString(currentAppVersion);
      final minClean = _cleanVersionString(minimumVersion);
      
      print('Comparing versions:');
      print('- Current (cleaned): $currentClean');
      print('- Minimum (cleaned): $minClean');
      
      final currentParts = _parseVersion(currentClean);
      final minParts = _parseVersion(minClean);
      
      print('- Current parts: $currentParts');
      print('- Minimum parts: $minParts');
      
      // Compare major, minor, patch versions
      for (int i = 0; i < 3; i++) {
        if (currentParts[i] < minParts[i]) {
          print('Update required: Part $i - ${currentParts[i]} < ${minParts[i]}');
          return true;
        } else if (currentParts[i] > minParts[i]) {
          print('No update needed: Part $i - ${currentParts[i]} > ${minParts[i]}');
          return false;
        }
      }
      print('Versions are equal, no update needed');
      return false; // Versions are equal
    } catch (e) {
      print('Error comparing versions: $e');
      return false; // If error, don't force update
    }
  }

  List<int> _parseVersion(String version) {
    try {
      // Extract version numbers using regex
      final regex = RegExp(r'(\d+)\.(\d+)\.(\d+)');
      final match = regex.firstMatch(version);
      
      if (match != null) {
        return [
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        ];
      }
      
      // Fallback: split by dots and parse
      final parts = version.split('.');
      return [
        int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
        int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
        int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
      ];
    } catch (e) {
      print('Error parsing version $version: $e');
      return [0, 0, 0];
    }
  }
}