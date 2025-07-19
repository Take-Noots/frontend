// import 'package:flutter/material.dart';
// import 'package:auto_size_text/auto_size_text.dart';

// // ========== HeaderWidget ==========
// class HeaderWidget extends StatelessWidget {
//   final String? username;
//   final String? userImage;
//   final String? trackId;

//   const HeaderWidget({
//     super.key,
//     this.username,
//     this.userImage,
//     this.trackId,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           // flex: 359,
//           child: UserDetailWidget(
//             username: username,
//             userImage: userImage,
//           ),
//         ),
//         const Expanded(
//           // flex: 131,
//           child: SongControlWidget(),
//         ),
//       ],
//     );
//   }
// }

// // ========== PostArtWidget ==========
// class PostArtWidget extends StatefulWidget {
//   final String? albumImage;
//   final String? title;
//   final String? description;

//   const PostArtWidget({
//     super.key,
//     this.albumImage,
//     this.title,
//     this.description,
//   });

//   @override
//   State<PostArtWidget> createState() => _PostArtWidgetState();
// }

// class _PostArtWidgetState extends State<PostArtWidget> {
//   bool _showFull = false;

//   @override
//   Widget build(BuildContext context) {
//     final description = widget.description ?? '';
//     const fixedFontSize = 14.0;
//     const descriptionStyle = TextStyle(
//       color: Colors.white70,
//       fontSize: fixedFontSize,
//       height: 1.4,
//     );

//     return Container(
//       margin: const EdgeInsets.all(12),
//       padding: const EdgeInsets.all(16),
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           final double totalWidth = constraints.maxWidth;
//           final double imageSize = totalWidth * 0.35;

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Top Row: Image + Title + Description
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Album Art
//                   Container(
//                     width: imageSize,
//                     height: imageSize,
//                     margin: const EdgeInsets.only(right: 12),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: widget.albumImage != null &&
//                               widget.albumImage!.startsWith('http')
//                           ? Image.network(
//                               widget.albumImage!,
//                               fit: BoxFit.cover,
//                               errorBuilder: (_, __, ___) => Image.asset(
//                                 'assets/images/song.png',
//                                 fit: BoxFit.cover,
//                               ),
//                             )
//                           : Image.asset(
//                               'assets/images/song.png',
//                               fit: BoxFit.cover,
//                             ),
//                     ),
//                   ),

//                   // Title + Dynamic Description
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Title
//                         AutoSizeText(
//                           widget.title ?? 'Unknown Title',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 6),

//                         // Description with Read More
//                         LayoutBuilder(
//                           builder: (context, subConstraints) {
//                             // Measure full description height
//                             final span = TextSpan(
//                               text: description,
//                               style: descriptionStyle,
//                             );
//                             final tp = TextPainter(
//                               text: span,
//                               textDirection: TextDirection.ltr,
//                               maxLines: _showFull ? null : 6,
//                               ellipsis: '...',
//                             )..layout(maxWidth: subConstraints.maxWidth);

//                             final isOverflowing = tp.didExceedMaxLines;

//                             return Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   description,
//                                   style: descriptionStyle,
//                                   overflow: _showFull
//                                       ? TextOverflow.visible
//                                       : TextOverflow.ellipsis,
//                                   maxLines: _showFull ? null : 6,
//                                 ),
//                                 if (isOverflowing && !_showFull)
//                                   GestureDetector(
//                                     onTap: () {
//                                       setState(() {
//                                         _showFull = true;
//                                       });
//                                     },
//                                     child: const Padding(
//                                       padding: EdgeInsets.only(top: 4),
//                                       child: Text(
//                                         'Read More',
//                                         style: TextStyle(
//                                           color: Colors.purple,
//                                           fontSize: fixedFontSize,
//                                           fontWeight: FontWeight.w500,
//                                           decoration: TextDecoration.underline,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                               ],
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// // ========== FooterWidget ==========
// class FooterWidget extends StatelessWidget {
//   final String? songName;
//   final String? artists;

