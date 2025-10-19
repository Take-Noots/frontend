import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/router/route_names.dart';
import '../../../data/services/advertisement_service.dart';
import '../../../data/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';

class CreateAdvertisementScreen extends StatefulWidget {
  const CreateAdvertisementScreen({Key? key}) : super(key: key);

  @override
  State<CreateAdvertisementScreen> createState() => _CreateAdvertisementScreenState();
}

class _CreateAdvertisementScreenState extends State<CreateAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactDetailsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();

  File? _selectedMedia;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contactDetailsController.dispose();
    _locationController.dispose();
    _genreController.dispose();
    _hashtagsController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedMedia = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedMedia = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e')),
      );
    }
  }

  void _showMediaPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.secondary),
                  title: Text('Photo from Gallery', style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickMedia(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera, color: Theme.of(context).colorScheme.secondary),
                  title: Text('Photo from Camera', style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickMedia(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.video_library, color: Theme.of(context).colorScheme.secondary),
                  title: Text('Video from Gallery', style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickVideo(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.videocam, color: Theme.of(context).colorScheme.secondary),
                  title: Text('Video from Camera', style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickVideo(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onNextPressed() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to create an advertisement')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final authService = AuthService(authProvider);
      final advertisementService = AdvertisementService(authService);

      final result = await advertisementService.createAdvertisement(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        image: null, // Not saving image to DB yet
        video: null, // Not saving video to DB yet
        contactDetails: _contactDetailsController.text.trim().isEmpty ? null : _contactDetailsController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        genre: _genreController.text.trim().isEmpty ? null : _genreController.text.trim(),
        hashtags: _hashtagsController.text.trim().isEmpty ? null : _hashtagsController.text.trim(),
        keywords: _keywordsController.text.trim().isEmpty ? null : _keywordsController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advertisement created successfully!')),
        );
  // Navigate to set audience screen (use push to preserve navigation stack)
  context.push(AppRoutes.setAudience);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to create advertisement')),
        );
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    int maxLines = 1,
    String? hintText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              fontSize: 16,
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: required ? (value) {
            if (value == null || value.isEmpty) {
              return '$label is required';
            }
            return null;
          } : null,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Advertisement',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.titleLarge?.color),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title (Required)
              _buildTextField(
                label: 'Title *',
                controller: _titleController,
                required: true,
                hintText: 'Enter advertisement title',
              ),

              // Description (Required)
              _buildTextField(
                label: 'Description *',
                controller: _descriptionController,
                required: true,
                maxLines: 3,
                hintText: 'Describe your advertisement',
              ),

              // Upload Image/Video (Optional)
              Text(
                'Upload Image or Video',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Optional',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showMediaPicker,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedMedia != null ? Theme.of(context).colorScheme.secondary : (isDark ? Colors.grey[600]! : Colors.grey[200]!),
                      width: _selectedMedia != null ? 2 : 1,
                    ),
                  ),
                  child: _selectedMedia != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _selectedMedia!.path.endsWith('.mp4') ||
                                  _selectedMedia!.path.endsWith('.mov') ||
                                  _selectedMedia!.path.endsWith('.avi')
                              ? Center(
                                  child: Icon(
                                    Icons.video_file,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                )
                              : Image.file(
                                  _selectedMedia!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_a_photo,
                                size: 32,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to select image or video',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Contact Details (Optional)
              _buildTextField(
                label: 'Contact Details',
                controller: _contactDetailsController,
                hintText: 'Phone, email, or other contact info',
              ),

              // Location (Optional)
              _buildTextField(
                label: 'Location',
                controller: _locationController,
                hintText: 'City, state, or address',
              ),

              // Genre (Optional)
              _buildTextField(
                label: 'Genre',
                controller: _genreController,
                hintText: 'Music genre, event type, etc.',
              ),

              // Hashtags (Optional)
              _buildTextField(
                label: 'Hashtags',
                controller: _hashtagsController,
                hintText: 'e.g., #music #art #event',
              ),

              // Keywords (Optional)
              _buildTextField(
                label: 'Keywords',
                controller: _keywordsController,
                hintText: 'Separate with commas',
              ),

              const SizedBox(height: 32),

              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading ? Colors.grey : const Color(0xFF8E08EF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
