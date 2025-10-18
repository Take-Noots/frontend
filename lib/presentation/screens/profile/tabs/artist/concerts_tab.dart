import 'package:flutter/material.dart';

class ArtistConcertsTab extends StatelessWidget {
  final String userId;

  const ArtistConcertsTab({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace with actual concerts UI
    return Center(
      child: Text(
        'Concerts (Artist)',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
