import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteAccountPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteAccount(BuildContext context) async {
    final User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete the user account from Firebase Authentication
        await user.delete();

        // Sign out the user after account deletion
        await _auth.signOut();

        // Show success popup and redirect to registration page
        _showSuccessDialog(context);
      } on FirebaseAuthException catch (e) {
        // Handle errors related to Firebase Authentication
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please re-authenticate and try again. Login again to proceed.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Handle other unexpected errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user is currently signed in.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Account Deleted'),
          content: const Text(
            'Your account has been successfully deleted. You will need to Register on your next app opening.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                Navigator.of(context).pushReplacementNamed('/register');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        backgroundColor: const Color.fromARGB(255, 255, 185, 41),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => _deleteAccount(context),
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }
}