import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
      children: [
        Expanded(
          flex: 359,
          child: UserDetailWidget(
            username: username,
            userImage: userImage,
          ),
        ),
        const Expanded(
          flex: 131,
          child: SongControlWidget(),
        ),
      ],
    );
  }
}

// ========== PostArtWidget ==========
class PostArtWidget extends StatelessWidget {
  final String? albumImage;
  final String? title;
  final String? description;

  const PostArtWidget({
    super.key,
    this.albumImage,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(9.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalHeight = constraints.maxWidth; // assume square
          final double imageHeight = totalHeight * 0.25;

          return Column(
            children: [
              // Top Row (Image + Title + Partial Description)
              Row(
                children: [
                  // Left: Image
                  SizedBox(
                    width: constraints.maxWidth * 0.5,
                    height: imageHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: albumImage != null && albumImage!.startsWith('http')
                          ? Image.network(
                              albumImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/song.png',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/song.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // Right: Title and first lines of description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          title ?? 'Unknown Track',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          minFontSize: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        AutoSizeText(
                          description ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          minFontSize: 8,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom Row: Remaining description
              AutoSizeText(
                description ?? 'No description available.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
                minFontSize: 8,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ========== FooterWidget ==========
class FooterWidget extends StatelessWidget {
  final String? songName;
  final String? artists;

  const FooterWidget({
    super.key,
    this.songName,
    this.artists,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 359,
          child: TrackDetailWidget(
            songName: songName,
            artists: artists,
          ),
        ),
        const Expanded(
          flex: 131,
          child: InteractionWidget(),
        ),
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
    return 
    // Container(
    //   // flex: 359,
    //   child: 
      Container(
        margin: const EdgeInsets.only(left: 0, bottom: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Image - taking maximum height possible
            AspectRatio(
              // size: 5.0,
              aspectRatio: 1,
              child: Container(
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
            ),
            const SizedBox(width: 12),
            // Username in AutoSizeText
            // Expanded(
            //   child: 
              Align(
                alignment: Alignment.centerLeft,
                child: AutoSizeText(
                  username ?? 'Unknown User',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
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
            // ),
          ],
        ),
      // ),
    );
  }
}

// ========== SongControlWidget ==========
class SongControlWidget extends StatelessWidget {
  final String? trackId;

  const SongControlWidget({super.key, this.trackId});

  @override
  Widget build(BuildContext context) {
    return 
    // Expanded(
    //   // flex: 131,
    //   child: 
      Container(
        margin: const EdgeInsets.all(4.0),
        child: const Center(
          child: Text(
            'Song Control',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      // ),
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
    return 
    // Expanded(
    //   flex: 359,
    //   child: 
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Song name - larger and bolder
            AutoSizeText(
              songName ?? 'Unknown Track',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              minFontSize: 8,
              maxFontSize: 12,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 2), // Reduced spacing
            // Artists - smaller text
            AutoSizeText(
              artists ?? 'Unknown Artist',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w300,
              ),
              minFontSize: 4,
              maxFontSize: 10,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ],
        ),
      // ),
    );
  }
}

// ========== InteractionWidget ==========
class InteractionWidget extends StatelessWidget {
  const InteractionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return 
    // Expanded(
    //   flex: 131,
    //   child: 
      Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.black.withOpacity(0.3)),
        ),
        child: const Center(
          child: Text(
            'Interactions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      // ),
    );
  }
}
