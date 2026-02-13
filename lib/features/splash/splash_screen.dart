import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:workers_hub/features/onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }
  Future<void> _navigateToOnboarding() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Icon (Using a placeholder icon for now, construction related)
            Icon(Icons.engineering_rounded, size: 100, color: Colors.black)
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .then(delay: 200.ms)
                .shimmer(
                  duration: 1200.ms,
                  color: Colors.white.withOpacity(0.5),
                ),

            const SizedBox(height: 24),

            // App Name
            Text(
                  'Workers Hub',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                )
                .animate()
                .fadeIn(delay: 500.ms, duration: 600.ms)
                .moveY(begin: 20, end: 0, delay: 500.ms, curve: Curves.easeOut),

            const SizedBox(height: 8),

            Text(
              'Connecting Hands, Building Dreams',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
