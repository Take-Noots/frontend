import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExploreFeed extends StatefulWidget {
  final List<Map<String, String>> imageUrls;

  const ExploreFeed({Key? key, required this.imageUrls}) : super(key: key);

  @override
  State<ExploreFeed> createState() => _ExploreFeedState();
}

class _ExploreFeedState extends State<ExploreFeed> {
  late List<Map<String, String>> _validImages;
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
      final img = _validImages[index]['albumImage']!;
      if (!_failedImages.contains(img)) {
        _failedImages.add(img);
        setState(() {
          _validImages.removeAt(index);
        });
      }
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
        final imgData = _validImages[index];
        final img = imgData['albumImage']!;
        final isNetwork = img.startsWith('http');
        return GestureDetector(
          onTap: () {
            // Navigate to post details screen with post ID
            context.push('/post/${imgData['id']}');
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


