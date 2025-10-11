import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../data/models/thoughts_model.dart';
import '../../widgets/thoughts/thoughts_feed_card.dart';
import '../../widgets/home/header_bar.dart';

class ThoughtFeedScreen extends StatefulWidget {
  final List<ThoughtsPost> posts;
  final String? userId;
  final String? initialPostId;

  const ThoughtFeedScreen({
    Key? key,
    required this.posts,
    this.userId,
    this.initialPostId,
  }) : super(key: key);

  @override
  State<ThoughtFeedScreen> createState() => _ThoughtFeedScreenState();
}

class _ThoughtFeedScreenState extends State<ThoughtFeedScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int _initialIndex = 0;

  @override
  void initState() {
    super.initState();
    // Determine initial index if an initialPostId was provided
    if (widget.initialPostId != null && widget.initialPostId!.isNotEmpty) {
      final idx = widget.posts.indexWhere((p) => p.id == widget.initialPostId);
      if (idx != -1) _initialIndex = idx;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemScrollController.isAttached && _initialIndex > 0) {
        try {
          _itemScrollController.jumpTo(index: _initialIndex);
        } catch (e) {
          // ignore scroll errors
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NootAppBar(),
      backgroundColor: Colors.black,
      body: ScrollablePositionedList.builder(
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          final post = widget.posts[index];
          return ThoughtsFeedCard(
            post: post,
            onLike: () {
              // no-op here; liking handled elsewhere in the app
            },
            onComment: () {
              // no-op - could navigate to detailed comment view later
            },
            onUserTap: (userId) {
              // Optionally navigate to the tapped user's profile; left as no-op to avoid
              // introducing additional dependencies here.
            },
          );
        },
      ),
    );
  }
}
