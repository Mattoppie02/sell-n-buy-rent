import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:sell_n_buy_updated/services/auth_service.dart';
import 'package:sell_n_buy_updated/services/database_service.dart';
import 'package:sell_n_buy_updated/services/storage_service.dart';
import 'package:sell_n_buy_updated/models/user_profile.dart';
import 'package:sell_n_buy_updated/theme/app_theme.dart';
import 'profile_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  late final DatabaseService _databaseService;
  late final AuthService _authService;
  late final StorageService _storageService;
  final ImagePicker _imagePicker = ImagePicker();
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _databaseService = context.read<DatabaseService>();
    _authService = context.read<AuthService>();
    _storageService = context.read<StorageService>();
    _loadUserProfile();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final File imageFile = File(pickedFile.path);
      final String userId = _authService.currentUser?.uid ?? '';
      
      // Upload image to Firebase Storage
      final String downloadUrl = await _storageService.uploadProfilePicture(userId, imageFile);
      
      // Update user profile with new photo URL
      final updatedProfile = _userProfile!.copyWith(photoUrl: downloadUrl);
      await _databaseService.updateUserProfile(updatedProfile);
      
      setState(() {
        _userProfile = updatedProfile;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated successfully', 
              style: AppTheme.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppTheme.errorColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final profile = await _databaseService.getUserProfile(currentUser.uid);
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          nameController.text = profile.name;
          phoneController.text = profile.phoneNumber ?? '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_userProfile == null) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = _userProfile!.copyWith(
        name: nameController.text,
        phoneNumber: phoneController.text,
      );

      await _databaseService.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully', style: AppTheme.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e', style: AppTheme.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppTheme.errorColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'ACCOUNT',
          style: AppTheme.headingMedium.copyWith(
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Picture Section
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.secondaryColor, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _userProfile?.photoUrl != null
                              ? NetworkImage(_userProfile!.photoUrl!)
                              : null,
                          child: _userProfile?.photoUrl == null
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.secondaryColor,
                          ),
                          child: const Icon(Icons.camera_alt, size: 20, color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Form Fields
                  _buildEditableField(
                    'Name',
                    nameController,
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  _buildEditableField(
                    'Email Address',
                    TextEditingController(text: _userProfile?.email ?? ''),
                    Icons.email_outlined,
                    editable: false,
                  ),
                  const SizedBox(height: 20),

                  _buildEditableField(
                    'Phone Number',
                    phoneController,
                    Icons.phone_outlined,
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: AppTheme.primaryButton.copyWith(
                        backgroundColor: MaterialStateProperty.all(AppTheme.secondaryColor),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      onPressed: _saveChanges,
                      child: Text(
                        'Save Changes',
                        style: AppTheme.button.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool editable = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2F2F2F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: editable ? Colors.transparent : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: TextField(
            controller: controller,
            readOnly: !editable,
            style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey[400]),
              suffixIcon: editable
                  ? Icon(Icons.edit, color: AppTheme.secondaryColor, size: 20)
                  : Icon(Icons.lock_outline, color: Colors.grey[400], size: 20),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
