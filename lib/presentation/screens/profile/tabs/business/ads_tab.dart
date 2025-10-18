import 'package:flutter/material.dart';

class BusinessAdsTab extends StatelessWidget {
  final String userId;

  const BusinessAdsTab({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace with actual ads UI
    return Center(
      child: Text(
        'Advertisements (Business)',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
