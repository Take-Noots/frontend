import 'package:flutter/material.dart';
import 'fanbase_post_layers.dart';

// ========== Post ==========
class Post extends StatelessWidget {
  final String trackId;
  final String postId;
  final String songName;
  final String artists;
  final String albumImage;
  final String caption;
  final String username;
  final String userImage;
  final String descriptionTitle;
  final String description;
  final List<Map<String, String>> comments; // Add this line
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onPlayPause;
  final VoidCallback? onUsernameTap;
  final bool isLiked;
  final bool isPlaying;
  final bool isCurrentTrack;
  final Color backgroundColor;
  final int likesCount;
  final int commentsCount;
  final String fanbaseId;

  const Post({
    super.key,
    this.trackId = '',
    this.postId = '',
    this.songName = '',
    this.artists = '',
    this.albumImage = '',
    this.caption = '',
    required this.username,
    this.userImage = '',
    this.descriptionTitle = '',
    this.description = '',
    this.comments = const [], // Add this line
    this.onLike,
    this.onComment,
    this.onShare,
    this.onPlayPause,
    this.onUsernameTap,
    this.isLiked = false,
    this.isPlaying = false,
    this.isCurrentTrack = false,
    this.backgroundColor = Colors.black,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.fanbaseId, // Make this required, not empty string default
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HeaderWidget(
          username: username,
          userImage: userImage,
          trackId: trackId,
        ),
        PostArtWidget(
          albumImage: albumImage,
          title: descriptionTitle,
          description: description,
          postId: postId,
          trackId: trackId,
          songName: songName,
          artists: artists,
          comments: comments, // Update this line to pass the actual comments
          username: username,
          userImage: userImage,
          isLiked: isLiked,
          isPlaying: isPlaying,
          isCurrentTrack: isCurrentTrack,
          backgroundColor: backgroundColor,
          fanbaseId: fanbaseId, // Add the missing fanbaseId parameter
        ),
        FooterWidget(
          songName: songName,
          artists: artists,
          onLike: onLike, // Add the missing callbacks
          onComment: onComment,
          onShare: onShare,
          isLiked: isLiked,
          likesCount: likesCount,
          commentsCount: commentsCount,
        ),
      ],
    );
  }
}
