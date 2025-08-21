// import 'package:flutter/material.dart';
// import 'package:frontend/data/models/fanbase/fanbase_model.dart';
import 'package:Noot/data/models/feed_item.dart';
// import 'package:frontend/data/services/fanbase/fanbase_service.dart';
// import 'package:frontend/presentation/screens/demopost/des_post_home.dart';
// import 'package:lucide_icons/lucide_icons.dart';
// import 'package:provider/provider.dart';
// import '../../../core/providers/auth_provider.dart';
// import '../../widgets/common/musicplayer_bar.dart';

// class FanbaseDetailScreen extends StatefulWidget {
//   final String fanbaseId;

//   const FanbaseDetailScreen({super.key, required this.fanbaseId});

//   @override
//   State<FanbaseDetailScreen> createState() => _FanbaseDetailScreenState();
// }

// class _FanbaseDetailScreenState extends State<FanbaseDetailScreen> {
//   late Future<Fanbase> _fanbaseFuture;
//   bool isJoined = false;

//   @override
//   void initState() {
//     super.initState();
//     _fanbaseFuture = FanbaseService.getFanbaseById(widget.fanbaseId);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final color = theme.colorScheme;

//     // Debugging
//     print("Destination: FanbaseDetailScreen");
//     print("Fanbase ID: ${widget.fanbaseId}");

//     return Scaffold(
//       body: SafeArea(
//         child: FutureBuilder<Fanbase>(
//           future: _fanbaseFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             if (snapshot.hasError || !snapshot.hasData) {
//               return const Center(child: Text('Error loading fanbase'));
//             }

//             final fanbase = snapshot.data!;
//             bool _showMusicPlayer = false; // move this inside the builder scope

