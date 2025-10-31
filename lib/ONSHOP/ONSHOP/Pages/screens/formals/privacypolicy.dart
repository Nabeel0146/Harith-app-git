import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color.fromARGB(255, 255, 185, 41),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy for OnShop App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Effective Date: 31/12/2024',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            const Text(
              'OnShop (“we,” “our,” “us”) operates as a shop listing application designed to provide users with a convenient way to discover shops and businesses in their nearby locations. Protecting your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information when you use the OnShop app.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('1. Information We Collect'),
            _buildSubSection(
              'a. Location Information',
              'Purpose: To display shops near your chosen location.\n\nHow: You can manually select a location in the app; your GPS location is not accessed or tracked.',
            ),
            _buildSubSection(
              'b. Personal Information',
              'If you sign up or create an account, we may collect your name and phone number.',
            ),
            _buildSubSection(
              'c. Device Information',
              'We may collect technical information about your device, such as its type, operating system, and app version, to ensure compatibility and app functionality.',
            ),
            _buildSubSection(
              'd. Usage Data',
              'We collect data about how you interact with the app, including pages viewed, search queries, and clicks, to improve user experience and app performance.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('2. How We Use Your Information'),
            const Text(
              '• To provide and improve our app services.\n'
              '• To display relevant shop listings based on your chosen or current location.\n'
              '• To send updates, notifications, and promotional offers if you opt-in.\n'
              '• To analyze app usage and trends for app enhancements.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('3. Information Sharing and Disclosure'),
            const Text(
              'We do not sell or rent your personal information to third parties. However, we may share your information in the following scenarios:',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text(
              '• With Service Providers: To support app functionality, such as analytics tools.\n'
              '• For Legal Obligations: If required by law or to protect our legal rights.\n'
              '• With Your Consent: If you explicitly agree to share your information for specific purposes.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('4. Data Security'),
            const Text(
              'We implement appropriate technical and organizational measures to protect your data from unauthorized access, disclosure, or misuse. However, no system is completely secure, and we cannot guarantee absolute security.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('5. Your Choices'),
            const Text(
              '• Account Information: You can update or delete your account information by contacting us.\n'
              '• Opt-Out: You can opt-out of promotional communications at any time by using the unsubscribe option provided in such communications.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('6. Third-Party Links'),
            const Text(
              'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these external sites.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('7. Children’s Privacy'),
            const Text(
              'OnShop is not intended for individuals under the age of 13. We do not knowingly collect personal information from children.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('8. Changes to This Privacy Policy'),
            const Text(
              'We may update this Privacy Policy from time to time. Any changes will be reflected here with the updated effective date. We encourage you to review this policy periodically.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('9. Contact Us'),
            const Text(
              'If you have any questions or concerns about this Privacy Policy, please contact us:',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Email: onshoponahop59@gmail.com\n'
              '• Phone: 8138878717',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Thank you for trusting OnShop. We are committed to protecting your privacy and providing you with a secure and reliable app experience.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSubSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}