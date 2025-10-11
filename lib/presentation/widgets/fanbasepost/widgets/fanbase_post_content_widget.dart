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
  final String? userId; // Add userId parameter
  final String? currentUserId; // Add currentUserId parameter
  final String userImage;
  final String descriptionTitle;
  final String description;
  final List<Map<String, String>> comments;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onPlayPause;
  final VoidCallback? onUsernameTap;
  final VoidCallback? onMoreOptions; // Add onMoreOptions parameter
  final bool isLiked;
  final bool isPlaying;
  final bool isCurrentTrack;
  final bool isOwnPost; // Add isOwnPost parameter
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
    this.userId, // Add userId parameter
    this.currentUserId, // Add currentUserId parameter
    this.userImage = '',
    this.descriptionTitle = '',
    this.description = '',
    this.comments = const [],
    this.onLike,
    this.onComment,
    this.onShare,
    this.onPlayPause,
    this.onUsernameTap,
    this.onMoreOptions, // Add onMoreOptions parameter
    this.isLiked = false,
    this.isPlaying = false,
    this.isCurrentTrack = false,
    this.isOwnPost = false, // Add isOwnPost parameter
    this.backgroundColor = Colors.black,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.fanbaseId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HeaderWidget(
          username: username,
          userId: userId, // Pass userId to HeaderWidget
          currentUserId: currentUserId, // Pass currentUserId to HeaderWidget
          userImage: userImage,
          trackId: trackId,
          onUsernameTap: onUsernameTap,
          onMoreOptions: onMoreOptions, // Pass onMoreOptions to HeaderWidget
          isOwnPost: isOwnPost, // Pass isOwnPost to HeaderWidget
        ),
        PostArtWidget(
          albumImage: albumImage,
          title: descriptionTitle,
          description: description,
          postId: postId,
          trackId: trackId,
          songName: songName,
          artists: artists,
          comments: comments,
          username: username,
          userImage: userImage,
          isLiked: isLiked,
          isPlaying: isPlaying,
          isCurrentTrack: isCurrentTrack,
          backgroundColor: backgroundColor,
          fanbaseId: fanbaseId,
        ),
        FooterWidget(
          songName: songName,
          artists: artists,
          onLike: onLike,
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
