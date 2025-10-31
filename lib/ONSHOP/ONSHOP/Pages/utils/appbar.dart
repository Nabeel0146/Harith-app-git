import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> cities;
  final String? selectedCity;
  final ValueChanged<String?>? onCityChanged;

  CustomAppBar({
    required this.cities,
    required this.selectedCity,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GradientAppBar(
      child: AppBarContent(
        cities: cities,
        selectedCity: selectedCity,
        onCityChanged: onCityChanged,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}

class GradientAppBar extends StatelessWidget {
  final Widget child;

  GradientAppBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 255, 185, 41), // Orange
            Colors.white, // White
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

class AppBarContent extends StatelessWidget {
  final List<String> cities;
  final String? selectedCity;
  final ValueChanged<String?>? onCityChanged;

  AppBarContent({
    required this.cities,
    required this.selectedCity,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return AppBar(
      backgroundColor: Colors.transparent, // Make the AppBar background transparent
      elevation: 0, // Remove the shadow
      toolbarHeight: 100,
      flexibleSpace: Padding(
        padding: const EdgeInsets.only(top: 35),
        child: Row(
          children: [
            const SizedBox(width: 46),
            ClipRRect(
              child: Image.asset(
                "assets/onshopnewcurvedlogo.png",
                width: 60,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: userId != null
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .snapshots()
                    : null,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 100,
                            height: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 150,
                            height: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Text(
                      "Error loading data",
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text(
                      "User Not Found",
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  final userName = userData?['name'] as String? ?? 'Guest';
                  final cardNo = userData?['cardno'] as String? ??
                      "Contact Us to get the discount card!";

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hello!",
                        style: TextStyle(color: Colors.black),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        cardNo?.isNotEmpty == true
                            ? 'Card No: $cardNo'
                            : "Contact Us to get the discount card!",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: cardNo?.isNotEmpty == true ? 13 : 10, // Set fontSize based on cardNo
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}