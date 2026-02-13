import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:workers_hub/features/auth/screens/sign_in_screen.dart';
import 'package:workers_hub/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Find Work,\nGet Paid',
      'subtitle':
          'Connect with contractors looking for your skills. Fair pricing, guaranteed work.',
      'icon': Icons.handyman_rounded,
      'color': AppTheme.primaryColor,
    },
    {
      'title': 'Hire Skilled\nLabor Fast',
      'subtitle':
          'Post your requirements and find verified masons, carpenters, and laborers in minutes.',
      'icon': Icons.engineering_rounded,
      'color': AppTheme.secondaryColor,
    },
    {
      'title': 'Seamless\nConstruction',
      'subtitle':
          'Manage your projects and workforce efficiently. Building better, together.',
      'icon': Icons.apartment_rounded,
      'color': AppTheme.accentColor,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Color Transition
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: _pages[_currentPage]['color'].withOpacity(0.1),
            width: double.infinity,
            height: double.infinity,
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon / Illustration Placeholder
                            Center(
                              child:
                                  Container(
                                        padding: const EdgeInsets.all(40),
                                        decoration: BoxDecoration(
                                          color: (page['color'] as Color)
                                              .withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          page['icon'],
                                          size: 100,
                                          color: page['color'],
                                        ),
                                      )
                                      .animate()
                                      .scale(
                                        duration: 600.ms,
                                        curve: Curves.easeOutBack,
                                      )
                                      .fade(duration: 600.ms),
                            ),
                            const Spacer(),
                            // Title
                            Text(
                                  page['title'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        height: 1.1,
                                        color: Colors.black87,
                                      ),
                                )
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 600.ms)
                                .moveX(begin: -20, end: 0, delay: 200.ms),

                            const SizedBox(height: 16),

                            // Subtitle
                            Text(
                                  page['subtitle'],
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.black54,
                                        height: 1.4,
                                      ),
                                )
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 600.ms)
                                .moveX(begin: -20, end: 0, delay: 400.ms),
                            const Spacer(),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Controls
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page Indicators
                        Row(
                          children: List.generate(
                            _pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 8),
                              height: 8,
                              width: _currentPage == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? _pages[_currentPage]['color']
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        // Next / Get Started Button
                        ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              // Navigate to Auth/Home (Not implemented yet)
                              // For now just show a snackbar or print
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignInScreen(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentPage]['color'],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Row(
                              key: ValueKey(_currentPage == _pages.length - 1),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Get Started'
                                      : 'Next',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                if (_currentPage != _pages.length - 1)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
