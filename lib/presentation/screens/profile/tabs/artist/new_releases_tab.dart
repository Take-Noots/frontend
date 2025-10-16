import 'package:flutter/material.dart';

class ArtistNewReleasesTab extends StatelessWidget {
  final String userId;

  const ArtistNewReleasesTab({Key? key, required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace with actual new releases UI
    return Center(
      child: Text(
        'New Releases (Artist)',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
