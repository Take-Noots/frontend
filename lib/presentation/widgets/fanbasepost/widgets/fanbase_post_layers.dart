import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../screens/fanbasePost/fanbasePost_screen.dart';

// ========== HeaderWidget ==========
class HeaderWidget extends StatelessWidget {
  final String? username;
  final String? userImage;
  final String? trackId;

  const HeaderWidget({
    super.key,
    this.username,
    this.userImage,
    this.trackId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: UserDetailWidget(
            username: username,
            userImage: userImage,
          ),
        ),
        const SongControlWidget(),
      ],
    );
  }
}

// ========== UserDetailWidget ==========
class UserDetailWidget extends StatelessWidget {
  final Map<String, dynamic>? details;
  final String? username;
  final String? userImage;

  const UserDetailWidget({
    super.key,
    this.details,
    this.username,
    this.userImage,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16.0),
            image: userImage != null
                ? DecorationImage(
                    image: userImage!.startsWith('http')
                        ? NetworkImage(userImage!) as ImageProvider
                        : AssetImage(userImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AutoSizeText(
            username ?? 'Unknown User',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              letterSpacing: 0.2,
            ),
            minFontSize: 14,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}

class PostArtWidget extends StatefulWidget {
  final String albumImage;
  final String title;
  final String description;
  final String postId;
  final String trackId;
  final String songName;
  final String artists;
  final List<Map<String, String>> comments;
  final String username;
  final String userImage;
  final bool isLiked;
  final bool isPlaying;
  final bool isCurrentTrack;
  final Color backgroundColor;
  final String fanbaseId; // Make this required

  const PostArtWidget({
    super.key,
    this.albumImage = '',
    this.title = '',
    this.description = '',
    this.postId = '',
    this.trackId = '',
    this.songName = '',
    this.artists = '',
    this.comments = const [],
    this.username = '',
    this.userImage = '',
    this.isLiked = false,
    this.isPlaying = false,
    this.isCurrentTrack = false,
    this.backgroundColor = Colors.black,
    required this.fanbaseId, // Make this required instead of optional with empty string
  });

  @override
  State<PostArtWidget> createState() => _PostArtWidgetState();
}

class _PostArtWidgetState extends State<PostArtWidget> {
  bool _showFull = false;

  void _navigateToPost(BuildContext context) {
    if (widget.postId.isNotEmpty) {
      // Check for empty string instead of null
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailPage(
            postId: widget.postId,
            trackId: widget.trackId,
            songName: widget.songName,
            artists: widget.artists,
            albumImage: widget.albumImage,
            comments: widget.comments,
            username: widget.username,
            userImage: widget.userImage,
            title: widget.title,
            description: widget.description,
            isLiked: widget.isLiked,
            isPlaying: widget.isPlaying,
            isCurrentTrack: widget.isCurrentTrack,
            backgroundColor: widget.backgroundColor,
            fanbaseId: widget.fanbaseId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.description ?? '';
    final title = widget.title ?? '';
    const fixedFontSize = 12.0;

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;
            final double imageSize = totalWidth * 0.20;

            return InkWell(
              onTap: () => _navigateToPost(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  int titleLimit = constraints.maxWidth > 200
                                      ? 35
                                      : constraints.maxWidth > 150
                                          ? 25
                                          : 15;

                                  String responsiveTitle = title.length >
                                          titleLimit
                                      ? title.substring(0, titleLimit) + '...'
                                      : title;

                                  return AutoSizeText(
                                    responsiveTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 10,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              Flexible(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    int descLimit = constraints.maxWidth > 200
                                        ? 100
                                        : constraints.maxWidth > 150
                                            ? 70
                                            : 40;
                                    int maxLines = constraints.maxHeight > 60
                                        ? 3
                                        : constraints.maxHeight > 40
                                            ? 2
                                            : 1;

                                    String responsiveDesc = description.length >
                                            descLimit
                                        ? description.substring(0, descLimit) +
                                            '...'
                                        : description;

                                    return AutoSizeText(
                                      responsiveDesc,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: fixedFontSize,
                                        height: 1.2,
                                      ),
                                      maxLines: maxLines,
                                      minFontSize: 8,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ========== FooterWidget ==========
class FooterWidget extends StatelessWidget {
  final String? songName;
  final String? artists;
  final VoidCallback? onLike; // Add missing callback parameters
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final bool isLiked;
  final int likesCount;
  final int commentsCount;

  const FooterWidget({
    super.key,
    this.songName,
    this.artists,
    this.onLike, // Add to constructor
    this.onComment,
    this.onShare,
    this.isLiked = false,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TrackDetailWidget(
            songName: songName,
            artists: artists,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 1,
          child: InteractionWidget(
            onLike: onLike, // Pass the callbacks to InteractionWidget
            onComment: onComment,
            onShare: onShare,
            isLiked: isLiked,
            likesCount: likesCount,
            commentsCount: commentsCount,
          ),
        ),
      ],
    );
  }
}

// ========== TrackDetailWidget ==========
class TrackDetailWidget extends StatelessWidget {
  final String? songName;
  final String? artists;

  const TrackDetailWidget({
    super.key,
    this.songName,
    this.artists,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          songName ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 241, 241, 241),
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          artists ?? '',
          style: TextStyle(
            fontSize: 13,
            color: const Color.fromARGB(255, 199, 198, 198),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

// ========== SongControlWidget ==========
class SongControlWidget extends StatefulWidget {
  final String? trackId;
  final bool isPlaying;
  final bool isCurrentTrack;
  final VoidCallback? onPlayPause;

  const SongControlWidget({
    super.key,
    this.trackId,
    this.isPlaying = false,
    this.isCurrentTrack = false,
    this.onPlayPause,
  });

  @override
  State<SongControlWidget> createState() => _SongControlWidgetState();
}

class _SongControlWidgetState extends State<SongControlWidget> {
  @override
  Widget build(BuildContext context) {
    const iconColor = Colors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.network(
          'https://cdn-icons-png.flaticon.com/512/174/174872.png',
          width: 24,
          height: 24,
          color: iconColor,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.music_note,
              color: iconColor,
              size: 24,
            );
          },
        ),
        const SizedBox(width: 8),
        if (widget.onPlayPause != null)
          GestureDetector(
            onTap: widget.onPlayPause,
            child: Icon(
              widget.isCurrentTrack && widget.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: iconColor,
              size: 24,
            ),
          ),
      ],
    );
  }
}

// ========== InteractionWidget ==========
class InteractionWidget extends StatelessWidget {
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final bool isLiked;
  final int likesCount;
  final int commentsCount;

  const InteractionWidget({
    super.key,
    this.onLike,
    this.onComment,
    this.onShare,
    this.isLiked = false,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    final likedColor = isDark ? Colors.purple : Colors.deepPurple;
    final textColor = isDark ? Colors.white : Colors.black;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onLike,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? likedColor : iconColor,
                size: 18,
              ),
              if (likesCount > 0)
                Text(
                  '$likesCount',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onComment,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.comment_outlined,
                color: iconColor,
                size: 18,
              ),
              if (commentsCount > 0)
                Text(
                  '$commentsCount',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onShare,
          child: Icon(
            Icons.share,
            color: iconColor,
            size: 18,
          ),
        ),
      ],
    );
  }
}
