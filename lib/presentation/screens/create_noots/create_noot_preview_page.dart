import 'package:flutter/material.dart';

class CreateNootPreviewPage extends StatelessWidget {
  final Map<String, dynamic> track;
  final String songName;
  final String artists;
  final String? albumImage;
  final String caption;
  final Future<void> Function() createPost;

  const CreateNootPreviewPage({
    Key? key,
    required this.track,
    required this.songName,
    required this.artists,
    required this.albumImage,
    required this.caption,
    required this.createPost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Noot')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (albumImage != null && albumImage!.isNotEmpty)
              Image.network(
                albumImage!,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.music_note, size: 100),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: Text('No Image')),
              ),
            const SizedBox(height: 16),
            Text(
              songName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              artists,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Caption:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              caption.isNotEmpty ? caption : '(No caption)',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await createPost();
                    Navigator.of(context).popUntil((route) => route.isFirst); //riderct to the home screen    
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E08EF),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text('Share'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 