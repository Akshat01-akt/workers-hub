import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workers_hub/core/services/job_service.dart';
import 'package:workers_hub/core/services/auth_service.dart';
import 'package:workers_hub/core/theme/app_theme.dart';
import 'package:workers_hub/core/utils/app_snackbar.dart';
import 'package:workers_hub/features/home/widgets/job_map_widget.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const JobDetailScreen({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isApplying = false;

  Future<void> _apply() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _isApplying = true);

    try {
      await JobService().applyForJob(
        jobId: widget.jobId,
        workerId: user.uid,
        jobData: widget.jobData,
      );
      if (mounted) {
        AppSnackbar.show(
          context,
          'Application submitted successfully!',
          type: SnackType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          type: SnackType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        AppSnackbar.show(
          context,
          'Cannot place call on this device',
          type: SnackType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.jobData;
    final contractorPhone = job['contractor_phone'] as String?;
    final lat = (job['lat'] as num?)?.toDouble();
    final lng = (job['lng'] as num?)?.toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  job['title'] ?? 'No Title',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  job['company_name'] ?? 'Unknown Company',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                // Key Detail Chips
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildDetailChip(
                      Icons.location_on,
                      job['location'] ?? 'Remote',
                    ),
                    _buildDetailChip(
                      Icons.currency_rupee,
                      '${job['hourly_rate']}/hr',
                    ),
                    if (job['category'] != null)
                      _buildDetailChip(
                        Icons.category_outlined,
                        job['category'],
                      ),
                  ],
                ),

                // Call Contractor
                if (contractorPhone != null && contractorPhone.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => _callPhone(contractorPhone),
                    icon: const Icon(Icons.phone, color: Colors.green),
                    label: Text(
                      'Call Contractor ($contractorPhone)',
                      style: const TextStyle(color: Colors.green),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                ],

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // Description
                Text(
                  'Description',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  job['description'] ?? 'No description provided.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.6),
                ),

                // Map Section
                if (lat != null && lng != null && lat != 0.0) ...[
                  const SizedBox(height: 32),
                  JobMapWidget(
                    lat: lat,
                    lng: lng,
                    label: job['location'] ?? 'Site',
                  ).animate().fadeIn(delay: 200.ms),
                ],

                // Bottom padding for FAB
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Floating Apply Button
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isApplying ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isApplying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Apply Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
