import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import './widgets/des_post_content_widget.dart';
import './widgets/des_post_bg_container.dart';

class FeedWidget extends StatefulWidget {
  const FeedWidget({Key? key}) : super(key: key);

  @override
  State<FeedWidget> createState() => _FeedWidgetState();
}

class _FeedWidgetState extends State<FeedWidget> {
  final List<Map<String, dynamic>> feedPosts = [
    {
      "_id": "686b967060b0a052ded69195",
      "trackId": "12VqMTtUAuHwsWRSGYTZRE",
      "songName": "ATLAS",
      "artists": "Pretty Patterns",
      "albumImage":
          "https://i.scdn.co/image/ab67616d0000b273371ea9340b6b2157e8adc10f",
      "caption": "guliguli",
      "username": "owl",
      "title": "ATLAS by Pretty Patterns",
      "description":
          "ATLAS by Pretty Patterns is a richly layered composition that evokes the feeling of wandering through a dreamscape. With its hypnotic rhythms and delicate synth textures, the track opens like a slow unfurling of space and time. Gentle melodic lines intertwine with atmospheric pads, creating a sense of movement—like floating through constellations or navigating the vast unknown. The production balances minimalism with complexity, never overwhelming, but always evolving. Subtle electronic flourishes and ambient echoes give the track an almost cinematic quality, making it perfect for introspection, night drives, or quiet creative sessions. It's both grounding and expansive—an emotional journey that seems to tell a story without words. Pretty Patterns shows impressive control here, delivering a track that is both intimate and infinite.",
    },
    {
      "_id": "686b966920b0a052ded69192",
      "trackId": "6K6wDKxAKY3yRoWnf7O2fT",
      "songName": "BLUESTAR",
      "artists": "Pretty Patterns",
      "albumImage":
          "https://i.scdn.co/image/ab67616d0000b27358b2eb8669e1197a203afb3f",
      "caption": "hehe",
      "username": "owl",
      "title": "BLUESTAR by Pretty Patterns",
      "description":
          "In BLUESTAR, Pretty Patterns crafts an ethereal soundscape that transcends genre boundaries. The track shimmers with a dreamlike ambiance, where softly plucked guitars and airy synths coexist in perfect harmony...",
    },
    {
      "_id": "686b966060b0a052ded69190",
      "trackId": "406IpEtZPvbxApWTGM3twY",
      "songName": "HOT",
      "artists": "LE SSERAFIM",
      "albumImage":
          "https://i.scdn.co/image/ab67616d0000b27386efcf81bf1382daa2d2afe6",
      "caption": "huh",
      "username": "owl",
      "title": "HOT by LE SSERAFIM",
      "description": "A high-energy track that combines pop and hip-hop influences.",
    }
  ];

  final Map<String, Color> _extractedColors = {};
  final Color _defaultColor = const Color.fromARGB(255, 17, 37, 37);

  @override
  void initState() {
    super.initState();
    _extractColorsFromAlbumImages();
  }

  Future<void> _extractColorsFromAlbumImages() async {
    for (final post in feedPosts) {
      final albumImageUrl = post['albumImage'] as String;
      if (!_extractedColors.containsKey(albumImageUrl)) {
        try {
          final PaletteGenerator paletteGenerator =
              await PaletteGenerator.fromImageProvider(
            NetworkImage(albumImageUrl),
            size: const Size(100, 100),
            maximumColorCount: 10,
          );

          Color? extractedColor = paletteGenerator.darkMutedColor?.color ??
              paletteGenerator.darkVibrantColor?.color ??
              paletteGenerator.dominantColor?.color;

          if (extractedColor != null) {
            setState(() {
              _extractedColors[albumImageUrl] = _isDarkEnough(extractedColor)
                  ? extractedColor
                  : _darkenColor(extractedColor);
            });
          } else {
            setState(() {
              _extractedColors[albumImageUrl] = _defaultColor;
            });
          }
        } catch (e) {
          print('Error extracting color: $e');
          setState(() {
            _extractedColors[albumImageUrl] = _defaultColor;
          });
        }
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: feedPosts.length,
          itemBuilder: (context, index) {
            final post = feedPosts[index];
            return _buildPostItem(post);
          },
        ),
      ),
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post) {
    final albumImageUrl = post['albumImage'] as String;
    final backgroundColor = _extractedColors[albumImageUrl] ?? _defaultColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: AspectRatio(
        aspectRatio: 496 / 455, // Maintain a fixed aspect ratio
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: PostShape(backgroundColor: backgroundColor),
              ),
            ),
            Post(
              trackId: post['trackId'],
              songName: post['songName'],
              artists: post['artists'],
              albumImage: post['albumImage'],
              caption: post['caption'],
              username: post['username'] ?? 'Unknown User',
              userImage: 'assets/images/profile_picture.jpg',
              descriptionTitle: post['title'],
              description: post['description'],
              onLike: () => print('Liked post: ${post['_id']}'),
              onComment: () => print('Comment: ${post['_id']}'),
              // onPlay: () => print('Play: ${post['_id']}'),
              isLiked: false,
              isPlaying: false,
            ),
          ],
        ),
      ),
    );
  }

//   Widget _buildPostItem(Map<String, dynamic> post) {
//   final albumImageUrl = post['albumImage'] as String;
//   final backgroundColor = _extractedColors[albumImageUrl] ?? _defaultColor;

//   return Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//     child: LayoutBuilder(
//       builder: (context, constraints) {
//         return ConstrainedBox(
//           constraints: const BoxConstraints(
//             minHeight: 220,
//             maxHeight: 455, // allows growth but caps it
//           ),
//           child: Container(
//             clipBehavior: Clip.hardEdge,
//             decoration: const BoxDecoration(),
//             child: Stack(
//               children: [
//                 // Background painter fills height naturally
//                 Positioned.fill(
//                   child: CustomPaint(
//                     painter: PostShape(backgroundColor: backgroundColor),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Post(
//                     trackId: post['trackId'],
//                     songName: post['songName'],
//                     artists: post['artists'],
//                     albumImage: post['albumImage'],
//                     caption: post['caption'],
//                     username: post['username'] ?? 'Unknown User',
//                     userImage: 'assets/images/profile_picture.jpg',
//                     descriptionTitle: post['title'],
//                     description: post['description'],
//                     onLike: () => print('Liked post: ${post['_id']}'),
//                     onComment: () => print('Comment: ${post['_id']}'),
//                     isLiked: false,
//                     isPlaying: false,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     ),
//   );
// }

}
