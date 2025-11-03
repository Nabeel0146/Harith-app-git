// lib/Screens/terms_conditions_page.dart
import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff7DBF75),
        title: const Text('Terms & Conditions'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionContent(
              'By using Harithagramam App, you agree to these terms. This app allows you to browse products and place orders for delivery within your panchayath. All products shown are subject to availability and we reserve the right to modify product listings without prior notice. You are responsible for providing accurate delivery information including your name, phone number, panchayath, and ward details for successful order fulfillment. The app content is protected by copyright and may not be reproduced without permission. We may update these terms periodically, and continued use of the app constitutes acceptance of any changes.'
            ),
            
            const SizedBox(height: 20),
            Text(
              'Last updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 16),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }
}