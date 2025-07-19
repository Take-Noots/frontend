import 'package:flutter/material.dart';
import './des_post_layers.dart';

// ========== Post ==========
class Post extends StatelessWidget {
  final String? trackId;
  final String? songName;
  final String? artists;
  final String? albumImage;
  final String? caption;
  final String username;
  final String? userImage;
  final String? descriptionTitle;
  final String? description;

  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onPlayPause;
  final VoidCallback? onUsernameTap;
  final bool isLiked;
  final bool isPlaying;
  final bool isCurrentTrack;

  const Post({
    super.key,
    this.trackId,
    this.songName,
    this.artists,
    this.albumImage,
    this.caption,
    required this.username,
    this.userImage,
    this.descriptionTitle,
    this.description,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onPlayPause,
    this.onUsernameTap,
    this.isLiked = false,
    this.isPlaying = false,
    this.isCurrentTrack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisSize: MainAxisSize.min,
      children: [
        HeaderWidget(
          username: username,
          userImage: userImage,
          trackId: trackId,
          // isPlaying: isPlaying,
          // isCurrentTrack: isCurrentTrack,
          // onPlayPause: onPlayPause,
          // onUsernameTap: onUsernameTap, // <-- Pass callback
        ),
        PostArtWidget(
          albumImage: albumImage,
          title: descriptionTitle,
          description: description,
        ),
        FooterWidget(
          songName: songName,
          artists: artists,
          // onLike: onLike,
          // onComment: onComment,
          // onShare: onShare,
          // isLiked: isLiked,
        ),
      ],
    );
  }
}