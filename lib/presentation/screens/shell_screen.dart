// import 'package:flutter/material.dart';
// import '../widgets/home/header_bar.dart';
// import '../widgets/common/bottom_bar.dart';
// import '../widgets/common/musicplayer_bar.dart';
// import 'home_screen.dart';
// import 'package:provider/provider.dart';
// import '../../core/providers/auth_provider.dart';

// /// ShellScreen: A container that maintains persistent UI elements across screen changes.
// ///
// /// This is phase 1 of implementing a persistent navigation structure similar to Vue Router.
// /// Currently, only the HomeScreen is integrated into the shell; other navigation still uses
// /// standard Flutter routing.
// ///
// /// Future evolution:
// /// 1. Add more screens to the shell (Search, Create, Fanbases, Profile)
// /// 2. Replace direct navigation with IndexedStack for tab switching
// /// 3. Implement nested navigation within each tab as needed
// ///
// /// This approach allows gradual migration from the current navigation system
// /// to a more efficient persistent-state model.
// class ShellScreen extends StatefulWidget {
//   const ShellScreen({Key? key}) : super(key: key);

//   @override
//   State<ShellScreen> createState() => _ShellScreenState();
// }

// class _ShellScreenState extends State<ShellScreen> {
//   int _currentIndex = 0;
//   bool _showMusicPlayer = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const NootAppBar(),
//       body: Column(
//         children: [
//           // Currently, only the HomeScreen is managed here
//           // In the future, this will be an IndexedStack with multiple screens
//           Expanded(
//             child: HomeScreen(
//               inShell: true, // Tell HomeScreen it's inside the shell
//             ),
//           ),
//           // Music player widget - always rendered but conditionally visible
//           Consumer<AuthProvider>(
//             builder: (context, authProvider, _) => AnimatedContainer(
//               // Animate height changes for smooth transitions
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeInOut,
//               // Height is 0 when hidden, otherwise use the widget's natural height
//               height: _showMusicPlayer ? null : 0.0,
//               // When height is 0, don't take any space and clip overflowing content
//               constraints:
//                   _showMusicPlayer ? null : BoxConstraints(maxHeight: 0.0),
//               child: SingleChildScrollView(
//                 // Use SingleChildScrollView to avoid layout issues when animating height
//                 physics: NeverScrollableScrollPhysics(),
//                 child: MusicPlayerBar(
//                   // authToken: authProvider.token ?? '',
//                   // Keep the widget alive and polling regardless of visibility
//                   isHidden: !_showMusicPlayer,
//                   // Update visibility state when session status changes
//                   onSessionStatusChanged: (isActive) {
//                     setState(() {
//                       _showMusicPlayer = isActive;
//                     });
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       // Use the same bottom navigation bar
//       bottomNavigationBar: BottomBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           // If it's the home tab (index 0), just update the state
//           if (index == 0) {
//             setState(() {
//               _currentIndex = index;
//             });
//             return;
//           }

//           // For other tabs, use standard navigation for now
//           // This will be replaced with IndexedStack switching in the future
//           switch (index) {
//             case 1: // Search
//               Navigator.pushNamed(context, '/search');
//               break;
//             case 2: // Create
//               Navigator.pushNamed(context, '/create');
//               break;
//             case 3: // Fanbases
//               Navigator.pushNamed(context, '/fanbases');
//               break;
//             case 4: // Profile
//               Navigator.pushNamed(context, '/profile');
//               break;
//           }
//         },
//       ),
//     );
//   }
// }
