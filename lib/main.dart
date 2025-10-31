import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:harithapp/Auth/splashscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth Demo',
      theme: ThemeData(useMaterial3: true),
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}