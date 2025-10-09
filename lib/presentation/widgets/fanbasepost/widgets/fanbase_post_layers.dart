import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_svg/svg.dart';
import '../../../screens/fanbasePost/fanbasePost_screen.dart';
import 'post_options_menu.dart'; // Use the local post_options_menu
import 'package:lucide_icons/lucide_icons.dart';

// ========== HeaderWidget ==========
class HeaderWidget extends StatelessWidget {
  final String? username;
  final String? userId;
  final String? currentUserId;
  final String? userImage;
  final String? trackId;
  final VoidCallback? onUsernameTap;
  final VoidCallback? onMoreOptions;
  final VoidCallback? onPlayPause; // Add play/pause callback
  final bool isOwnPost;
  final bool isPlaying; // Add playing state
  final bool isCurrentTrack; // Add current track state

  const HeaderWidget({
    super.key,
    this.username,
    this.userId,
    this.currentUserId,
    this.userImage,
    this.trackId,
    this.onUsernameTap,
    this.onMoreOptions,
    this.onPlayPause, // Add to constructor
    this.isOwnPost = false,
    this.isPlaying = false, // Add to constructor
    this.isCurrentTrack = false, // Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    // return Container(
    //   height: 50, // Fixed height for consistency
    //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    //   child: Row(
    //     children: [
    //       // User details section
    //       Expanded(
    //         child: UserDetailWidget(
    //           username: username,
    //           userId: userId,
    //           currentUserId: currentUserId,
    //           userImage: userImage,
    //           onUsernameTap: onUsernameTap,
    //           onMoreOptions: onMoreOptions,
    //           isOwnPost: isOwnPost,
    //         ),
    //       ),
    //       const SizedBox(width: 12),
    //       // Spotify control pill
    //       SongControlWidget(
    //         trackId: trackId,
    //         isPlaying: isPlaying,
    //         isCurrentTrack: isCurrentTrack,
    //         onPlayPause: onPlayPause,
    //       ),
    //     ],
    //   ),
    // );

    return Expanded(
      flex: 120,
      child: Row(
        children: [
          Expanded(
            child: UserDetailWidget(
              username: username,
              userId: userId,
              currentUserId: currentUserId,
              userImage: userImage,
              onUsernameTap: onUsernameTap,
              onMoreOptions: onMoreOptions,
              isOwnPost: isOwnPost,
            ),
          ),
          const SizedBox(width: 12),
          // Spotify control pill
          SongControlWidget(
            trackId: trackId,
            isPlaying: isPlaying,
            isCurrentTrack: isCurrentTrack,
            onPlayPause: onPlayPause,
          ),
        ],
      ),
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
    // final parentWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark ? Colors.grey[900] : Colors.white;
    final iconColor = isDark ? Colors.white : Colors.black;
    final spotifyAsset = isDark
        ? 'assets/icons/icons-spotify-dark.svg'
        : 'assets/icons/icons-spotify-light.svg';

    return Container(
      height: 30, // Fixed compact height
      width: 80, // Fixed width for pill shape
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius:
            BorderRadius.circular(18.0), // Half of height for perfect pill
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Spotify icon
          SizedBox(
            width: 20,
            height: 20,
            child: SvgPicture.asset(
              spotifyAsset,
              fit: BoxFit.contain,
            ),
          ),
          // Play/Pause button
          if (widget.onPlayPause != null)
            GestureDetector(
              onTap: widget.onPlayPause,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  widget.isCurrentTrack && widget.isPlaying
                      ? LucideIcons.pause
                      : LucideIcons.play,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ========== UserDetailWidget ==========
class UserDetailWidget extends StatelessWidget {
  final Map<String, dynamic>? details;
  final String? username;
  final String? userId;
  final String? currentUserId;
  final String? userImage;
  final VoidCallback? onUsernameTap;
  final VoidCallback? onMoreOptions;
  final bool isOwnPost;

  const UserDetailWidget({
    super.key,
    this.details,
    this.username,
    this.userId,
    this.currentUserId,
    this.userImage,
    this.onUsernameTap,
    this.onMoreOptions,
    this.isOwnPost = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Row(
      children: [
        // Profile picture
        Container(
          width: 32,
          height: 32,
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
        const SizedBox(width: 8),
        // Username
        Expanded(
          child: GestureDetector(
            onTap: onUsernameTap,
            child: Text(
              username ?? 'Unknown User',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Options button
        GestureDetector(
          onTap: () {
            if (onMoreOptions != null) {
              onMoreOptions!();
            } else {
              PostOptionsMenu.show(
                context,
                postUserId: userId,
                currentUserId: currentUserId,
                isOwnPost: isOwnPost,
                onCopyLink: () =>
                    print('Copy link pressed for user: $username'),
                onSavePost: () =>
                    print('Save post pressed for user: $username'),
                onUnfollow: () => print('Unfollow pressed for user: $username'),
                onReport: () => print('Report pressed for user: $username'),
                onEdit: isOwnPost
                    ? () => print('Edit post pressed for user: $username')
                    : null,
                onDelete: isOwnPost
                    ? () => print('Delete post pressed for user: $username')
                    : null,
                onHide: isOwnPost
                    ? () => print('Hide post pressed for user: $username')
                    : null,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.more_vert,
              color: textColor.withOpacity(0.7),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

// ========== PostArtWidget ==========
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
    final description = widget.description;
    final title = widget.title;
    final parentWidth = MediaQuery.of(context).size.width;

    return Container(
      width: parentWidth, // Fixed width to screen width
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
      // decoration: BoxDecoration(
      //   color: Colors.grey[900]?.withOpacity(0.3), // Optional background
      //   borderRadius: BorderRadius.circular(12.0),
      // ),
      child: InkWell(
        onTap: () => _navigateToPost(context),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.all(1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with overflow handling
              SizedBox(
                width: double.infinity,
                child: Text(
                  title.isNotEmpty ? title : "No Title",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: (parentWidth * 0.01).clamp(6.0, 20.0)),
              // Description with overflow handling
              SizedBox(
                width: double.infinity,
                child: Text(
                  description.isNotEmpty ? description : "No Description",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
    final parentWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        SizedBox(width: (parentWidth * 0.04).clamp(6.0, 20.0)),
        Expanded(
          flex: 3,
          child: TrackDetailWidget(
            songName: songName,
            artists: artists,
          ),
        ),
        SizedBox(width: (parentWidth * 0.01).clamp(6.0, 20.0)),
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

    final textColor = Theme.of(context).colorScheme.onPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    songName ?? 'Unknown Track',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    minFontSize: 5,
                    maxFontSize: 14,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                  AutoSizeText(
                    artists != null
                        ? (artists!.length > 20
                            ? '${artists!.substring(0, 20)}...'
                            : artists!)
                        : 'Unknown Artist',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    minFontSize: 4,
                    maxFontSize: 13,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],
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
    final likedColor = Color(0xFFFd535f9);
    // final textColor = isDark ? Colors.white : Colors.black;
    final parentWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // SizedBox(width: (parentWidth * 0.02).clamp(6.0, 20.0)),
        GestureDetector(
          onTap: onLike,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? likedColor : iconColor,
                size: 24,
              ),
            ],
          ),
        ),
        SizedBox(width: (parentWidth * 0.01).clamp(6.0, 20.0)),
        GestureDetector(
          onTap: onComment,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.messageCircle,
                color: iconColor,
                size: 22,
              ),
            ],
          ),
        ),
        SizedBox(width: (parentWidth * 0.01).clamp(6.0, 20.0)),
        GestureDetector(
          onTap: onShare,
          child: Icon(
            LucideIcons.share2,
            color: iconColor,
            size: 22,
          ),
        ),
        // SizedBox(width: (parentWidth * 0.02).clamp(6.0, 20.0)),
      ],
    );
  }
}
