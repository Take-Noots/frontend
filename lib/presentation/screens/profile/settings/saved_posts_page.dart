// import 'package:flutter/material.dart';

// class SavedPostsPage extends StatelessWidget {
//   const SavedPostsPage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Saved Posts'),
//         backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back,
//               color: Theme.of(context).colorScheme.onSurface),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.bookmark_border,
//               size: 80,
//               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'No Saved Posts',
//               style: TextStyle(
//                 color: Theme.of(context).colorScheme.onSurface,
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40),
//               child: Text(
//                 'Posts you save will appear here. Start saving posts you want to revisit later!',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color:
//                       Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
