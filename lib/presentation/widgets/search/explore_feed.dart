import 'package:flutter/material.dart';

class ExploreFeed extends StatelessWidget {
  final List<String> imageUrls;

  const ExploreFeed({Key? key, required this.imageUrls}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
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
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final img = imageUrls[index];
        final isNetwork = img.startsWith('http');
        return GestureDetector(
          onTap: () {
            // TODO: Open post or reel details
          },
          child: isNetwork
              ? Image.network(
                  img,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.network(
                    'https://picsum.photos/seed/picsum/200/300',
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  img,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
        );
      },
    );
  }
}
