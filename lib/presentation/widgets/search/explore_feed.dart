import 'package:flutter/material.dart';

class ExploreFeed extends StatefulWidget {
  final List<String> imageUrls;

  const ExploreFeed({Key? key, required this.imageUrls}) : super(key: key);

  @override
  State<ExploreFeed> createState() => _ExploreFeedState();
}

class _ExploreFeedState extends State<ExploreFeed> {
  late List<String> _validImages;
  final Set<String> _failedImages = {};

  @override
  void initState() {
    super.initState();
    _validImages = List.from(widget.imageUrls);
  }

  @override
  void didUpdateWidget(covariant ExploreFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls != widget.imageUrls) {
      _validImages = List.from(widget.imageUrls);
      _failedImages.clear();
    }
  }

  void _removeInvalidImageAtIndex(int index) {
    if (index >= 0 && index < _validImages.length) {
      final img = _validImages[index];
      _failedImages.add(img);
      setState(() {
        _validImages.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_validImages.isEmpty) {
      return Center(
        child: Text(
          'No posts to explore.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.8,
      ),
      itemCount: _validImages.length,
      itemBuilder: (context, index) {
        final img = _validImages[index];
        final isNetwork = img.startsWith('http');
        return GestureDetector(
          onTap: () {
            // Open a detail popup (Instagram-like) with the tapped image
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => PostDetailDialog(imageUrl: img),
            );
          },
          child: isNetwork
              ? Image.network(
                  img,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _removeInvalidImageAtIndex(index);
                    });
                    return const SizedBox.shrink();
                  },
                )
              : Image.asset(
                  img,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _removeInvalidImageAtIndex(index);
                    });
                    return const SizedBox.shrink();
                  },
                ),
        );
      },
    );
  }
}

// A simple full-screen dialog that displays the tapped image and some dummy
// post details. Keeps UI-only dummy data as requested.
class PostDetailDialog extends StatelessWidget {
  final String imageUrl;

  const PostDetailDialog({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isNetwork = imageUrl.startsWith('http');
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            // Close button aligned to the top-right
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Expanded image area
            Expanded(
              child: isNetwork
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100, color: Colors.white),
                    )
                  : Image.asset(
                      imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
            ),
            // Dummy details similar to an Instagram post
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      CircleAvatar(radius: 18, backgroundColor: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('artist_placeholder',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Icon(Icons.favorite_border),
                      SizedBox(width: 8),
                      Icon(Icons.comment_outlined),
                      SizedBox(width: 8),
                      Icon(Icons.send_outlined),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Song Title — Artist Name',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text(
                    'This is a dummy caption shown for the explore post detail. Replace with real content when integrating.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
