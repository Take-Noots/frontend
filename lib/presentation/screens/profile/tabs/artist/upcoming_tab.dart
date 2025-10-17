import 'package:flutter/material.dart';

class ArtistUpcomingTab extends StatelessWidget {
  final String userId;

  const ArtistUpcomingTab({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace with actual upcoming events UI
    return Center(
      child: Text(
        'Upcoming Events (Artist)',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
