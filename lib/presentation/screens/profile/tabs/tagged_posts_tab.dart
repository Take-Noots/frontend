import 'package:flutter/material.dart';

class TaggedPostsTab extends StatelessWidget {
  const TaggedPostsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Tagged posts will appear here.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
