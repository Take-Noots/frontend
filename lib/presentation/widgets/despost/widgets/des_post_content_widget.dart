import 'package:flutter/material.dart';
import './des_post_layers.dart';

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
  final VoidCallback? onPlay;
  final bool isLiked;
  final bool isPlaying;

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
    this.onPlay,
    this.isLiked = false,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          HeaderWidget(
            username: username,
            userImage: userImage,
            trackId: trackId,
          ),
          Expanded(
            flex: 4,
            child: PostArtWidget(
              albumImage: albumImage,
              title: descriptionTitle,
              description: description,
            ),
          ),
          FooterWidget(
            songName: songName,
            artists: artists,
          ),
        ],
      ),
    );
  }
}
