import 'package:flutter/material.dart';

class ArtistInsightsTab extends StatelessWidget {
  final String userId;

  const ArtistInsightsTab({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace with actual insights UI
    return Center(
      child: Text(
        'Insights (Artist)',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
