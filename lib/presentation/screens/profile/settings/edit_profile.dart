import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
// ...existing code...
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/models/profile_model.dart';
import '../../../../data/services/profile_service.dart';
import '../../../../presentation/widgets/loading_screens/common_loading.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  String profileImage = 'assets/hehe.png';
  String userType = 'public'; // Default user type

  final ProfileService _service = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;

  // Store original values to detect changes
  String _originalUsername = '';
  String _originalBio = '';
  String _originalEmail = '';
  String _originalFullName = '';
  String _originalProfileImage = '';
  String _originalUserType = 'public';

  // Define profile type options
  final List<Map<String, String>> _profileTypes = [
    {'value': 'public', 'label': 'Public'},
    {'value': 'private', 'label': 'Private'},
    {'value': 'artist', 'label': 'Artist'},
    {'value': 'business', 'label': 'Business'},
  ];

  @override
  void initState() {
    super.initState();
    print('[DEBUG] EditProfilePage initState called');
    _fetchProfile();
    // Add listeners to detect changes
    _usernameController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _fullNameController.addListener(_onFieldChanged);
  }


  void _onFieldChanged() {
    setState(() {}); // Rebuild to update button state
  }

  // Clean username validator (Instagram-like rules): letters, numbers, periods and underscores; 1-30 chars
  bool _validUsername(String u) {
    return RegExp(r'^[A-Za-z0-9._]{1,30}$').hasMatch(u);
  }

  bool get _hasChanges {
    return _usernameController.text != _originalUsername ||
        _bioController.text != _originalBio ||
        _emailController.text != _originalEmail ||
        _fullNameController.text != _originalFullName ||
        profileImage != _originalProfileImage ||
        userType != _originalUserType;
  }

  @override
  void dispose() {
    print('[DEBUG] EditProfilePage dispose called');
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    print('[DEBUG] _fetchProfile started');
    if (mounted) {
      setState(() => _loading = true);
    }

    // Get userId from SharedPreferences directly
    String? userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        userId = userData['id'];
      }
    } catch (e) {
      print('[DEBUG] _fetchProfile: Error reading SharedPreferences: $e');
    }

    print('[DEBUG] _fetchProfile userId: $userId');
    if (userId == null) {
      print('[DEBUG] _fetchProfile: userId is null');
      if (mounted) {
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in')),
          );
          Navigator.of(context).pop();
        });
      }
      return;
    }
    print('[DEBUG] _fetchProfile: calling getUserProfile');
    final result = await _service.getUserProfile(userId);
    print('[DEBUG] _fetchProfile result: $result');

    if (result['success'] == false || result['data'] == null) {
      print('[DEBUG] _fetchProfile: failed or no data');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Failed to load profile')),
        );
      }
      return;
    }
    final data = result['data'];
    print('[DEBUG] _fetchProfile: data received, setting controllers');

    try {
      // Defensive: check for required fields
      _usernameController.text = data['username'] ?? '';
      _originalUsername = _usernameController.text;
      print('[DEBUG] _fetchProfile: username set');
      _bioController.text = data['bio'] ?? '';
      _originalBio = _bioController.text;
      print('[DEBUG] _fetchProfile: bio set');
      _emailController.text = data['email'] ?? '';
      _originalEmail = _emailController.text;
      print('[DEBUG] _fetchProfile: email set');
      _fullNameController.text = data['fullName'] ?? '';
      _originalFullName = _fullNameController.text;
      print('[DEBUG] _fetchProfile: fullName set');

      final fetchedProfileImage = data['profileImage'] as String?;
      final fetchedUserType = data['userType'] as String?;

      if (mounted) {
        setState(() {
          profileImage = fetchedProfileImage ?? profileImage;
          _originalProfileImage = profileImage;
          userType = fetchedUserType ?? 'public';
          _originalUserType = userType;
        });
      }

      print('[DEBUG] _fetchProfile: profileImage set to $profileImage');
      print('[DEBUG] _fetchProfile: userType set to $userType');
    } catch (e) {
      print('[DEBUG] _fetchProfile ERROR setting fields: $e');
    }

    print('[DEBUG] _fetchProfile: setting _loading = false');
    if (mounted) {
      setState(() => _loading = false);
      print(
          '[DEBUG] _fetchProfile: setState called, _loading is now $_loading');
    } else {
      print('[DEBUG] _fetchProfile: widget not mounted, cannot call setState');
    }
    print('[DEBUG] _fetchProfile: completed successfully');
  }

  void _pickImage() async {
    try {
      // Show options dialog
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

      // Pick image
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _uploading = true);

      // Get userId from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      if (userId == null) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      // Read bytes from picked file (works on web and native)
      final bytes = await pickedFile.readAsBytes();

      // Build MultipartFile from bytes so it works on web (dart:io not required)
      final multipart = MultipartFile.fromBytes(
        bytes,
        filename: pickedFile.name,
      );

      final formData = FormData.fromMap({
        'profileImage': multipart,
      });

      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final response = await dio.post('/profile/$userId/upload-profile-picture',
          data: formData);

      // Accept several possible response shapes and give informative errors
      if (response.statusCode == 200 || response.statusCode == 201) {
        final respData = response.data;
        // Debug log the full response to help diagnose server issues
        print('[DEBUG] uploadProfilePicture response: $respData');

        String? imageUrl;

        try {
          if (respData is Map) {
            // Common keys
            imageUrl = respData['imageUrl'] as String? ??
                respData['url'] as String? ??
                respData['secure_url'] as String?;

            // Some controllers may nest under 'data' or 'result'
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
            // Try to decode JSON string
            try {
              final parsed = jsonDecode(respData);
              if (parsed is Map) {
                imageUrl =
                    parsed['imageUrl'] as String? ?? parsed['url'] as String?;
              }
            } catch (_) {
              // ignore
            }
          }
        } catch (e) {
          print('[DEBUG] Error while extracting imageUrl: $e');
        }

        if (imageUrl != null && imageUrl.isNotEmpty) {
          setState(() {
            profileImage = imageUrl as String;
            _uploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')),
          );
        } else {
          // If server provided a message, show it; otherwise show full response for debugging
          String serverMsg = 'No image URL in response';
          try {
            if (respData is Map) {
              serverMsg =
                  respData['message']?.toString() ?? respData.toString();
            } else {
              serverMsg = respData.toString();
            }
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

  Future<void> _saveProfile() async {
    if (mounted) {
      setState(() => _saving = true);
    }

    // Get userId from SharedPreferences directly
    String? userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        userId = userData['id'];
      }
    } catch (e) {
      print('[DEBUG] _saveProfile: Error reading SharedPreferences: $e');
    }

    if (userId == null) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
      return;
    }
    // Validate username
    final usernameText = _usernameController.text.trim();
    if (!_validUsername(usernameText)) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username invalid. Use letters, numbers, periods and underscores only (1-30 chars).')),
        );
      }
      return;
    }
    final editProfile = EditProfileModel(
      username: _usernameController.text,
      bio: _bioController.text,
      profileImage: profileImage,
      email: _emailController.text,
      fullName: _fullNameController.text,
      userType: userType, // Include user type in the update
    );
    final result = await _service.updateProfile(userId, editProfile.toJson());
    if (mounted) {
      setState(() => _saving = false);
    }
    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        // Navigate back with result to trigger profile refresh
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Failed to update profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        '[DEBUG] EditProfilePage build called, _loading=$_loading, _saving=$_saving');
    if (_loading || _saving) {
      print('[DEBUG] EditProfilePage: Showing loading spinner');
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CommonLoading.purple()),
      );
    }
    print(
        '[DEBUG] EditProfilePage: Rendering form with username=${_usernameController.text}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
            onPressed: () {
              _fetchProfile();
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _uploading ? null : _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: (() {
                          // If profileImage is empty or looks like an asset path, use AssetImage
                          if (profileImage.isEmpty) {
                            return const AssetImage('assets/hehe.png');
                          }
                          // simple heuristic: treat http/https as network image
                          if (profileImage.startsWith('http')) {
                            return NetworkImage(profileImage);
                          }
                          // fallback to asset image for local paths
                          return AssetImage(profileImage);
                        })() as ImageProvider,
                      ),
                      if (_uploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: CommonLoading.purple(size: 24),
                            ),
                          ),
                        ),
                      if (!_uploading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            child: Icon(Icons.camera_alt,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _fullNameController,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9._]')),
                    LengthLimitingTextInputFormatter(30),
                  ],
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioController,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Add profile type dropdown
                Container(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Type',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: userType,
                        isExpanded: true,
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
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
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface)),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    ElevatedButton(
                      onPressed: _hasChanges ? _saveProfile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChanges
                            ? Theme.of(context).colorScheme.surface
                            : Theme.of(context).disabledColor,
                        disabledBackgroundColor:
                            Theme.of(context).disabledColor,
                      ),
                      child: Text('Save',
                          style: TextStyle(
                              color: _hasChanges
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).disabledColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
