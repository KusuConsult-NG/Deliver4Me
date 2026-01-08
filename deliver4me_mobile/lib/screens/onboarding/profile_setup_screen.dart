import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deliver4me_mobile/providers/auth_provider.dart';
import 'package:deliver4me_mobile/services/user_service.dart';
import 'package:deliver4me_mobile/services/storage_service.dart';
import 'package:deliver4me_mobile/models/user_model.dart'; // Ensure this model import exists
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // New Controllers
  final _ageController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedGender;

  final userService = UserService();
  final storageService = StorageService();
  final imagePicker = ImagePicker();

  File? _profileImage;
  bool _isLoading = false; // Fixed variable name
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user =
        ref.read(currentUserProvider).value; // Changed to currentUserProvider
    if (user != null) {
      _emailController.text = user.email;
      _nameController.text = user.name;

      // Fetch existing profile data
      try {
        final userData = await userService.getUserById(user.id);
        if (userData != null) {
          if (mounted) {
            setState(() {
              _nameController.text = userData.name;
              _phoneController.text = userData.phone ?? '';
              final age = userData.age ?? 0;
              _ageController.text = age > 0 ? age.toString() : '';
              _countryController.text = userData.country ?? 'Nigeria';
              _stateController.text = userData.state ?? '';
              _cityController.text = userData.city ?? '';
              _selectedGender = userData.gender;

              // Role is an Enum, convert to string
              if (userData.role == UserRole.rider) {
                selectedRole = 'rider';
              } else if (userData.role == UserRole.sender) {
                selectedRole = 'sender';
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Photo Upload (Simplified for brevity)
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(Icons.camera_alt,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Role Selector
                  if (selectedRole == null) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'I am a',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child:
                              _buildRoleButton('sender', 'Sender', Icons.send),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRoleButton(
                              'rider', 'Rider', Icons.motorcycle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF135BEC).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF135BEC)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              selectedRole == 'rider'
                                  ? Icons.motorcycle
                                  : Icons.send,
                              color: const Color(0xFF135BEC)),
                          const SizedBox(width: 12),
                          Text('Role: ${selectedRole?.toUpperCase()}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF135BEC))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Form Fields
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(labelText: 'Country'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(labelText: 'State'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController, // Read-only
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135BEC),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Save & Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String value, String label, IconData icon) {
    final isSelected = selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF135BEC) : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF135BEC) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role (Sender or Rider)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider).value!;

      final userModel = UserModel(
        id: user.id,
        email: _emailController.text,
        name: _nameController.text,
        phone: _phoneController.text,
        role: selectedRole == 'rider' ? UserRole.rider : UserRole.sender,
        age: int.tryParse(_ageController.text) ?? 0,
        country: _countryController.text,
        state: _stateController.text,
        city: _cityController.text,
        gender: _selectedGender ?? 'Not Specified',
        createdAt: user.createdAt,
        walletBalance: user.walletBalance,
        totalDeliveries: user.totalDeliveries,
        isOnline: user.isOnline,
      );

      await _uploadProfilePhoto(user.id); // Use id or uid consistently
      await userService.updateUser(userModel);

      if (mounted) {
        if (selectedRole == 'rider') {
          Navigator.pushNamed(
            context,
            '/vehicle-selection', // Go to vehicle selection first
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/permissions', // Senders go straight to permissions
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadProfilePhoto(String userId) async {
    if (_profileImage == null) return;
    try {
      await storageService.uploadProfilePhoto(userId, _profileImage!);
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile saved, but photo upload failed.')),
        );
      }
    }
  }
}