//   const FooterWidget({
//     super.key,
//     this.songName,
//     this.artists,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           // flex: 359,
//           child: TrackDetailWidget(
//             songName: songName,
//             artists: artists,
//           ),
//         ),
//         const Expanded(
//           // flex: 131,
//           child: InteractionWidget(),
//         ),
//       ],
//     );
//   }
// }

// // ========== UserDetailWidget ==========
// class UserDetailWidget extends StatelessWidget {
//   final Map<String, dynamic>? details;
//   final String? username;
//   final String? userImage;

//   const UserDetailWidget({
//     super.key,
//     this.details,
//     this.username,
//     this.userImage,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       child: Container(
//         margin: const EdgeInsets.only(left: 0, bottom: 4.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             SizedBox(
//               height: 40, // or any fixed height you want
//               child: AspectRatio(
//                 aspectRatio: 1,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(16.0),
//                     image: userImage != null
//                         ? DecorationImage(
//                             image: userImage!.startsWith('http')
//                                 ? NetworkImage(userImage!) as ImageProvider
//                                 : AssetImage(userImage!),
//                             fit: BoxFit.cover,
//                           )
//                         : null,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             // Username in AutoSizeText
//             // Expanded(
//             //   child:
//             Align(
//               alignment: Alignment.centerLeft,
//               child: AutoSizeText(
//                 username ?? 'Unknown User',
//                 style: TextStyle(
//                   color: Theme.of(context).brightness == Brightness.dark
//                       ? Colors.white
//                       : Colors.black,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 18,
//                   letterSpacing: 0.2,
//                 ),
//                 minFontSize: 14,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 textAlign: TextAlign.left,
//               ),
//             ),
//             // ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ========== SongControlWidget ==========
// class SongControlWidget extends StatefulWidget {
//   final String? trackId;
//   final bool isPlaying;
//   final bool isCurrentTrack;
//   final VoidCallback? onPlayPause;

//   const SongControlWidget({
//     super.key,
//     this.trackId,
//     this.isPlaying = false,
//     this.isCurrentTrack = false,
//     this.onPlayPause,
//   });

//   @override
//   State<SongControlWidget> createState() => _SongControlWidgetState();
// }

// class _SongControlWidgetState extends State<SongControlWidget> {
//   @override
//   Widget build(BuildContext context) {
//     const iconColor = Colors.white;

//     return Container(
//       margin: const EdgeInsets.all(4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // Spotify icon
//           Image.network(
//             'https://cdn-icons-png.flaticon.com/512/174/174872.png',
//             width: 24,
//             height: 24,
//             color: iconColor,
//             errorBuilder: (context, error, stackTrace) {
//               return const Icon(
//                 Icons.music_note,
//                 color: iconColor,
//                 size: 24,
//               );
//             },
//           ),

//           // Play/Pause icon
//           if (widget.onPlayPause != null)
//             GestureDetector(
//               onTap: widget.onPlayPause,
//               child: Icon(
//                 widget.isCurrentTrack && widget.isPlaying
//                     ? Icons.pause
//                     : Icons.play_arrow,
//                 color: iconColor,
//                 size: 24,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // ========== TrackDetailWidget ==========
// class TrackDetailWidget extends StatelessWidget {
//   final String? songName;
//   final String? artists;

//   const TrackDetailWidget({
//     super.key,
//     this.songName,
//     this.artists,
//   });

//   @override
//   Widget build(BuildContext context) {
//     const textColor = Colors.white;

//     return Expanded(
//       // flex: 300,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start, // match caption layout
//               children: [
//                 Expanded(
//                   child: AutoSizeText(
//                     '${songName ?? 'Unknown Track'} - ${artists ?? 'Unknown Artist'}',
//                     style: const TextStyle(
//                       color: textColor,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                     minFontSize: 8,
//                     maxFontSize: 12,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     textAlign: TextAlign.left,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ========== InteractionWidget ==========
// class InteractionWidget extends StatelessWidget {
//   final VoidCallback? onLike;
//   final VoidCallback? onComment;
//   final VoidCallback? onShare;
//   final bool isLiked;
//   final int likesCount;
//   final int commentsCount;

