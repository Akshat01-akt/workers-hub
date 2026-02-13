import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:workers_hub/core/providers/theme_provider.dart';
import 'package:workers_hub/core/services/auth_service.dart';
import 'package:workers_hub/features/auth/screens/sign_in_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerProfileTab extends StatefulWidget {
  const WorkerProfileTab({super.key});

  @override
  State<WorkerProfileTab> createState() => _WorkerProfileTabState();
}

class _WorkerProfileTabState extends State<WorkerProfileTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _skillsController;
  late TextEditingController _experienceController;
  late TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _skillsController = TextEditingController();
    _experienceController = TextEditingController();
    _rateController = TextEditingController();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = AuthService().currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';

      // Fetch additional data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _phoneController.text = data['phoneNumber'] ?? '';
          _skillsController.text =
              (data['skills'] as List<dynamic>?)?.join(', ') ?? '';
          _experienceController.text = data['experience'] ?? '';
          _rateController.text = data['hourlyRate']?.toString() ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = AuthService().currentUser;
      if (user != null) {
        try {
          // Update Auth Profile
          await user.updateDisplayName(_nameController.text);

          // Update Firestore
          await FirebaseFirestore.instance
              .collection('workers')
              .doc(user.uid)
              .update({
                'phoneNumber': _phoneController.text,
                'skills': _skillsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList(),
                'experience': _experienceController.text,
                'hourlyRate': double.tryParse(_rateController.text) ?? 0.0,
              });

          setState(() => _isEditing = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating profile: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return CustomScrollView(
      slivers: [
        // Animated Header
        SliverAppBar(
          expandedHeight: 250.0,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: _isEditing ? const SizedBox() : Text(_nameController.text),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Colors.black, const Color(0xFF333333)]
                          : [Colors.blue.shade400, Colors.purple.shade400],
                    ),
                  ),
                ),
                Center(
                  child:
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 56,
                          child: Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _isEditing
                  ? _saveProfile
                  : () => setState(() => _isEditing = true),
            ),
          ],
        ),

        // Profile Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Personal Info'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Full Name',
                    _nameController,
                    Icons.person,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Phone',
                    _phoneController,
                    Icons.phone,
                    enabled: _isEditing,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader('Professional Details'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Skills (comma separated)',
                    _skillsController,
                    Icons.handyman,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Experience',
                    _experienceController,
                    Icons.work_history,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Hourly Rate (₹)',
                    _rateController,
                    Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    enabled: _isEditing,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader('Settings'),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                    ),
                    value: isDark,
                    onChanged: (value) => themeProvider.toggleTheme(value),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await AuthService().signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignInScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: !enabled,
        fillColor: enabled
            ? null
            : Theme.of(context).cardColor.withOpacity(0.5),
      ),
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }
}
