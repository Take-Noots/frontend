import 'package:flutter/material.dart';
import 'package:frontend/data/models/fanbase_model.dart';

/// About tab shown to non-owner users (general info)
class FanbaseDetailsUserAbout extends StatelessWidget {
  final Fanbase fanbase;

  const FanbaseDetailsUserAbout({super.key, required this.fanbase});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fanbase.fanbaseName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            fanbase.fanbaseTopic,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${fanbase.joinedUserIds.length} members',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'Created by ${fanbase.createdBy.username}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'Created on ${fanbase.createdAt.toLocal().toString().split(' ')[0]}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
