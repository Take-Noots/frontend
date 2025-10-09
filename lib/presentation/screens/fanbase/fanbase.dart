import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // Add for JSON decoding
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add for user data access

import 'package:frontend/data/models/fanbase_model.dart';
import 'package:frontend/data/services/fanbase_service.dart';
import 'package:frontend/presentation/widgets/fanbases/fanbase_card.dart';
import 'package:frontend/presentation/widgets/common/bottom_bar.dart';
import 'package:frontend/presentation/widgets/home/header_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  late Future<List<Fanbase>> futureFanbases;
  late TabController _tabController;
  String? _currentUserId; // Current user's ID for filtering
  List<Fanbase> _allFanbases = []; // Cache all fanbases
  int _selectedTabIndex = 0; // Track selected tab index

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUserId != null) {
      _loadFanbases();
    }
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
  List<Fanbase> _filterFanbases(List<Fanbase> fanbases, bool showOwned) {
    if (_currentUserId == null) return fanbases;

    return fanbases.where((fanbase) {
      bool isOwned = fanbase.createdBy.id == _currentUserId;
      return showOwned ? isOwned : !isOwned;
    }).toList();
  }

  /// Builds the fanbase list based on current tab
  Widget _buildFanbaseList(bool showOwned) {
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
                  showOwned ? Icons.create : Icons.explore,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  showOwned ? 'No owned fanbases yet' : 'No fanbases found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  showOwned
                      ? 'Create your first fanbase!'
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
        final filteredFanbases = _filterFanbases(_allFanbases, showOwned);

        if (filteredFanbases.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  showOwned ? Icons.create : Icons.explore,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  showOwned
                      ? 'No owned fanbases yet'
                      : 'No other fanbases found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  showOwned
                      ? 'Create your first fanbase using the + button!'
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
                backgroundColor: _selectedTabIndex == 0
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                foregroundColor: _selectedTabIndex == 0
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
                _tabController.animateTo(0);
              },
              child: const Text('Feed'),
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTabIndex == 1
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                foregroundColor: _selectedTabIndex == 1
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
                _tabController.animateTo(1);
              },
              child: const Text('Owned'),
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
    final urlController = TextEditingController();
    File? selectedImage;
    String? networkImageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                /// Picks an image from the device gallery
                Future<void> _pickImage() async {
                  final picker = ImagePicker();
                  final pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setModalState(() {
                      selectedImage = File(pickedFile.path);
                      networkImageUrl = null;
                    });
                  }
                }

                /// Shows dialog for entering image URL
                void _showUrlInputDialog() {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Enter the fanbase Photo URL'),
                        content: TextField(
                          controller: urlController,
                          decoration:
                              const InputDecoration(hintText: 'https://...'),
                          keyboardType: TextInputType.url,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setModalState(() {
                                networkImageUrl = urlController.text.trim();
                                selectedImage = null;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Use URL'),
                          ),
                        ],
                      );
                    },
                  );
                }

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
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

                        // Image selection section
                        GestureDetector(
                          onTap: () async {
                            final result = await showMenu<String>(
                              context: context,
                              position: const RelativeRect.fromLTRB(
                                  100, 400, 100, 100),
                              items: [
                                const PopupMenuItem(
                                  value: 'gallery',
                                  child: Row(
                                    children: [
                                      Icon(Icons.photo),
                                      SizedBox(width: 8),
                                      Text("Gallery"),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'url',
                                  child: Row(
                                    children: [
                                      Icon(Icons.link),
                                      SizedBox(width: 8),
                                      Text("Enter URL"),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            if (result == 'gallery') {
                              await _pickImage();
                            } else if (result == 'url') {
                              _showUrlInputDialog();
                            }
                          },
                          child: Column(
                            children: [
                              // Profile image preview
                              CircleAvatar(
                                radius: 34,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: selectedImage != null
                                    ? FileImage(selectedImage!)
                                    : (networkImageUrl != null &&
                                            networkImageUrl!.isNotEmpty)
                                        ? NetworkImage(networkImageUrl!)
                                            as ImageProvider
                                        : const NetworkImage(
                                            'https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png',
                                          ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8E24AA),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Fanbase name input
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Fanbase Name',
                            filled: true,
                            fillColor: const Color(0xFFF0F2FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Fanbase topic input
                        TextField(
                          controller: topicController,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'What is this fanbase about?',
                            filled: true,
                            fillColor: const Color(0xFFF0F2FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
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
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            FloatingActionButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                final topic = topicController.text.trim();
                                if (name.isNotEmpty && topic.isNotEmpty) {
                                  try {
                                    await FanbaseService.createFanbase(
                                      name,
                                      topic,
                                      context,
                                      imageFile: selectedImage,
                                      imageUrl: networkImageUrl,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.pop(context);

                                    // Switch to Owned tab to show the newly created fanbase
                                    setState(() {
                                      _selectedTabIndex = 1;
                                    });
                                    _tabController.animateTo(1);
                                    _loadFanbases();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Fanbase created successfully!')),
                                    );
                                  } catch (e) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              backgroundColor: const Color(0xFFDB0DF9),
                              foregroundColor: Colors.white,
                              heroTag: 'create_fanbase_fab',
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
    return Scaffold(
      appBar: NootAppBar(),
      body: Column(
        children: [
          // Page title
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

          // Tab bar with button style
          _buildTabBar(),
          const SizedBox(height: 2),

          // Tab view content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Feed tab - shows non-owned fanbases
                _buildFanbaseList(false),

                // Owned tab - shows owned fanbases
                _buildFanbaseList(true),
              ],
            ),
          ),
        ],
      ),

      // Floating action button for creating new fanbases
      floatingActionButton: FloatingActionButton.extended(
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
      ),

      bottomNavigationBar: const BottomBar(),
    );
  }
}
