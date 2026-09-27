import 'package:flutter/material.dart';

import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fixed to the light Ledger palette regardless of system theme, since
      // MARK.png bakes its own warm-paper background into the asset.
      backgroundColor: const Color(0xFFEFE9DD),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/MARK.png', width: 320),
            const SizedBox(height: 8),
            const Text(
              'Archery Scorecard',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
                color: Color(0xFF5A5346),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
