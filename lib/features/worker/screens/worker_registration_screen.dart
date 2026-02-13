import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:workers_hub/core/services/auth_service.dart';
import 'package:workers_hub/core/theme/app_theme.dart';
import 'package:workers_hub/features/auth/widgets/auth_button.dart';
import 'package:workers_hub/features/auth/widgets/auth_text_field.dart';
import 'package:workers_hub/features/home/screens/worker_home_screen.dart';

class WorkerRegistrationScreen extends StatefulWidget {
  const WorkerRegistrationScreen({super.key});

  @override
  State<WorkerRegistrationScreen> createState() =>
      _WorkerRegistrationScreenState();
}

class _WorkerRegistrationScreenState extends State<WorkerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _rateController = TextEditingController();
  String? _selectedSkill;
  String? _selectedExperience;
  bool _isLoading = false;

  final List<String> _skills = [
    'Carpenter',
    'Plumber',
    'Electrician',
    'Painter',
    'Mason',
    'Welder',
    'HVAC Technician',
    'Laborer',
  ];

  final List<String> _experienceLevels = [
    '< 1 Year',
    '1-3 Years',

    '3-5 Years',
    '5-10 Years',
    '10+ Years',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _locationController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _registerWorker() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final uid = AuthService().currentUser!.uid;
        await AuthService().createWorkerProfile(
          uid: uid,
          data: {
            'phone': _phoneController.text.trim(),
            'location': _locationController.text.trim(),
            'hourlyRate': double.parse(_rateController.text.trim()),
            'skill': _selectedSkill,
            'experience': _selectedExperience,
            'isAvailable': true,
          },
        );

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WorkerHomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Your Profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideX(),
                const SizedBox(height: 8),
                Text(
                  'Tell us about your skills and experience.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 32),

                // Skill Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSkill,
                  decoration: InputDecoration(
                    labelText: 'Select Your Skill',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.handyman_outlined),
                  ),
                  items: _skills.map((skill) {
                    return DropdownMenuItem(value: skill, child: Text(skill));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSkill = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a skill' : null,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 20),

                // Experience Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedExperience,
                  decoration: InputDecoration(
                    labelText: 'Years of Experience',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.timeline),
                  ),
                  items: _experienceLevels.map((level) {
                    return DropdownMenuItem(value: level, child: Text(level));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedExperience = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select experience' : null,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 20),

                // Hourly Rate
                AuthTextField(
                  controller: _rateController,
                  label: 'Hourly Rate (\u20B9)',
                  hint: '500',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter hourly rate';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Location
                AuthTextField(
                  controller: _locationController,
                  label: 'Current Location',
                  hint: 'Mumbai, Maharashtra',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone
                AuthTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '9876543210',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (value.length < 10) {
                      return 'Invalid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                AuthButton(
                  text: 'Register & Continue',
                  onPressed: _registerWorker,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
