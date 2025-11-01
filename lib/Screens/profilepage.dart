import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harithapp/Auth/register.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  // Sign out function
  // Alternative approach if you don't use named routes
Future<void> _signOut(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    // Navigate to register page and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()), // Your register screen widget
      (route) => false,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error signing out: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // Confirm sign out dialog
  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _signOut(context); // Perform sign out
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: const Color(0xff7DBF75),
        title: const Text("My Profile"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('harith-users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          // Get user data from Firestore
          String userName = "User";
          String phoneNumber = "Not provided";
          bool hasMembership = false;
          String? membershipId;
          
          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            
            // Get user name and mobile
            userName = userData?['fullName'] as String? ?? "User";
            phoneNumber = userData?['mobile'] as String? ?? "Not provided";
            
            // Check membership - FIXED: Use the correct field name
            membershipId = userData?['membershipId'] as String?; // Make sure this matches your Firestore field name exactly
            hasMembership = membershipId != null && membershipId.isNotEmpty;
            
            // Debug print to check what's happening
            print('User: $userName, Membership ID: $membershipId, Has Membership: $hasMembership');
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 15),

                /// ✅ Membership Card Container - Only show if user has membership
                if (hasMembership)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.asset(
                              "assets/harithmembershipcard.jpg",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xff7DBF75),
                                        const Color(0xff5A9D55),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.card_membership,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Membership ID overlay
                            if (membershipId != null)
                              Positioned(
                                bottom: 78,
                                left: 32,
                                child: Text(
                                    '$membershipId',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // Show message if no membership
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.card_membership_outlined,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No Membership Card',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Apply for Harithagramam membership to get your card',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              _applyForMembership(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff7DBF75),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Apply for Membership'),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 15),

                /// ✅ Name + Number Container - Now shows dynamic user data
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/harithagramamlogowhite.png",
                        height: 30,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            phoneNumber,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// ✅ Menu Items
                _menuTile("Privacy Policy", Icons.privacy_tip_outlined, context: context),
                _divider(),
                _menuTile("Terms & Conditions", Icons.description_outlined, context: context),
                _divider(),
                _menuTile("Help", Icons.help_outline, context: context),
                _divider(),
                _menuTile("Support", Icons.support_agent_outlined, context: context),
                _divider(),

                /// ✅ Sign Out (Red) - Now functional
                _menuTile("Sign out", Icons.logout, isLogout: true, context: context),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _menuTile(String title, IconData icon, {bool isLogout = false, required BuildContext context}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : const Color(0xff7DBF75),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isLogout ? Colors.red : Colors.black,
          fontWeight: isLogout ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isLogout ? Colors.red : Colors.black54,
      ),
      onTap: () {
        if (isLogout) {
          _confirmSignOut(context);
        } else {
          // TODO: Navigation for other menu items
          // You can implement navigation for other menu items here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title feature coming soon!'),
            ),
          );
        }
      },
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(left: 72),
      child: Divider(height: 0.5, color: Colors.grey),
    );
  }

  void _applyForMembership(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply for Membership'),
        content: const Text(
            'Contact Harithagramam support to apply for membership. You will receive your membership card after approval.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}