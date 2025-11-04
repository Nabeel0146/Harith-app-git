import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:harithapp/Auth/register.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Create fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Create scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Start the animation sequence
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    // Start the fade-in and scale animation
    await _animationController.forward();

    // Wait for a moment at full opacity
    await Future.delayed(const Duration(milliseconds: 1000));

    // Start fade-out animation
    await _animationController.reverse();

    // Navigate after animation completes
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    final creds = await FirebaseAuth.instance.signInAnonymously();
    final uid = creds.user!.uid;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RegisterPage()),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Image.asset(
            'assets/harithagramamlogogreen.png',
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }
}