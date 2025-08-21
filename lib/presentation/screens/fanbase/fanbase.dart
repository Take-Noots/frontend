import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:Noot/data/models/fanbase_model.dart';
import 'package:Noot/data/services/fanbase_service.dart';
import 'package:Noot/presentation/widgets/fanbases/fanbase_card.dart';
import 'package:Noot/presentation/widgets/common/bottom_bar.dart';
import 'package:Noot/presentation/widgets/home/header_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FanbasePage extends StatefulWidget {
  final bool inShell;

  const FanbasePage({super.key, this.inShell = false});

  @override
  State<FanbasePage> createState() => _FanbasePageState();
}

class _FanbasePageState extends State<FanbasePage> {
  late Future<List<Fanbase>> futureFanbases;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFanbases();
  }

  void _loadFanbases() {
    setState(() {
      futureFanbases = FanbaseService.getAllFanbases(context);
    });
  }

  Widget _buildFanbaseList() {
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
          return const Center(child: Text('No fanbases found.'));
        }

        final fanbases = snapshot.data!;
        return ListView.builder(
          itemCount: fanbases.length,
          itemBuilder: (context, index) {
            final fanbase = fanbases[index];
            return FanbaseCard(
              // fanbaseId: fanbase.id,
              // profileImageUrl: fanbase.fanbasePhotoUrl ?? '',
              // fanbaseName: fanbase.fanbaseName,
              // topic: fanbase.fanbaseTopic,
              // numLikes: fanbase.numLikes,
              // numPosts: fanbase.numPosts,
              // isJoined: false,
              // onJoin: () {},
              onJoinStateChanged: _loadFanbases,
              initialFanbase: fanbase,
            );
          },
        );
      },
    );
  }

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
                                    _loadFanbases();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Fanbase created')),
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
    final content = _buildFanbaseList();

    return Scaffold(
      appBar: NootAppBar(),
      body: Column(
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
          Expanded(child: content),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateFanbaseSheet,
        label: const Icon(Icons.add, size: 18),
        backgroundColor: const Color.fromARGB(211, 217, 13, 249),
        heroTag: 'add_fanbase_fab',
      ),
      bottomNavigationBar: const BottomBar(),
    );
  }
}
