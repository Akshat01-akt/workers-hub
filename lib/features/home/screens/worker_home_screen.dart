import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:workers_hub/core/services/auth_service.dart';
import 'package:workers_hub/core/theme/app_theme.dart';
import 'package:workers_hub/features/home/widgets/job_card.dart';
import 'package:workers_hub/features/home/widgets/worker_profile_tab.dart';
import 'package:workers_hub/core/services/job_service.dart';
import 'package:workers_hub/features/home/screens/job_detail_screen.dart';
import 'package:workers_hub/core/services/message_service.dart';
import 'package:workers_hub/features/shared/screens/inbox_screen.dart';
import 'package:workers_hub/features/shared/screens/conversations_screen.dart';
import 'package:workers_hub/features/home/screens/saved_jobs_screen.dart';
import 'package:workers_hub/core/utils/app_snackbar.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

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
    final screens = [
      const _JobsTab(),
      const _ApplicationsTab(),
      const SavedJobsScreen(), // Tab 2: Saved Jobs
      const ConversationsScreen(), // Tab 3: Chat
      const WorkerProfileTab(), // Tab 4: Profile
    ];

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
          onPageChanged: (index) => setState(() => _currentIndex = index),
          physics: const BouncingScrollPhysics(),
          children: screens,
        ),
      ),
      bottomNavigationBar:
          NavigationBar(
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.work_outline),
                selectedIcon: Icon(Icons.work),
                label: 'Jobs',
              ),
              // Applications tab — shows unread badge for new status changes
              NavigationDestination(
                icon: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: JobService().getMyApplications(
                    AuthService().currentUser?.uid ?? '',
                  ),
                  builder: (context, snap) {
                    final newCount = (snap.data ?? [])
                        .where(
                          (a) =>
                              a['status'] == 'accepted' ||
                              a['status'] == 'rejected',
                        )
                        .where((a) => !(a['seen_by_worker'] ?? false))
                        .length;
                    return Badge.count(
                      count: newCount,
                      isLabelVisible: newCount > 0,
                      child: const Icon(Icons.description_outlined),
                    );
                  },
                ),
                selectedIcon: const Icon(Icons.description),
                label: 'Applications',
              ),
              // Saved Jobs
              const NavigationDestination(
                icon: Icon(Icons.bookmark_border),
                selectedIcon: Icon(Icons.bookmark),
                label: 'Saved',
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
          ).animate().slideY(
            begin: 1.0,
            duration: 500.ms,
            curve: Curves.easeOutQuart,
          ),
    );
  }
}

// ─── JOBS TAB ────────────────────────────────────────────────────────────────

class _JobsTab extends StatefulWidget {
  const _JobsTab();

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  double _minRate = 0;
  double _maxRate = 5000;

