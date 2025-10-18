import 'package:flutter/material.dart';

class BusinessAdInsightsTab extends StatelessWidget {
  final String userId;

  const BusinessAdInsightsTab({Key? key, required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace with actual ad insights UI
    return Center(
      child: Text(
        'Ad Insights (Business)',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
