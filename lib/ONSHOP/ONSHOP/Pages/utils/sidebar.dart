import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/formals/aboutpage.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/formals/deleteaccount.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/formals/privacypolicy.dart';

class Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 255, 185, 41),
            ),
            child: user != null
                ? StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Text(
                          'Error fetching user name',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        );
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text(
                          'Welcome, Guest',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        );
                      }

                      final userName = snapshot.data!.get('name') ?? 'No Name Found!';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome!',
                            style:
                                TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Name: $userName',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      );
                    },
                  )
                : const Text(
                    'No User Found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.video_collection_rounded),
            title: const Text('Video Demo'),
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => HowToUsePage()),
              // );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About OnShop'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Account'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeleteAccountPage()),
              );
            },
          ),
          
        ],
      ),
    );
  }
}