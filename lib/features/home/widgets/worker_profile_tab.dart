import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workers_hub/core/providers/theme_provider.dart';
import 'package:workers_hub/core/services/auth_service.dart';
import 'package:workers_hub/core/services/database_service.dart';
import 'package:workers_hub/core/services/rating_service.dart';
import 'package:workers_hub/core/services/storage_service.dart';
import 'package:workers_hub/features/auth/screens/sign_in_screen.dart';
import 'package:workers_hub/features/home/screens/earnings_screen.dart';
import 'package:workers_hub/features/home/widgets/portfolio_gallery_widget.dart';

class WorkerProfileTab extends StatefulWidget {
  const WorkerProfileTab({super.key});

  @override
  State<WorkerProfileTab> createState() => _WorkerProfileTabState();
}

class _WorkerProfileTabState extends State<WorkerProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();
  final StorageService _storage = StorageService();

  bool _isEditing = false;
  bool _isUploading = false;
  bool _isAvailable = true;
  String? _photoUrl;
  double _profileCompletion = 0;
  double _averageRating = 0;
  int _ratingCount = 0;
  List<String> _portfolio = [];

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _skillsController;
  late TextEditingController _experienceController;
  late TextEditingController _rateController;

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _skillsController = TextEditingController();
    _experienceController = TextEditingController();
    _rateController = TextEditingController();
    _initUserListener();
  }

  void _initUserListener() {
    final user = AuthService().currentUser;
    if (user != null) {
      // Set initial Auth data
      _nameController.text = user.displayName ?? '';

      // Listen to Firestore Profile updates
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists && mounted) {
                final profile = snapshot.data()!;
                setState(() {
                  if (!_isEditing) {
                    _nameController.text = profile['name'] ?? '';
                    _phoneController.text = profile['phone'] ?? '';
                    _skillsController.text =
                        (profile['skills'] as List<dynamic>?)?.join(', ') ?? '';
                    _experienceController.text = profile['experience'] ?? '';
                    _rateController.text =
                        profile['hourly_rate']?.toString() ?? '';
                  }
                  _photoUrl = profile['photo_url'];
                  _isAvailable = profile['is_available'] ?? true;
                  _portfolio = List<String>.from(profile['portfolio'] ?? []);
                  // Compute rating
                  _averageRating = RatingService().computeAverage(profile);
                  _ratingCount =
                      (profile['rating_count'] as num?)?.toInt() ?? 0;
                  // Compute profile completion
                  int filled = 0;
                  const total = 5;
                  if ((profile['name'] ?? '').toString().isNotEmpty) filled++;
                  if ((profile['phone'] ?? '').toString().isNotEmpty) filled++;
                  if ((profile['skills'] as List?)?.isNotEmpty == true)
                    filled++;
                  if ((profile['experience'] ?? '').toString().isNotEmpty)
                    filled++;
                  if ((profile['hourly_rate']) != null) filled++;
                  _profileCompletion = filled / total;
                });
              }
            },
            onError: (e) {
              debugPrint('Error listening to profile updates: $e');
            },
          );
    }
  }

  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Reasonable size for profile
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) return;

      // 1. Upload to Firebase Storage
      final File file = File(image.path);
      final String publicUrl = await _storage.uploadProfileImage(
        file,
        user.uid,
      );

      // 2. Update Profile with URL
      await _db.updateProfile(uid: user.uid, photoUrl: publicUrl);

      // 3. Update Firebase Auth Photo URL (for consistency)
      await user.updatePhotoURL(publicUrl);

      setState(() {
        _photoUrl = publicUrl;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
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
    _userSubscription?.cancel();
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
          await _db.updateProfile(
            uid: user.uid,
            name: _nameController.text,
            phone: _phoneController.text,
            skills: _skillsController.text
                .split(',')
                .map((e) => e.trim())
                .toList(),
            experience: _experienceController.text,
            hourlyRate: double.tryParse(_rateController.text),
          );

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
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(_photoUrl!);
    }

    return CustomScrollView(
      slivers: [
        // Animated Header
        SliverAppBar(
          expandedHeight: 280.0,
          floating: false,
          pinned: true,
          centerTitle: true,
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
                      // Star rating below avatar
                      if (!_isEditing && _ratingCount > 0)
                        Positioned(
                          bottom: -8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: StarRating(
                              rating: _averageRating,
                              count: _ratingCount,
                              size: 16,
                            ),
                          ),
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
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  // Reset fields if cancelling
                  if (!_isEditing) {
                    _initUserListener();
                  }
                });
              },
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

                  // ── Portfolio Gallery ──────────────────────────────────
                  if (!_isEditing) ...[
                    _buildSectionHeader('Portfolio'),
                    const SizedBox(height: 12),
                    PortfolioGalleryWidget(
                      imageUrls: _portfolio,
                      isEditable: true,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 32),
                  ],

                  // ── Profile Completion ─────────────────────────────────
                  if (!_isEditing) ...[
                    _buildSectionHeader('Profile Completion'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _profileCompletion,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _profileCompletion == 1.0
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(_profileCompletion * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                    if (_profileCompletion < 1.0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Complete your profile to attract more contractors.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],

                  _buildSectionHeader('Settings'),
                  const SizedBox(height: 8),

                  // ── Availability Toggle ────────────────────────────────
                  Card(
                    elevation: 0,
                    color: _isAvailable
                        ? Colors.green.withOpacity(0.08)
                        : Colors.grey.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        _isAvailable ? 'Open to Work' : 'Not Available',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isAvailable ? Colors.green : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        _isAvailable
                            ? 'Contractors can see you are available'
                            : 'You are hidden from contractor searches',
                        style: const TextStyle(fontSize: 12),
                      ),
                      secondary: Icon(
                        _isAvailable
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: _isAvailable ? Colors.green : Colors.grey,
                      ),
                      value: _isAvailable,
                      activeColor: Colors.green,
                      onChanged: (value) async {
                        setState(() => _isAvailable = value);
                        final user = AuthService().currentUser;
                        if (user != null) {
                          await DatabaseService().updateProfile(
                            uid: user.uid,
                            isAvailable: value,
                          );
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),

                  // ── Earnings Button ────────────────────────────────────
                  if (!_isEditing)
                    ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EarningsScreen(),
                          ),
                        );
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.green,
                        ),
                      ),
                      title: const Text(
                        'My Earnings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'View accepted jobs & estimated pay',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 12),

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

                  if (_isEditing) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.check),
                        label: const Text('Update Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 16),
                  ],

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
