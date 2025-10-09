import 'package:flutter/material.dart';
import '../../../data/services/song_post_service.dart';
import '../../../data/models/post_model.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final SongPostService _songPostService = SongPostService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.post.caption ?? '';
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _songPostService.updatePost(
        widget.post.id,
        _captionController.text.trim().isEmpty ? '' : _captionController.text.trim(),
      );

      if (result['success']) {
        if (mounted) {
          // Show success message
          final snackBar = SnackBar(
            content: Text(result['message'] ?? 'Post updated successfully'),
            backgroundColor: const Color(0xFF8E08EF),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          
          // Wait a bit for the SnackBar to show before navigating back
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            Navigator.of(context).pop(true); // Return true to indicate successful update
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update post'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating post: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
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



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Header
                Text(
                  'Edit Your Post',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Update your caption',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // Album Cover Image (Read-only)
                if (widget.post.albumImage != null && widget.post.albumImage!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.post.albumImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.music_note, size: 80, color: Colors.white),
                      ),
                    ),
                  ),

                // Song Info (Read-only)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.songName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.post.artists,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Caption Input
                Text(
                  'Caption',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _captionController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Write your thoughts about this song...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E08EF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Update Post',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
