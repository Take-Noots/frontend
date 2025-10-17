import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/musicplayer_bar.dart';
import '../../../data/services/song_post_service.dart';
import 'create_noot_preview_page.dart';
import '../../widgets/create_post/button.dart';
import '../../../core/router/route_names.dart';
import '../../../core/styles/app_colors.dart';

class CreateNewNootPage extends StatefulWidget {
  final Map<String, dynamic> track;

  const CreateNewNootPage({Key? key, required this.track}) : super(key: key);

  @override
  State<CreateNewNootPage> createState() => _CreateNewNootPageState();
}

class _CreateNewNootPageState extends State<CreateNewNootPage> {
  final TextEditingController _captionController = TextEditingController();
  final SongPostService _songPostService = SongPostService();
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final track = widget.track;
      final String trackId = track['id'] ?? '';
      final String songName = track['name'] ?? '';
      final String artists = track['artists'] is List
          ? track['artists'].join(", ")
          : track['artists'].toString();
      final String? albumImage = track['album'];
      final String caption = _captionController.text.trim();

      final result = await _songPostService.createPost(
        trackId: trackId,
        songName: songName,
        artists: artists,
        albumImage: albumImage,
        caption: caption.isNotEmpty ? caption : null,
        context: context,
      );

      if (result['success']) {
       
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppColors.primaryPurple,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 2),
            ),
          );
          // Navigate back to home screen
          context.go(AppRoutes.home);
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPreview() {
    final track = widget.track;
    final String songName = track['name'] ?? '';
    final String artists = track['artists'] is List
        ? track['artists'].join(", ")
        : track['artists'].toString();
    final String? albumImage = track['album'];
    final String caption = _captionController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNootPreviewPage(
          track: track,
          songName: songName,
          artists: artists,
          albumImage: albumImage,
          caption: caption,
          createPost: _createPost,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final String songName = track['name'] ?? '';
    final String artists = track['artists'] is List
        ? track['artists'].join(", ")
        : track['artists'].toString();
    final String? albumImage = track['album'];

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Noot')),
      body: Column(
        children: [
          if (albumImage != null && albumImage.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.45,
              child: Center(
                child: Image.network(albumImage,
                    fit: BoxFit.cover,
                    width: 500,
                    height: 400,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.music_note, size: 100)),
              ),
            )
          else
            Container(
              color: Colors.grey[300],
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.35,
              child: const Center(
                  child: Text('No Image', style: TextStyle(fontSize: 18))),
            ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: TextField(
              controller: _captionController,
              maxLines: 3,
              cursorColor: Colors.grey,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Caption',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '$songName  •  $artists',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Spacer(),
          //Preview and Share buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: PreviewShareButtonRow(
              onPreview: _showPreview,
              onShare: _createPost,
              isLoading: _isLoading,
              shareText: 'Post',
            ),
          ),
        ],
      ),
    );
  }
}