//             return Column(
//               children: [
//                 // axisAlignment: CrossAxisAlignment.start,
//                 // ===== Top Section =====
//                 Container(
//                   padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0),
//                   color: color.onPrimary,
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       CircleAvatar(
//                         backgroundImage: NetworkImage(fanbase.fanbasePhotoUrl),
//                         radius: 24,
//                         backgroundColor: color.surface,
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           fanbase.fanbaseName,
//                           style: theme.textTheme.headlineSmall?.copyWith(
//                             color: color.primary,
//                           ),
//                         ),
//                       ),
//                       OutlinedButton.icon(
//                         onPressed: () {},
//                         icon: const Icon(LucideIcons.plus, size: 16),
//                         label: const Text("Create Post"),
//                         style: OutlinedButton.styleFrom(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       SizedBox(
//                         width: 100,
//                         child: OutlinedButton(
//                           onPressed: () =>
//                               setState(() => isJoined = !isJoined),
//                           style: OutlinedButton.styleFrom(
//                             backgroundColor:
//                                 isJoined ? Colors.transparent : Colors.purple,
//                             foregroundColor: isJoined
//                                 ? color.primary
//                                 : Colors.white,
//                             side: const BorderSide(color: Colors.purple),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                           ),
//                           child: Text(isJoined ? 'Joined' : 'Join'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 16),
//                 Text(
//                   // padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                   // child: Text(
//                     fanbase.fanbaseTopic,
//                     style: theme.textTheme.bodyLarge,
//                   // ),
//                 ),
//                 const SizedBox(height: 24),

//                 /// Expanded content + music player bar
//                 Expanded(
//                   child: Column(
//                     children: [
//                       Expanded(
//                         child: HomeScreen2(inShell: true),
//                       ),
//                       Consumer<AuthProvider>(
//                         builder: (context, authProvider, _) {
//                           return AnimatedContainer(
//                             duration: const Duration(milliseconds: 300),
//                             curve: Curves.easeInOut,
//                             height: _showMusicPlayer ? null : 0.0,
//                             constraints: _showMusicPlayer
//                                 ? null
//                                 : const BoxConstraints(maxHeight: 0.0),
//                             child: SingleChildScrollView(
//                               physics: const NeverScrollableScrollPhysics(),
//                               child: MusicPlayerBar(
//                                 isHidden: !_showMusicPlayer,
//                                 onSessionStatusChanged: (isActive) {
//                                   setState(() {
//                                     _showMusicPlayer = isActive;
//                                   });
//                                 },
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
// import 'package:Noot/presentation/screens/demopost/des_post_home.dart';
import 'package:Noot/data/models/fanbase_model.dart';
import 'package:Noot/data/services/fanbase_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:Noot/presentation/screens/fanbasePost/fanbasePost_creation_screen.dart';
import '../../widgets/fanbasepost/fanbase_post_feed.dart';

import '../../widgets/common/bottom_bar.dart';

class FanbaseDetailScreen extends StatefulWidget {
  final String fanbaseId;

  const FanbaseDetailScreen({super.key, required this.fanbaseId});

  @override
  State<FanbaseDetailScreen> createState() => _FanbaseDetailScreenState();
}

class _FanbaseDetailScreenState extends State<FanbaseDetailScreen> {
  late Future<Fanbase> _fanbaseFuture;
  Fanbase? _fanbase; // Store the current fanbase state
  bool _isLoading = false; // Loading state for join button

  @override
  void initState() {
    super.initState();
    _fanbaseFuture = FanbaseService.getFanbaseById(widget.fanbaseId, context);
  }

  /// Handles toggling the join status by trusting the backend response.
  Future<void> _handleJoin() async {
    if (_isLoading || _fanbase == null) return;

    setState(() => _isLoading = true);

    try {
      // Call the service and wait for the definitive response
      final updatedFanbase =
          await FanbaseService.joinFanbase(_fanbase!.id, context);

      print('Updated fanbase: ${updatedFanbase.toJson()}');

      // Trust the backend's response to update the state
      if (mounted) {
        setState(() {
          _fanbase = updatedFanbase;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
    // final theme = Theme.of(context);
    // final color = theme.colorScheme;

    return Scaffold(
      body: FutureBuilder<Fanbase>(
        future: _fanbaseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error loading fanbase'));
          }

          // Initialize _fanbase when data is first loaded
          if (_fanbase == null) {
            _fanbase = snapshot.data!;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Top Container =====
              Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.fromLTRB(8.0, 30.0, 8.0, 8.0),
                // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                color: Theme.of(context).colorScheme.onPrimary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  // mainAxisAlignment: MainAxisAlignment.center,
                  // crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    // Profile Image and Name
                    CircleAvatar(
                      backgroundImage: NetworkImage(_fanbase!.fanbasePhotoUrl ??
                          'https://via.placeholder.com/150'),
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      onBackgroundImageError: (exception, stackTrace) {
                        // Handle image loading error
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fanbase!.fanbaseName,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ),
                    // Create Post Button
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FanbasePostCreationScreen(
                              fanbaseId: _fanbase!.id,
                              fanbaseName: _fanbase!.fanbaseName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text(" Post"),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Join / Joined Button with fixed width
                    SizedBox(
                      width: 100, // Fixed width
                      child: OutlinedButton(
                        onPressed: _handleJoin,
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              _fanbase!.isJoined ? Colors.white : Colors.purple,
                          foregroundColor:
                              _fanbase!.isJoined ? Colors.purple : Colors.white,
                          side: const BorderSide(color: Colors.purple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _fanbase!.isJoined
                                        ? Colors.purple
                                        : Colors.white,
                                  ),
                                ),
                              )
                            : Text(_fanbase!.isJoined ? 'Joined' : 'Join'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===== Fanbase Topic / Description =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _fanbase!.fanbaseTopic,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

              const SizedBox(height: 24),

              // ======= Post Feed =======
              Expanded(
                child: FanbasePostFeedWidget(
                  fanbaseId: _fanbase!.id,
                ),
              ),

            ],
          );
        },
      ),
      bottomNavigationBar: const BottomBar(),
    );
  }
}