  static const List<String> _categories = [
    'Carpenter',
    'Electrician',
    'Plumber',
    'Mason',
    'Painter',
    'Welder',
    'Laborer',
    'Driver',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> jobs) {
    return jobs.where((job) {
      final title = (job['title'] ?? '').toString().toLowerCase();
      final location = (job['location'] ?? '').toString().toLowerCase();
      final company = (job['company_name'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final rate = (job['hourly_rate'] as num?)?.toDouble() ?? 0.0;
      final category = (job['category'] ?? '').toString();

      final matchesSearch =
          q.isEmpty ||
          title.contains(q) ||
          location.contains(q) ||
          company.contains(q);
      final matchesCategory =
          _selectedCategory == null || category == _selectedCategory;
      final matchesRate = rate >= _minRate && rate <= _maxRate;

      return matchesSearch && matchesCategory && matchesRate;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _selectedCategory != null || _minRate > 0 || _maxRate < 5000;

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _minRate = 0;
      _maxRate = 5000;
    });
  }

  void _showFilterSheet() {
    String? tempCategory = _selectedCategory;
    double tempMin = _minRate;
    double tempMax = _maxRate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Filters',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Category',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: tempCategory == null,
                    onSelected: (_) => setSheetState(() => tempCategory = null),
                  ),
                  ..._categories.map(
                    (c) => ChoiceChip(
                      label: Text(c),
                      selected: tempCategory == c,
                      onSelected: (_) => setSheetState(() => tempCategory = c),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hourly Rate',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${tempMin.toInt()} – ₹${tempMax.toInt()}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: RangeValues(tempMin, tempMax),
                min: 0,
                max: 5000,
                divisions: 50,
                labels: RangeLabels(
                  '₹${tempMin.toInt()}',
                  '₹${tempMax.toInt()}',
                ),
                onChanged: (v) => setSheetState(() {
                  tempMin = v.start;
                  tempMax = v.end;
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = tempCategory;
                      _minRate = tempMin;
                      _maxRate = tempMax;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search + Filter bar ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search jobs…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: _hasActiveFilters,
                child: IconButton.filled(
                  onPressed: _showFilterSheet,
                  style: IconButton.styleFrom(
                    backgroundColor: _hasActiveFilters
                        ? AppTheme.primaryColor
                        : Colors.grey.shade200,
                    foregroundColor: _hasActiveFilters
                        ? Colors.black
                        : Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.tune),
                ),
              ),
            ],
          ),
        ),

        // ── Active filter chips ──────────────────────────────────────
        if (_hasActiveFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                if (_selectedCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(_selectedCategory!),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() => _selectedCategory = null),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (_minRate > 0 || _maxRate < 5000)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(
                        '₹${_minRate.toInt()}–₹${_maxRate.toInt()}/hr',
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() {
                        _minRate = 0;
                        _maxRate = 5000;
                      }),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),

        // ── Jobs list ────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: JobService().getJobs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final allJobs = snapshot.data ?? [];
              final filtered = _applyFilters(allJobs);

              if (allJobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_off_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No jobs posted yet.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No jobs match your filters.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear Filters'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Streams auto-refresh; this just gives tactile feedback
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final job = filtered[index];
                    final jobId = job['id'] as String;

                    return JobCard(
                          jobId: jobId,
                          title: job['title'] ?? 'No Title',
                          contractorName: job['company_name'] ?? 'Unknown',
                          location: job['location'] ?? 'Remote',
                          hourlyRate:
                              (job['hourly_rate'] as num?)?.toDouble() ?? 0.0,
                          timePosted: 'Recently',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    JobDetailScreen(jobId: jobId, jobData: job),
                              ),
                            );
                          },
                          onApply: () async {
                            final user = AuthService().currentUser;
                            if (user == null) return;
                            try {
                              await JobService().applyForJob(
                                jobId: jobId,
                                workerId: user.uid,
                                jobData: job,
                              );
                              if (context.mounted) {
                                AppSnackbar.show(
                                  context,
                                  'Application submitted!',
                                  type: SnackType.success,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackbar.show(
                                  context,
                                  e.toString().replaceFirst('Exception: ', ''),
                                  type: SnackType.error,
                                );
                              }
                            }
                          },
                        )
                        .animate()
                        .fadeIn(delay: (index * 60).ms)
                        .slideY(begin: 0.08);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── APPLICATIONS TAB ─────────────────────────────────────────────────────────

class _ApplicationsTab extends StatelessWidget {
  const _ApplicationsTab();

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: JobService().getMyApplications(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final apps = snapshot.data ?? [];

        if (apps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No applications yet.',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              await Future.delayed(const Duration(milliseconds: 500)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              final status = app['status'] ?? 'pending';
              final isNew =
                  (status == 'accepted' || status == 'rejected') &&
                  !(app['seen_by_worker'] ?? false);

              return _ApplicationCard(
                app: app,
                status: status,
                isNew: isNew,
              ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.06);
            },
          ),
        );
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> app;
  final String status;
  final bool isNew;

  const _ApplicationCard({
    required this.app,
    required this.status,
    required this.isNew,
  });

  Color _statusColor() {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon() {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isNew
            ? Border.all(color: _statusColor(), width: 2)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: isNew
                ? _statusColor().withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _statusColor().withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(), color: _statusColor()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        app['job_title'] ?? 'Unknown Job',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  app['company_name'] ?? 'Unknown company',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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
