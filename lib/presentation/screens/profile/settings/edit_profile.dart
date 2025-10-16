import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// ...existing code...
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/models/profile_model.dart';
import '../../../../data/services/profile_service.dart';

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
  String profileImage = 'https://via.placeholder.com/150';
  String userType = 'public'; // Default user type

  final ProfileService _service = ProfileService();

  bool _loading = true;
  bool _saving = false;

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
    setState(() {
      profileImage = profileImage.endsWith('e6e6e6e6e6e6e6e6')
          ? 'https://i.scdn.co/image/ab6761610000e5ebc4e8e8e8e8e8e8e8e8e8e8e8'
          : 'https://i.scdn.co/image/ab6761610000e5eb02e3c8b0e6e6e6e6e6e6e6e6';
    });
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    print(
        '[DEBUG] EditProfilePage: Rendering form with username=${_usernameController.text}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.black,
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
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: NetworkImage(profileImage),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.camera_alt, color: Colors.black, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _fullNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Add profile type dropdown
            Container(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade700),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile Type',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
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
                    items: _profileTypes.map<DropdownMenuItem<String>>((type) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  onPressed: _hasChanges ? _saveProfile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasChanges ? Colors.white : Colors.grey,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text('Save',
                      style: TextStyle(
                          color: _hasChanges ? Colors.black : Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
