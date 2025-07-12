import 'package:flutter/material.dart';

class ProfileNameRow extends StatelessWidget {
  final String profileImageUrl;
  final String fanbaseName;

  const ProfileNameRow({
    required this.profileImageUrl,
    required this.fanbaseName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: AssetImage(profileImageUrl),
          radius: 14.0,
        ),
        SizedBox(width: 12.0),
        Text(
          fanbaseName,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22.0,
          ),
        ),
      ],
    );
  }
}


// import 'package:flutter/material.dart';

// class ProfileNameRow extends StatelessWidget {
//   final String profileImageUrl;
//   final String fanbaseName;

//   const ProfileNameRow({
//     Key? key,
//     required this.profileImageUrl,
//     required this.fanbaseName,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         CircleAvatar(
//           backgroundImage: AssetImage(profileImageUrl),
//           radius: 16.0,
//         ),
//         const SizedBox(width: 12.0),
//         Text(
//           fanbaseName,
//           style: TextStyle(
//             color: Theme.of(context).colorScheme.onPrimary,
//             fontWeight: FontWeight.bold,
//             fontSize: 16.0,
//           ),
//         ),
//       ],
//     );
//   }
// }
