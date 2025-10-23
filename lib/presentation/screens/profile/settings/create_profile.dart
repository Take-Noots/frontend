import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/services/profile_service.dart';
import 'edit_profile.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({Key? key}) : super(key: key);

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String bio = '';
  String profileImage = '';
  String username = '';
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  String fullName = '';
  String userType = 'public'; // Default user type
  bool isLoading = false;

  // Define profile type options
  final List<Map<String, String>> _profileTypes = [
    {'value': 'public', 'label': 'Public'},
    {'value': 'private', 'label': 'Private'},
    {'value': 'artist', 'label': 'Artist'},
    {'value': 'business', 'label': 'Business'},
  ];

  Future<void> _submitProfile() async {
    // Ensure form validators pass (fullName and username required; bio optional)
    if (!_formKey.currentState!.validate()) return;
    // Pull latest values from controllers to ensure we send current text
    username = _usernameController.text.trim();
    fullName = _fullNameController.text.trim();
    setState(() {
      isLoading = true;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }
    final profileService = ProfileService();
    // Check if a profile already exists for this userId
    try {
      final existing = await profileService.getUserProfile(userId);
      if (existing['success'] == true && existing['data'] != null) {
        // Profile exists - ask user to edit instead
        if (!mounted) return;
        final goEdit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Profile already exists'),
            content: const Text(
                'A profile already exists for this account. Would you like to edit it instead?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Edit Profile'),
              ),
            ],
          ),
        );
        if (goEdit == true) {
          // Navigate to EditProfilePage
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EditProfilePage()),
          );
          return;
        } else {
          // Do not create duplicate; simply return
          return;
        }
      }
    } catch (e) {
      // If the check fails, proceed with create - server may be down
      print('[DEBUG] Error checking existing profile: $e');
    }
    final payload = {
      'userId': userId,
      'bio': bio,
      'fullName': fullName,
      'username': username,
      'userType': userType,
    };
    if (profileImage.isNotEmpty) payload['profileImage'] = profileImage;
    final result = await profileService.createProfile(payload);
    setState(() {
      isLoading = false;
    });
    if (result['success'] == true) {
      if (mounted) {
        // Force refresh of the profile cache then navigate to My Profile
        try {
          final profileProvider =
              Provider.of<ProfileProvider>(context, listen: false);
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final uid = authProvider.user?.id;
          if (uid != null) {
            await profileProvider.refreshProfile(uid, context: context);
          }
        } catch (e) {
          // ignore - proceed to navigation
        }
        // Navigate to Home after successful creation
        context.go(AppRoutes.home);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Failed to create profile')),
        );
      }
    }
  }

  final ImagePicker _imagePicker = ImagePicker();
  bool _uploading = false;
  bool _usernamePrefilled = false;

  @override
  void initState() {
    super.initState();
    _prefillUsername();
  }

  Future<void> _prefillUsername() async {
    // Try AuthProvider first, then SharedPreferences as fallback
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final nameOrUsername =
          authProvider.user == null ? null : (authProvider.user!.name);
      if (nameOrUsername != null && nameOrUsername.isNotEmpty) {
        setState(() {
          username = nameOrUsername;
          _usernameController.text = username;
          _usernamePrefilled = true;
        });
        return;
      }

      // Fallback to SharedPreferences 'user_data'
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        final spUsername =
            userData['username'] as String? ?? userData['name'] as String?;
        if (spUsername != null && spUsername.isNotEmpty) {
          setState(() {
            username = spUsername;
            _usernameController.text = username;
            _usernamePrefilled = true;
          });
        }
      }
    } catch (e) {
      // ignore - leave username editable/empty
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      setState(() => _uploading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      if (userId == null) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final multipart =
          MultipartFile.fromBytes(bytes, filename: pickedFile.name);
      final formData = FormData.fromMap({'profileImage': multipart});

      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final response = await dio.post('/profile/$userId/upload-profile-picture',
          data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respData = response.data;
        String? imageUrl;
        try {
          if (respData is Map) {
            imageUrl = respData['imageUrl'] as String? ??
                respData['url'] as String? ??
                respData['secure_url'] as String?;
            if (imageUrl == null) {
              if (respData['data'] is Map) {
                final nested = respData['data'] as Map;
                imageUrl = nested['imageUrl'] as String? ??
                    nested['url'] as String? ??
                    nested['secure_url'] as String?;
              }
              if (imageUrl == null && respData['result'] is Map) {
                final nested = respData['result'] as Map;
                imageUrl =
                    nested['secure_url'] as String? ?? nested['url'] as String?;
              }
            }
          } else if (respData is String) {
            try {
              final parsed = jsonDecode(respData);
              if (parsed is Map) {
                imageUrl =
                    parsed['imageUrl'] as String? ?? parsed['url'] as String?;
              }
            } catch (_) {}
          }
        } catch (e) {
          print('[DEBUG] Error extracting imageUrl: $e');
        }

        if (imageUrl != null && imageUrl.isNotEmpty) {
          setState(() {
            profileImage = imageUrl!;
            _uploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')),
          );
        } else {
          String serverMsg = 'No image URL in response';
          try {
            if (respData is Map)
              serverMsg =
                  respData['message']?.toString() ?? respData.toString();
            else
              serverMsg = respData.toString();
          } catch (_) {
            serverMsg = respData.toString();
          }
          throw Exception(serverMsg);
        }
      } else {
        throw Exception('Upload failed: ${response.statusMessage}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // top duplicate username field removed; prefilled username field below retained
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _uploading ? null : _pickAndUploadImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: (() {
                        if (profileImage.isEmpty) {
                          return const AssetImage('assets/images/hehe.png');
                        }
                        if (profileImage.startsWith('http')) {
                          return NetworkImage(profileImage);
                        }
                        return AssetImage(profileImage);
                      })() as ImageProvider,
                    ),
                    if (_uploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    if (!_uploading)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.camera_alt, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => fullName = value,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Full name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => bio = value,
                // Bio is optional per request - allow empty
                validator: (value) => null,
              ),
              const SizedBox(height: 16),
              // Removed Profile Image URL field per request
              const SizedBox(height: 8),
              // Username field: prefilled from AuthProvider or SharedPreferences
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => username = value.trim(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9._]')),
                  LengthLimitingTextInputFormatter(30),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Username is required';
                  final valid =
                      RegExp(r'^[A-Za-z0-9._]{1,30}$').hasMatch(value.trim());
                  return valid
                      ? null
                      : 'Use letters, numbers, periods and underscores only (1-30 chars)';
                },
                readOnly: _usernamePrefilled,
              ),
              const SizedBox(height: 24),
              // Add profile type dropdown
              Container(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Type',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: userType,
                      isExpanded: true,
                      dropdownColor: Colors.black87,
                      style: const TextStyle(color: Colors.white),
                      underline: Container(), // Remove the default underline
                      onChanged: (newValue) {
                        setState(() {
                          userType = newValue!;
                        });
                      },
                      items:
                          _profileTypes.map<DropdownMenuItem<String>>((type) {
                        return DropdownMenuItem<String>(
                          value: type['value'],
                          child: Text(
                            type['label']!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _submitProfile();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
