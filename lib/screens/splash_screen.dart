import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:yoklama_sistemi/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final List<Color> _randomColors = [
    const Color(0xFF5C6BC0),
    const Color(0xFF3F51B5),
    const Color(0xFF1976D2),
    const Color(0xFF2196F3),
    const Color(0xFF03A9F4),
  ];

  late Color _bgColor;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _bgColor = _getRandomColor();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  Color _getRandomColor() {
    final random = Random();
    return _randomColors[random.nextInt(_randomColors.length)];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            ScaleTransition(
              scale: _animation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school,
                  size: 80,
                  color: _bgColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Animated Text
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'YOKLAMA SİSTEMİ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Slogan text
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'Kolay ve Güvenilir Yoklama',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
