// lib/Screens/privacy_policy_page.dart
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff7DBF75),
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Information We Collect'),
            _buildSectionContent(
              'We collect only the essential information required to process your orders and provide our services. This includes your name, phone number, panchayath, and ward details. This information is solely used for order processing, delivery, and customer service purposes.'
            ),
            
            _buildSectionTitle('How We Use Your Information'),
            _buildSectionContent(
              'Your personal information is used exclusively for order fulfillment, delivery coordination, and customer support. We maintain your data securely and do not use it for any marketing purposes without your explicit consent. Your panchayath and ward details help us organize efficient delivery services within your locality.'
            ),
            
            _buildSectionTitle('Data Protection'),
            _buildSectionContent(
              'We implement appropriate security measures to protect your personal information from unauthorized access or disclosure. Your data is stored securely and accessed only by authorized personnel for order processing purposes. We do not share your personal information with third parties except as required for order delivery.'
            ),
            
            _buildSectionTitle('Your Rights'),
            _buildSectionContent(
              'You have the right to access, correct, or request deletion of your personal information at any time. You can also contact us to understand how your data is being used. We are committed to maintaining the accuracy and confidentiality of your information.'
            ),
            
            _buildSectionTitle('Contact Us'),
            _buildSectionContent(
              'If you have any questions or concerns about our privacy practices or how we handle your personal information, please contact us through our customer support channels.'
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xff7DBF75),
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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