import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:workers_hub/features/onboarding/onboarding_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workers_hub/features/auth/screens/role_based_home.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // 1. Start the minimum duration timer
    final minDurationFuture = Future.delayed(const Duration(seconds: 4));

    // 2. Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // Fallback for initialization error or if already initialized
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
      } catch (e2) {
        debugPrint('Firebase init failed: $e2');
      }
    }

    // 3. Wait for the minimum duration to ensure splash is seen
    await minDurationFuture;

    if (!mounted) return;

    // 4. Check Auth State and Navigate
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const RoleBasedHome(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
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
