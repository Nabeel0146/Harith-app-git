// lib/Screens/support_page.dart
import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff7DBF75),
        title: const Text('Customer Support'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionContent(
              'For any assistance with orders, product inquiries, or technical support, please contact our customer care team. Our support staff is available to help you with order tracking, delivery questions, product information, and any issues you may encounter while using the Harithagramam app.'
            ),
            
            _buildSectionContent(
              'We are committed to providing you with the best possible service and ensuring your shopping experience is smooth and satisfactory. If you need help with your account, have questions about our products, or require assistance with an order, our team is here to support you.'
            ),

            const SizedBox(height: 25),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff7DBF75).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff7DBF75),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Phone: +91 81388 78717',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
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