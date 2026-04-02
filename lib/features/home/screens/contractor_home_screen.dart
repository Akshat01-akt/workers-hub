import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:workers_hub/features/home/widgets/contractor_home_tab.dart';
import 'package:workers_hub/features/home/screens/my_posted_jobs_screen.dart';
import 'package:workers_hub/features/home/screens/contractor_profile_screen.dart';
import 'package:workers_hub/features/home/screens/post_job_screen.dart';
import 'package:workers_hub/features/home/screens/all_applicants_screen.dart';
import 'package:workers_hub/features/shared/screens/inbox_screen.dart';
import 'package:workers_hub/features/shared/screens/conversations_screen.dart';
import 'package:workers_hub/core/services/message_service.dart';

class ContractorHomeScreen extends StatefulWidget {
  const ContractorHomeScreen({super.key});

  @override
  State<ContractorHomeScreen> createState() => _ContractorHomeScreenState();
}

class _ContractorHomeScreenState extends State<ContractorHomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = [
    const ContractorHomeTab(),
    const MyPostedJobsScreen(),
    const AllApplicantsScreen(),
    const ConversationsScreen(),
    const ContractorProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers Hub'),
        actions: [
          StreamBuilder<int>(
            stream: MessageService().getUnreadCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InboxScreen(),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ).animate().scale(),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          physics: const BouncingScrollPhysics(),
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          // If index is 1 (Post Job center item - wait, actually design requested center tab for listing OR posting?)
          // User requested: "provide the job listing options in form of center tab in bottom navigation bar to list the job and requirements"
          // This implies the center tab should OPEN the form to post a job?
          // "list the job" might mean "post a job listing". Let's assume it means "Post a Job".
          // However, standard nav bar behavior switches tabs.
          // Let's make the center tab "My Jobs" and add a Floating Action Button for "Post Job"?
          // OR make the center tab distinct.
          // Let's stick to standard tabs: Home, My Jobs, Profile. And add a persistent FAB for "Post Job".
          // BUT request said "in the home screen provide the job listing options in form of center tab... to list the job".
          // This sounds like the center tab SHOULD BE "Post Job" or "My Jobs".
          // Let's make the center tab "My Jobs" and put a "Post Job" button INSIDE "My Jobs" screen?
          // OR make the center tab "Post Job" directly?
          // Let's go with:
          // 0: Home (Find Workers)
          // 1: Center Tab -> My Jobs (which has a big "Post Job" button) OR directly Post Job?
          // "list the job and requirements of workers... reflected in the my jobs screen".
          // So center tab = "Post Job" action?
          // Let's Try: Center Tab is "My Jobs". Inside "My Jobs", there is a button to "Post Job".
          // And maybe a FAB on Home screen too?

          // Re-reading: "provide the job listing options in form of center tab... to list the job... reflected in the my jobs screen".
          // This is slightly ambiguous.
          // Interpretation: Center tab = "My Jobs".
          // Let's update the destinations.

          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_add),
            selectedIcon: Icon(Icons.assignment),
            label: 'My Jobs',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Applicants',
          ),
          // Chat tab with unread badge
          NavigationDestination(
            icon: StreamBuilder<int>(
              stream: MessageService().getUnreadCount(),
              builder: (context, snap) {
                final count = snap.data ?? 0;
                return Badge.count(
                  count: count,
                  isLabelVisible: count > 0,
                  child: const Icon(Icons.chat_bubble_outline),
                );
              },
            ),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ).animate().slideY(begin: 1.0, duration: 500.ms, curve: Curves.easeOutQuart),
      floatingActionButton:
          _currentIndex ==
              1 // Show FAB only on My Jobs tab? Or always?
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostJobScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Post Job'),
            ).animate().scale()
          : null,
    );
  }
}