//   const InteractionWidget({
//     super.key,
//     this.onLike,
//     this.onComment,
//     this.onShare,
//     this.isLiked = false,
//     this.likesCount = 0,
//     this.commentsCount = 0,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final iconColor = isDark ? Colors.white : Colors.black;
//     final likedColor = isDark ? Colors.purple : Colors.deepPurple;
//     final textColor = isDark ? Colors.white : Colors.black;
//     return Expanded(
//       // flex: 140,
//       child: Container(
//         margin: const EdgeInsets.all(4.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Like button
//             GestureDetector(
//               onTap: onLike,
//               child: SizedBox(
//                 // height: 40,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       isLiked ? Icons.favorite : Icons.favorite_border,
//                       color: isLiked ? likedColor : iconColor,
//                       size: 18,
//                     ),
//                     if (likesCount > 0)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 1),
//                         child: Text(
//                           '$likesCount',
//                           style: TextStyle(
//                             color: textColor,
//                             fontSize: 9,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             // Comment button
//             GestureDetector(
//               onTap: onComment,
//               child: SizedBox(
//                 // height: 32,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       Icons.comment_outlined,
//                       color: iconColor,
//                       size: 18,
//                     ),
//                     if (commentsCount > 0)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 1),
//                         child: Text(
//                           '$commentsCount',
//                           style: TextStyle(
//                             color: textColor,
//                             fontSize: 9,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             // Share button
//             GestureDetector(
//               onTap: onShare,
//               child: SizedBox(
//                 // height: 32,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       Icons.share,
//                       color: iconColor,
//                       size: 18,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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

// // ========== PostArtWidget ==========
// class PostArtWidget extends StatefulWidget {
//   final String? albumImage;
//   final String? title;
//   final String? description;

//   const PostArtWidget({
//     super.key,
//     this.albumImage,
//     this.title,
//     this.description,
//   });

//   @override
//   State<PostArtWidget> createState() => _PostArtWidgetState();
// }

// class _PostArtWidgetState extends State<PostArtWidget> {
//   bool _showFull = false;

//   @override
//   Widget build(BuildContext context) {
//     final description = widget.description ?? '';
//     const fixedFontSize = 14.0;
//     const minBoxHeight = 220.0;
//     const maxBoxHeight = 240.0;

//     final descriptionStyle = TextStyle(
//       color: Colors.white70,
//       fontSize: fixedFontSize,
//       height: 1.4,
//     );

//     return Padding(
//       padding: const EdgeInsets.all(12),
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           final double totalWidth = constraints.maxWidth;
//           final double imageSize = totalWidth * 0.35;

