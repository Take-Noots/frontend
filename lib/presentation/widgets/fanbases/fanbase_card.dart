import 'package:flutter/material.dart';
import './fanbase_interations.dart';
import './fanbase_profilebar.dart';

class FanbaseCard extends StatelessWidget {
  final int numLikes;
  final int numPosts;
  final String profileImageUrl;
  final String fanbaseName;
  final String topic;
  final String fanbaseId;
  final bool isJoined;
  final VoidCallback onJoin;

  const FanbaseCard({
    super.key,
    required this.numLikes,
    required this.numPosts,
    required this.profileImageUrl,
    required this.fanbaseName,
    required this.topic,
    required this.fanbaseId,
    required this.isJoined,
    required this.onJoin,
  });

  String truncateText(String text, int maxLength, {bool addEllipsis = true}) {
    if (text.length <= maxLength) return text;
    return addEllipsis ? '${text.substring(0, maxLength)}...' : text.substring(0, maxLength);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/fanbase/$fanbaseId'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: theme.outlineVariant,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row: Profile + Join Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ProfileNameRow(
                  profileImageUrl: profileImageUrl,
                  fanbaseName: truncateText(fanbaseName, 20),
                ),
                OutlinedButton(
                  onPressed: onJoin,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isJoined ? Colors.transparent : Colors.purple,
                    foregroundColor: isJoined ? theme.onPrimary : Colors.white,
                    side: const BorderSide(color: Colors.purple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    // padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  ),
                  child: Text(isJoined ? 'Joined' : 'Join'),
                ),
              ],
            ),

            const SizedBox(height: 14.0),

            /// Topic
            Container(
              width: double.infinity,
              // padding: const EdgeInsets.all(16.0),
              child: Text(
                truncateText(topic, 55),
                style: TextStyle(
                  color: theme.onPrimary,
                  fontSize: 14.5,
                ),
              ),
            ),

            const SizedBox(height: 14.0),

            /// Interaction stats
            FanbaseInterations(
              numLikes: numLikes,
              numPosts: numPosts,
            ),
          ],
        ),
      ),
    );
  }
}
