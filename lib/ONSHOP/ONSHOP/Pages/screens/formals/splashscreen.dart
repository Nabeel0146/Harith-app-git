// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:harithagramam/1SCREENS/ONSHOP/Pages/mainscree.dart';
// import 'package:harithagramam/AUTH/auth.dart';


// class SplashScreen extends StatefulWidget {
//   final FirebaseApp secondApp; // ✅ accept it here
//   const SplashScreen({super.key, required this.secondApp});

//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
//   late AnimationController _slideController;
//   late Animation<Offset> _slideAnimation;
//   late AnimationController _fadeController;
//   late Animation<double> _fadeAnimation;
//   late AnimationController _zoomController;
//   late Animation<double> _zoomAnimation;

//   @override
//   void initState() {
//     super.initState();

//     // Initialize slide animation controller
//     _slideController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );

//     // Create slide animation from bottom to center
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0.0, 1.0), // Start from the bottom
//       end: Offset.zero,              // End at the center
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeInOut,
//     ));

//     // Initialize fade animation controller
//     _fadeController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 1),
//     );

//     // Create fade animation
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeInOut,
//     ));

//     // Initialize zoom animation controller
//     _zoomController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     // Create zoom animation
//     _zoomAnimation = Tween<double>(
//       begin: 1.0,
//       end: 50.5,
//     ).animate(CurvedAnimation(
//       parent: _zoomController,
//       curve: Curves.easeInOut,
//     ));

//     // Start animations immediately
//     _slideController.forward();
//     _fadeController.forward();

//     // Initialize Firebase and check login status
//     _initializeApp();
//   }

//   Future<void> _initializeApp() async {
//     try {
//       // Ensure Firebase is initialized
//       await Firebase.initializeApp();

//       // Check user login status after a delay
//       Timer(Duration(seconds: 3), _checkUserLoginStatus);
//     } catch (e) {
//       // Handle Firebase initialization error
//       print('Firebase initialization error: $e');
//       _showErrorDialog();
//     }
//   }

//   void _checkUserLoginStatus() {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       // Start zoom animation before navigating to HomePage
//       _zoomController.forward().whenComplete(() {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => MainScreen()),
//         );
//       });
//     } else {
//       // Start zoom animation before navigating to RegisterPage
//       _zoomController.forward().whenComplete(() {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => RegisterPage(secondApp: widget.secondApp,)),
//         );
//       });
//     }
//   }

//   void _showErrorDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Error'),
//         content: Text('Failed to initialize Firebase. Please try again later.'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             child: Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _slideController.dispose();
//     _fadeController.dispose();
//     _zoomController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage('asset/8880783.jpg'), // Replace with your background image asset path
//             fit: BoxFit.fitHeight,
//           ),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               SlideTransition(
//                 position: _slideAnimation,
//                 child: FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: ScaleTransition(
//                     scale: _zoomAnimation,
//                     child: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(26),
//                       ),
//                       child: Column(
//                         children: [
//                           Image.asset(
//                             'asset/onshopcurvedlogo.jpg', // Logo image
//                             width: 200,
//                             height: 200,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }