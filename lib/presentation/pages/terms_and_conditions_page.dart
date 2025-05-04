import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 50),
            Text(
              'Terms of Use and Conditions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: March 28, 2025',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFF7F7F7),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '1. Acceptance of Terms',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFFF7F7F7),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'By accessing and using our application, you agree to comply with these terms and conditions. '
              'If you do not agree with any of the terms, you must not use the application.',
              style: TextStyle(fontSize: 16, color: Color(0xFFF7F7F7),),
            ),
            SizedBox(height: 16),
            Text(
              '2. Use of the Application',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFFF7F7F7),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You agree to use this application only for legal purposes and in a way that does not infringe on the rights of other users. '
              'You must not use the application to distribute illegal content or promote illicit activities.',
              style: TextStyle(fontSize: 16, color: Color(0xFFF7F7F7),),
            ),
            SizedBox(height: 16),
            Text(
              '3. Privacy and Data Protection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF7F7F7),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your privacy is important to us. The collection and use of your personal data are governed by our Privacy Policy.',
              style: TextStyle(fontSize: 16, color: Color(0xFFF7F7F7),),
            ),
            SizedBox(height: 16),
            Text(
              '4. Changes to Terms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF7F7F7),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We reserve the right to modify these terms at any time. '
              'If there are significant changes, we will notify you through an update in the application.',
              style: TextStyle(fontSize: 16, color: Color(0xFFF7F7F7),),
            ),
            SizedBox(height: 16),
            Text(
              '5. Limitation of Liability',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF7F7F7),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We shall not be liable for any direct, indirect, or consequential damages resulting from the use of the application.',
              style: TextStyle(fontSize: 16, color: Color(0xFFF7F7F7),),
            ),
            SizedBox(height: 16),
            Text(
              '6. Contact',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFFF7F7F7),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'If you have any questions about these terms, you can contact us through the help section in the application.',
              style: TextStyle(fontSize: 16, color: Color(0xFFF7F7F7),),
            ),
            SizedBox(height: 24),
            Text(
              'By clicking "Accept," you confirm that you have read and accepted these terms and conditions.',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Color(0xFFF7F7F7),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            'Accept',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
