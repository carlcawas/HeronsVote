import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F2D7), 
      body: Center(
        child: Shimmer.fromColors(
          baseColor: const Color(0xFF354372),
          highlightColor: Colors.white, 
          
          period: const Duration(seconds: 1),
          
          child: Hero(
            tag: 'appLogo',
            child: Image.asset(
              'assets/HeronVoteLogo.png',
              width: 70,
            ),
          ),
        ),
      ),
    );
  }
}
