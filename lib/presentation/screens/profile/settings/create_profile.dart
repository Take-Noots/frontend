import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/services/profile_service.dart';
import 'edit_profile.dart'; // Import the EditProfilePage

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({Key? key}) : super(key: key);

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String bio = '';
  String profileImage = '';
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
    if (!_formKey.currentState!.validate()) return;
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
    final result = await profileService.createProfile({
      'userId': userId,
      'bio': bio,
      'profileImage': profileImage,
      'fullName': fullName,
      'userType': userType, // Include user type in the creation
    });
    setState(() {
      isLoading = false;
    });
    if (result['success'] == true) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Profile Created'),
            content: const Text('Your profile was created successfully!'),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(context, '/profile');
                },
                child: const Text('Go to Profile'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditProfilePage()),
                  );
                },
                child: const Text('Edit Profile'),
              ),
            ],
          ),
        );
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
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _uploading ? null : _pickAndUploadImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: (() {
                        if (profileImage.isEmpty) {
                          return const AssetImage('assets/hehe.png');
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
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Bio is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Profile Image URL',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => profileImage = value,
                // Make profile image optional: don't force user to provide a URL
                validator: (value) => null,
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
