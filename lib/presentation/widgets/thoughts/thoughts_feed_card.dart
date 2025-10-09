import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../data/models/thoughts_model.dart';
import '../despost/widgets/TMP_des_post_bg_container.dart';

class ThoughtsFeedCard extends StatefulWidget {
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
  State<ThoughtsFeedCard> createState() => _ThoughtsFeedCardState();
}

class _ThoughtsFeedCardState extends State<ThoughtsFeedCard> {
  Color? _extractedColor;
  final Color _defaultColor = const Color(0xFF2D1B69);

  @override
  void initState() {
    super.initState();
    _extractColorFromCoverImage();
  }

  Future<void> _extractColorFromCoverImage() async {
    if (widget.post.coverImage != null && widget.post.coverImage!.isNotEmpty) {
      try {
        final PaletteGenerator paletteGenerator =
            await PaletteGenerator.fromImageProvider(
          NetworkImage(widget.post.coverImage!),
          size: const Size(100, 100),
          maximumColorCount: 10,
        );

        Color? extractedColor = paletteGenerator.darkMutedColor?.color ??
            paletteGenerator.darkVibrantColor?.color ??
            paletteGenerator.dominantColor?.color;

        if (extractedColor != null) {
          setState(() {
            _extractedColor = _isDarkEnough(extractedColor)
                ? extractedColor
                : _darkenColor(extractedColor);
          });
        }
      } catch (e) {
        print('Error extracting color: $e');
      }
    }
  }

  bool _isDarkEnough(Color color) {
    double luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance < 0.4;
  }

  Color _darkenColor(Color color) {
    const double factor = 0.6;
    return Color.fromARGB(
      color.alpha,
      (color.red * factor).round(),
      (color.green * factor).round(),
      (color.blue * factor).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _extractedColor ?? _defaultColor;
    const double postAspectRatio = 490 / 350; // Reduced height for more compact card

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 350, // Reduced height constraint
        ),
        child: AspectRatio(
          aspectRatio: postAspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background layer with custom shape
              CustomPaint(
                painter: PostShape(backgroundColor: backgroundColor),
                child: Container(),
              ),
                              // Content layer
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                  child: _ThoughtsContent(
                    post: widget.post,
                    onLike: widget.onLike,
                    onComment: widget.onComment,
                    onUserTap: widget.onUserTap,
                    backgroundColor: _extractedColor ?? _defaultColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThoughtsContent extends StatelessWidget {
  final ThoughtsPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final void Function(String userId)? onUserTap;
  final Color backgroundColor;

  const _ThoughtsContent({
    required this.post,
    this.onLike,
    this.onComment,
    this.onUserTap,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section - moved to top with maximized size
        _ThoughtsHeader(
          post: post,
          onUserTap: onUserTap,
        ),
        const SizedBox(height: 20), // Increased spacing from 12 to 20
        // Main content area with left-right layout - fills entire middle section
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8), // Added top margin to push content down
            child: _ThoughtsBody(
              post: post,
              backgroundColor: backgroundColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Footer section
        _ThoughtsFooter(
          post: post,
          onLike: onLike,
          onComment: onComment,
        ),
      ],
    );
  }
}

class _ThoughtsHeader extends StatelessWidget {
  final ThoughtsPost post;
  final void Function(String userId)? onUserTap;

  const _ThoughtsHeader({
    required this.post,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onUserTap?.call(post.userId),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20.0),
              image: post.userImage != null && post.userImage!.isNotEmpty
                  ? DecorationImage(
                      image: post.userImage!.startsWith('http')
                          ? NetworkImage(post.userImage!) as ImageProvider
                          : AssetImage(post.userImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: post.userImage == null || post.userImage!.isEmpty
                ? Center(
                    child: Text(
                      post.username != null && post.username!.isNotEmpty
                          ? post.username![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            post.username ?? 'Unknown',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          _formatTimestamp(post.createdAt),
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
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

class _ThoughtsBody extends StatelessWidget {
  final ThoughtsPost post;
  final Color backgroundColor;

  const _ThoughtsBody({
    required this.post,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left side - Cover image (minimized height)
        if (post.coverImage != null && post.coverImage!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              post.coverImage!,
              width: 120,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A3B8A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        // Right side - Text content with overflow handling
        Expanded(
          child: _ThoughtsTextContent(
            post: post,
            backgroundColor: backgroundColor,
          ),
        ),
      ],
    );
  }
}

class _FullContentBottomSheet extends StatelessWidget {
  final ThoughtsPost post;
  final Color backgroundColor;

  const _FullContentBottomSheet({
    required this.post,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(1),
            backgroundColor.withOpacity(0.9),
            backgroundColor.withOpacity(0.8),
            backgroundColor.withOpacity(0.7),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover image if available
                  if (post.coverImage != null && post.coverImage!.isNotEmpty) ...[
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          post.coverImage!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A3B8A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 45,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Full text content
                  Text(
                    post.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThoughtsTextContent extends StatefulWidget {
  final ThoughtsPost post;
  final Color backgroundColor;

  const _ThoughtsTextContent({
    required this.post,
    required this.backgroundColor,
  });

  @override
  State<_ThoughtsTextContent> createState() => _ThoughtsTextContentState();
}

class _ThoughtsTextContentState extends State<_ThoughtsTextContent> {
  void _showFullContentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _FullContentBottomSheet(
          post: widget.post,
          backgroundColor: widget.backgroundColor,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.post.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.justify,
                ),
              ),
              if (widget.post.text.length > 200) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _showFullContentBottomSheet,
                  child: const Text(
                    'see more',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}



class _ThoughtsFooter extends StatelessWidget {
  final ThoughtsPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const _ThoughtsFooter({
    required this.post,
    this.onLike,
    this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Left side - Song info with icon
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.music_note,
                  color: Colors.deepPurple,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.songName != null && post.songName!.isNotEmpty)
                        Text(
                          post.songName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (post.artistName != null && post.artistName!.isNotEmpty)
                        Text(
                          post.artistName!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right side - Interaction buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  // Like button
                  GestureDetector(
                    onTap: onLike,
                    child: Icon(
                      post.likedBy.contains(post.userId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: post.likedBy.contains(post.userId)
                          ? Colors.deepPurple
                          : Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Comment button
                  GestureDetector(
                    onTap: onComment,
                    child: const Icon(
                      Icons.comment_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Share button
                  const Icon(
                    Icons.share,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
