import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:workers_hub/core/services/auth_service.dart';
import 'package:workers_hub/core/theme/app_theme.dart';
import 'package:workers_hub/features/auth/widgets/auth_button.dart';
import 'package:workers_hub/features/auth/widgets/auth_text_field.dart';
import 'package:workers_hub/features/home/screens/contractor_home_screen.dart';

class ContractorRegistrationScreen extends StatefulWidget {
  const ContractorRegistrationScreen({super.key});

  @override
  State<ContractorRegistrationScreen> createState() =>
      _ContractorRegistrationScreenState();
}

class _ContractorRegistrationScreenState
    extends State<ContractorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedIndustry;
  bool _isLoading = false;

  final List<String> _industries = [
    'Residential',
    'Commercial',
    'Industrial',
    'Infrastructure',
    'Renovation',
    'Landscaping',
  ];

  @override
  void dispose() {
    _companyController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _registerContractor() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final uid = AuthService().currentUser!.uid;
        await AuthService().createContractorProfile(
          uid: uid,
          data: {
            'companyName': _companyController.text.trim(),
            'industry': _selectedIndustry,
            'phone': _phoneController.text.trim(),
            'location': _locationController.text.trim(),
          },
        );

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const ContractorHomeScreen(),
            ),
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
        title: const Text('Contractor Registration'),
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
                  'Company Details',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideX(),
                const SizedBox(height: 8),
                Text(
                  'Provide your business information to post jobs.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 32),

                // Company Name
                AuthTextField(
                  controller: _companyController,
                  label: 'Company Name',
                  hint: 'ABC Construction',
                  prefixIcon: Icons.business,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter company name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Industry Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedIndustry,
                  decoration: InputDecoration(
                    labelText: 'Industry Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: _industries.map((industry) {
                    return DropdownMenuItem(
                      value: industry,
                      child: Text(industry),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedIndustry = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select industry' : null,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 20),

                // Location
                AuthTextField(
                  controller: _locationController,
                  label: 'Headquarters Location',
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
                  label: 'Contact Number',
                  hint: '9876543210',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter contact number';
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
                  onPressed: _registerContractor,
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