//           return Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Album Image
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Container(
//                   width: imageSize,
//                   height: imageSize,
//                   color: Colors.grey.shade800,
//                   child: widget.albumImage != null &&
//                           widget.albumImage!.startsWith('http')
//                       ? Image.network(
//                           widget.albumImage!,
//                           fit: BoxFit.cover,
//                           errorBuilder: (_, __, ___) => Image.asset(
//                             'assets/images/song.png',
//                             fit: BoxFit.cover,
//                           ),
//                         )
//                       : Image.asset(
//                           'assets/images/song.png',
//                           fit: BoxFit.cover,
//                         ),
//                 ),
//               ),
//               const SizedBox(width: 12),

//               // Right-side content
//               Expanded(
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(
//                     minHeight: minBoxHeight,
//                     maxHeight: maxBoxHeight,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       AutoSizeText(
//                         widget.title ?? 'Unknown Title',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 6),

//                       // Description with Read More logic
//                       LayoutBuilder(
//                         builder: (context, subConstraints) {
//                           final span = TextSpan(
//                             text: description,
//                             style: descriptionStyle,
//                           );
//                           final tp = TextPainter(
//                             text: span,
//                             textDirection: TextDirection.ltr,
//                             maxLines: _showFull ? null : 6,
//                             ellipsis: '...',
//                           )..layout(maxWidth: subConstraints.maxWidth);

//                           final isOverflowing = tp.didExceedMaxLines;

//                           return Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 description,
//                                 style: descriptionStyle,
//                                 overflow: _showFull
//                                     ? TextOverflow.visible
//                                     : TextOverflow.ellipsis,
//                                 maxLines: _showFull ? null : 6,
//                               ),
//                               if (isOverflowing && !_showFull)
//                                 GestureDetector(
//                                   onTap: () {
//                                     setState(() {
//                                       _showFull = true;
//                                     });
//                                   },
//                                   child: const Padding(
//                                     padding: EdgeInsets.only(top: 4),
//                                     child: Text(
//                                       'Read More',
//                                       style: TextStyle(
//                                         color: Colors.purple,
//                                         fontSize: fixedFontSize,
//                                         fontWeight: FontWeight.w500,
//                                         decoration: TextDecoration.underline,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                             ],
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
class PostArtWidget extends StatefulWidget {
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
  State<PostArtWidget> createState() => _PostArtWidgetState();
}

class _PostArtWidgetState extends State<PostArtWidget> {
  bool _showFull = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.description ?? '';
    const fixedFontSize = 14.0;
    const minBoxHeight = 220.0;
    const maxBoxHeight = 240.0;

    final descriptionStyle = const TextStyle(
      color: Colors.white70,
      fontSize: fixedFontSize,
      height: 1.4,
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalWidth = constraints.maxWidth;
          final double imageSize = totalWidth * 0.35;
          final double textWidth = totalWidth - imageSize - 12;

          /// Split the description text manually
          final span = TextSpan(text: description, style: descriptionStyle);
          final tp = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
            maxLines: _showFull ? null : 6,
            ellipsis: '...',
          )..layout(maxWidth: textWidth);

          // Estimate how many characters fit beside the image
          int splitIndex = description.length;
          for (int i = description.length; i > 0; i--) {
            final testSpan = TextSpan(
              text: description.substring(0, i),
              style: descriptionStyle,
            );
            final testTp = TextPainter(
              text: testSpan,
              textDirection: TextDirection.ltr,
              maxLines: 6,
              ellipsis: '...',
            )..layout(maxWidth: textWidth);

            if (!testTp.didExceedMaxLines) {
              splitIndex = i;
              break;
            }
          }

          final sideText = description.substring(0, splitIndex).trim();
          final overflowText = description.substring(splitIndex).trim();

          return 
          // ConstrainedBox(
          //   constraints: const BoxConstraints(
          //     minHeight: minBoxHeight,
          //     maxHeight: maxBoxHeight,
          //   ),
          //   child: 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: image + title + side text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Album image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: imageSize,
                        height: imageSize,
                        color: Colors.grey.shade800,
                        child: widget.albumImage != null &&
                                widget.albumImage!.startsWith('http')
                            ? Image.network(
                                widget.albumImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/song.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/images/song.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Right side text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            widget.title ?? 'Unknown Title',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          Text(
                            sideText,
                            style: descriptionStyle,
                            overflow: _showFull
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            maxLines: _showFull ? null : 7,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Overflow part under the image
                if (overflowText.isNotEmpty && !_showFull)
                  const SizedBox(height: 8),

                if (overflowText.isNotEmpty && !_showFull)
                  Text(
                    overflowText,
                    style: descriptionStyle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                if (!_showFull && (tp.didExceedMaxLines || overflowText.isNotEmpty))
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showFull = true;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Read More',
                        style: TextStyle(
                          color: Colors.purple,
                          fontSize: fixedFontSize,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            // ),
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
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TrackDetailWidget(
            songName: songName,
            artists: artists,
          ),
        ),
        const SizedBox(width: 8),
        const Flexible(
          flex: 1,
          child: InteractionWidget(),
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
            color: Colors.grey[600],
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
