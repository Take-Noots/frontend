import 'package:flutter/material.dart';
import 'fanbase_post_feed.dart';

class GeneralFanbaseFeedWidget extends StatefulWidget {
  const GeneralFanbaseFeedWidget({Key? key}) : super(key: key);

  @override
  State<GeneralFanbaseFeedWidget> createState() =>
      _GeneralFanbaseFeedWidgetState();
}

class _GeneralFanbaseFeedWidgetState extends State<GeneralFanbaseFeedWidget> {
  // This could fetch posts from multiple fanbases or featured posts
  // For now, you might want to implement a different endpoint for this

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'General fanbase feed\n(implement with multiple fanbase posts)',
        textAlign: TextAlign.center,
      ),
    );
  }
}
