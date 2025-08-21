import 'package:flutter/material.dart';
import '../../../data/models/thoughts_model.dart';

class ThoughtsFeedCard extends StatelessWidget {
  final ThoughtsPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final void Function(String userId)? onUserTap;

  const ThoughtsFeedCard({
    Key? key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onUserTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => onUserTap?.call(post.userId),
                  child: CircleAvatar(
                    child: Text(post.username != null && post.username!.isNotEmpty
                        ? post.username![0].toUpperCase()
                        : '?'),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  post.username ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(post.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.text,
              style: const TextStyle(fontSize: 16),
            ),
            if (post.songName != null && post.songName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (post.artistName != null && post.artistName!.isNotEmpty) ...[
                    Icon(Icons.music_note, size: 20, color: Colors.deepPurple),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${post.songName} - ${post.artistName}',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.music_note, size: 20, color: Colors.deepPurple),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        post.songName!,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]
                ],
              ),
            ],
            if (post.coverImage != null && post.coverImage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.coverImage!,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    height: 120,
                    width: 120,
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.favorite,
                      color: post.likedBy.contains(post.userId)
                          ? Colors.red
                          : Colors.grey),
                  onPressed: onLike,
                ),
                Text('${post.likes}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: onComment,
                ),
                Text('${post.comments.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
