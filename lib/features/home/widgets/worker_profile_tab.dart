import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isUploading = false;
  String? _base64Image;
  String? _authPhotoUrl;

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
      _authPhotoUrl = user.photoURL;

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
          // Load base64 image if exists
          if (data['base64Image'] != null) {
            _base64Image = data['base64Image'];
          }
        });
      }
    }
  }

  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    // Pick with compression to avoid Firestore 1MB limit
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) return;

      final bytes = await File(image.path).readAsBytes();
      final String base64String = base64Encode(bytes);

      // Update Firestore directly (No Storage Bucket)
      await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .update({'base64Image': base64String});

      setState(() {
        _base64Image = base64String;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated locally!')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving image: $e')));
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

    ImageProvider? backgroundImage;
    if (_base64Image != null) {
      backgroundImage = MemoryImage(base64Decode(_base64Image!));
    } else if (_authPhotoUrl != null) {
      backgroundImage = NetworkImage(_authPhotoUrl!);
    }

    return CustomScrollView(
      slivers: [
        // Animated Header
        SliverAppBar(
          expandedHeight: 280.0,
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
                          ? [
                              const Color(0xFF2C3E50),
                              const Color(0xFF000000),
                            ] // Elegant Dark
                          : [
                              const Color(0xFF6A11CB),
                              const Color(0xFF2575FC),
                            ], // Modern Blue-Purple
                    ),
                  ),
                ),
                // Decorative circles
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 64,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: backgroundImage,
                          child: backgroundImage == null
                              ? Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.grey,
                                  ),
                                )
                              : null,
                        ),
                      ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAndSaveImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.blueAccent,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ],
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
