import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:Noot/data/models/fanbase_model.dart';
import 'package:Noot/data/services/fanbase_service.dart';
import 'package:Noot/data/services/cloudinary_service.dart'; // ADD THIS
import 'package:Noot/presentation/widgets/fanbases/fanbase_card.dart';
import 'package:Noot/presentation/widgets/home/header_bar.dart';
import 'package:Noot/presentation/widgets/loading_screens/common_loading.dart'; // ADD THIS



/// Main fanbase page with Feed and Owned tabs
/// Feed tab shows non-owned fanbases, Owned tab shows user's created fanbases
class FanbasePage extends StatefulWidget {
  final bool inShell;

  const FanbasePage({super.key, this.inShell = false});

  @override
  State<FanbasePage> createState() => _FanbasePageState();
}

class _FanbasePageState extends State<FanbasePage>
    with SingleTickerProviderStateMixin {
  Future<List<Fanbase>>? futureFanbases;
  late TabController _tabController;
  String? _currentUserId;
  List<Fanbase> _allFanbases = [];
  int _selectedTabIndex = 0;

  final CloudinaryService _cloudinaryService = CloudinaryService(); // ADD THIS
  final ImagePicker _imagePicker = ImagePicker(); // ADD THIS

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadCurrentUserAndFanbases();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loads current user ID and then fetches all fanbases
  Future<void> _loadCurrentUserAndFanbases() async {
    await _loadCurrentUserId();
    _loadFanbases();
  }

  /// Retrieves current user ID from SharedPreferences
  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        setState(() {
          _currentUserId = userData['id'];
        });
        print('Current user ID loaded: $_currentUserId');
      }
    } catch (e) {
      print('Error loading current user ID: $e');
    }
  }

  /// Fetches all fanbases from the service
  void _loadFanbases() {
    setState(() {
      futureFanbases = FanbaseService.getAllFanbases(context);
    });
  }

  /// Filters fanbases based on ownership
  List<Fanbase> _filterFanbases(List<Fanbase> fanbases, int tabIndex) {
    if (_currentUserId == null) return fanbases;

    return fanbases.where((fanbase) {
      if (tabIndex == 0) {
        return fanbase.createdBy.id != _currentUserId && !fanbase.isJoined;
      } else if (tabIndex == 1) {
        return fanbase.isJoined && fanbase.createdBy.id != _currentUserId;
      } else if (tabIndex == 2) {
        return fanbase.createdBy.id == _currentUserId;
      }
      return false;
    }).toList();
  }

  /// Builds the fanbase list based on current tab
  Widget _buildFanbaseList(int tabIndex) {
    return FutureBuilder<List<Fanbase>>(
      future: futureFanbases,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: _loadFanbases,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tabIndex == 2
                      ? Icons.create
                      : tabIndex == 1
                          ? Icons.group
                          : Icons.explore,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  tabIndex == 2
                      ? 'No owned fanbases yet'
                      : tabIndex == 1
                          ? 'No joined fanbases yet'
                          : 'No fanbases found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tabIndex == 2
                      ? 'Create your first fanbase!'
                      : tabIndex == 1
                          ? 'Explore and join fanbases'
                          : 'Check back later for new fanbases',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        _allFanbases = snapshot.data!;
        final filteredFanbases =
            _filterFanbases(_allFanbases, _selectedTabIndex);

        if (filteredFanbases.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedTabIndex == 2
                      ? Icons.create
                      : _selectedTabIndex == 1
                          ? Icons.group
                          : Icons.explore,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedTabIndex == 2
                      ? 'No owned fanbases yet'
                      : _selectedTabIndex == 1
                          ? 'No joined fanbases yet'
                          : 'No fanbases found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedTabIndex == 2
                      ? 'Create your first fanbase using the + button!'
                      : _selectedTabIndex == 1
                          ? 'Explore and join fanbases'
                          : 'All visible fanbases are owned by you',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadFanbases();
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: filteredFanbases.length,
            itemBuilder: (context, index) {
              final fanbase = filteredFanbases[index];
              return FanbaseCard(
                onJoinStateChanged: _loadFanbases,
                initialFanbase: fanbase,
              );
            },
          ),
        );
      },
    );
  }

  /// Builds the tab bar with Feed and Owned tabs using button style
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTabIndex != 0
                    ? Colors.grey[500]
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: _selectedTabIndex != 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
                _tabController.animateTo(0);
                _loadFanbases();
              },
              child: const Text('Explore'),
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTabIndex != 1
                    ? Colors.grey[500]
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: _selectedTabIndex != 1
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
                _tabController.animateTo(1);
                _loadFanbases();
              },
              child: const Text('Join'),
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTabIndex != 2
                    ? Colors.grey[500]
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: _selectedTabIndex != 2
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedTabIndex = 2;
                });
                _tabController.animateTo(2);
                _loadFanbases();
              },
              child: const Text('Creator'),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the modal bottom sheet for creating a new fanbase
  void _showCreateFanbaseSheet() {
    final nameController = TextEditingController();
    final topicController = TextEditingController();
    File? selectedImage;
    String? uploadedImageUrl;
    String? nameErrorText;
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      barrierColor: Colors.black.withOpacity(0.8), // Darker background
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                /// Picks an image from gallery or camera and uploads to Cloudinary
                Future<void> _pickAndUploadImage(ImageSource source) async {
                  try {
                    final pickedFile = await _imagePicker.pickImage(
                      source: source,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 85,
                    );

                    if (pickedFile == null) return;

                    setModalState(() => uploading = true);

                    // Upload to Cloudinary
                    final file = File(pickedFile.path);
                    final imageUrl = await _cloudinaryService.uploadImage(
                      file,
                      folder: 'fanbase_pictures',
                    );

                    setModalState(() {
                      selectedImage = file;
                      uploadedImageUrl = imageUrl;
                      uploading = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Image uploaded successfully!')),
                    );
                  } catch (e) {
                    setModalState(() => uploading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to upload image: $e')),
                    );
                  }
                }

                /// Shows dialog for selecting image source
                void _showImageSourceDialog() async {
                  final source = await showDialog<ImageSource>(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.8),
                    builder: (context) => AlertDialog(
                      title: const Text('Select Image Source'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Gallery'),
                            onTap: () =>
                                Navigator.pop(context, ImageSource.gallery),
                          ),
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Camera'),
                            onTap: () =>
                                Navigator.pop(context, ImageSource.camera),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (source != null) {
                    await _pickAndUploadImage(source);
                  }
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Create a Fanbase',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        // Image selection section with upload indicator
                        GestureDetector(
                          onTap: uploading ? null : _showImageSourceDialog,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: selectedImage != null
                                    ? FileImage(selectedImage!)
                                    : (uploadedImageUrl != null
                                        ? NetworkImage(uploadedImageUrl!)
                                        : const NetworkImage(
                                            'https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png',
                                          )) as ImageProvider,
                              ),
                              if (uploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: CommonLoading.purple(size: 24),
                                    ),
                                  ),
                                ),
                              if (!uploading)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.surface,
                                    child: Icon(Icons.camera_alt,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        size: 18),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!uploading)
                          const Text(
                            'Tap to change photo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8E24AA),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Fanbase name input
                        TextField(
                          controller: nameController,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary),
                          decoration: InputDecoration(
                            labelText: 'Fanbase Name',
                            labelStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onPrimary,
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onPrimary,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                        if (nameErrorText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            nameErrorText!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Fanbase topic input
                        TextField(
                          controller: topicController,
                          maxLines: 7,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary),
                          decoration: InputDecoration(
                            labelText: 'What is this fanbase about?',
                            labelStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onPrimary,
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onPrimary,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                side: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 35,
                                  vertical: 24,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton(
                              onPressed: uploading
                                  ? null
                                  : () async {
                                      final name = nameController.text.trim();
                                      // Check if the name is unique
                                      final isNameUnique = !_allFanbases.any(
                                          (fanbase) =>
                                              fanbase.fanbaseName
                                                  .trim()
                                                  .toLowerCase() ==
                                              name.toLowerCase());
                                      if (!isNameUnique) {
                                        setModalState(() {
                                          nameErrorText =
                                              'Fanbase name already exists. Please choose a different name.';
                                        });
                                        return;
                                      }
                                      final topic = topicController.text.trim();
                                      if (name.isNotEmpty && topic.isNotEmpty) {
                                        try {
                                          await FanbaseService.createFanbase(
                                            name,
                                            topic,
                                            context,
                                            imageUrl: uploadedImageUrl,
                                          );
                                          if (!context.mounted) return;
                                          Navigator.pop(context);

                                          setState(() {
                                            _selectedTabIndex = 2;
                                          });
                                          _tabController.animateTo(2);
                                          _loadFanbases();

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Fanbase created successfully!')),
                                          );
                                        } catch (e) {
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text('Error: $e')),
                                            );
                                          }
                                        }
                                      }
                                    },
                              backgroundColor: uploading
                                  ? Colors.grey
                                  : const Color(0xFFDB0DF9),
                              foregroundColor: Colors.white,
                              heroTag: 'create_fanbase_fab',
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(LucideIcons.check, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 3.0, 0, 4.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Fanbases',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 2),
        _buildTabBar(),
        const SizedBox(height: 0),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFanbaseList(0),
              _buildFanbaseList(1),
              _buildFanbaseList(2),
            ],
          ),
        ),
      ],
    );

    final fab = FloatingActionButton.extended(
      onPressed: _showCreateFanbaseSheet,
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 18),
          SizedBox(width: 4),
        ],
      ),
      backgroundColor: const Color.fromARGB(82, 221, 0, 255),
      heroTag: 'add_fanbase_fab',
    );

    if (widget.inShell) {
      return Stack(
        children: [
          Column(
            children: [
              NootAppBar(),
              Expanded(child: body),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: fab,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: NootAppBar(),
      body: body,
      floatingActionButton: fab,
    );
  }
}
