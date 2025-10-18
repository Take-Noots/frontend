import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../data/models/thoughts_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/services/song_post_service.dart';
import '../../../data/services/thoughts_service.dart';
import '../../widgets/thoughts/thoughts_feed_card.dart';
import '../../widgets/song_post/comment.dart';
import '../../widgets/home/header_bar.dart';

class ThoughtFeedScreen extends StatefulWidget {
  final List<ThoughtsPost> posts;
  final String? userId;
  final String? initialPostId;
  final VoidCallback? onRefresh; // Callback to refresh data

  const ThoughtFeedScreen({
    Key? key,
    required this.posts,
    this.userId,
    this.initialPostId,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<ThoughtFeedScreen> createState() => _ThoughtFeedScreenState();
}

class _ThoughtFeedScreenState extends State<ThoughtFeedScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final SongPostService _songPostService = SongPostService();
  final ThoughtsService _thoughtsService = ThoughtsService();
  int _initialIndex = 0;
  String? _currentUserId;
  late List<ThoughtsPost> _posts; // Local mutable list

  @override
  void initState() {
    super.initState();
    _posts = List.from(widget.posts); // Create local mutable copy
    _loadCurrentUserId();
    // Determine initial index if an initialPostId was provided
    if (widget.initialPostId != null && widget.initialPostId!.isNotEmpty) {
      final idx = _posts.indexWhere((p) => p.id == widget.initialPostId);
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

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final userData = userDataString != null
        ? jsonDecode(userDataString)
        : {'id': '685fb750cc084ba7e0ef8533'}; 
    _currentUserId = userData['id'];
  }

  // Method to refresh posts from parent widget
  void refreshPosts() {
    setState(() {
      _posts = List.from(widget.posts);
    });
  }

  void _handleLike(ThoughtsPost post) async {

    String? currentUserId = _currentUserId;
    if (currentUserId == null) {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      final userData = userDataString != null
          ? jsonDecode(userDataString)
          : {'id': '685fb750cc084ba7e0ef8533'}; 
      currentUserId = userData['id'];
    }

   
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ID not found. Please log in again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

   
    setState(() {
      if (post.likedBy.contains(currentUserId!)) {
       
        post.likedBy.remove(currentUserId!);
        post.likes = (post.likes - 1).clamp(0, double.infinity).toInt();
      } else {
       
        post.likedBy.add(currentUserId!);
        post.likes = post.likes + 1;
      }
    });

    
    final result = await _thoughtsService.likeThoughts(post.id, context);

    // Check if the API call was successful
    if (result['success'] != true) {
      // Revert the optimistic update
      if (mounted) {
        setState(() {
          if (post.likedBy.contains(currentUserId!)) {
            post.likedBy.remove(currentUserId!);
            post.likes = (post.likes - 1).clamp(0, double.infinity).toInt();
          } else {
            post.likedBy.add(currentUserId!);
            post.likes = post.likes + 1;
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to like post'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      // Update with server response if available
      if (result['data'] != null) {
        final updatedPost = ThoughtsPost.fromJson(result['data']);
        setState(() {
          post.likes = updatedPost.likes;
          post.likedBy = updatedPost.likedBy;
        });
      }
    }
  }

  void _handleComment(ThoughtsPost post) async {
    // Ensure we have the current user ID
    String? currentUserId = _currentUserId;
    if (currentUserId == null) {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      final userData = userDataString != null
          ? jsonDecode(userDataString)
          : {'id': '685fb750cc084ba7e0ef8533'};
      currentUserId = userData['id'];
    }

    // print('[DEBUG] _handleComment: currentUserId = $currentUserId');
    // print('[DEBUG] _handleComment: post.comments.length = ${post.comments.length}');
    for (int i = 0; i < post.comments.length; i++) {
      final comment = post.comments[i];
    // print('[DEBUG] _handleComment: comment $i - id: ${comment.id}, likedBy: ${comment.likedBy}');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: CommentSection(
          comments: post.comments.map((c) => Comment(
            id: c.id,
            userId: c.userId,
            username: c.username,
            text: c.text,
            createdAt: c.createdAt,
            likes: c.likes,
            likedBy: c.likedBy,
          )).toList(),
          onAddComment: (text) async {
            final prefs = await SharedPreferences.getInstance();
            final userDataString = prefs.getString('user_data');
            final userData = userDataString != null
                ? jsonDecode(userDataString)
                : {'id': '685fb750cc084ba7e0ef8533', 'name': 'owl'};
            final result = await _songPostService.addComment(
                post.id, userData['id'], userData['name'], text, context);
            
           
            bool isSuccess = false;
            if (result['success'] is bool) {
              isSuccess = result['success'];
            } else if (result['success'] is int) {
              isSuccess = result['success'] == 1;
            } else if (result['success'] is String) {
              isSuccess = result['success'].toString().toLowerCase() == 'true';
            }
            
            if (isSuccess && result['data'] != null) {
              final updatedComments =
                  (result['data']['comments'] as List<dynamic>)
                      .map((c) => ThoughtsComment.fromJson(c))
                      .toList();
              setState(() {
                post.comments = updatedComments;
              });
              return updatedComments.map((c) => Comment(
                id: c.id,
                userId: c.userId,
                username: c.username,
                text: c.text,
                createdAt: c.createdAt,
                likes: c.likes,
                likedBy: c.likedBy,
              )).toList();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Failed to add comment'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
              return post.comments.map((c) => Comment(
                id: c.id,
                userId: c.userId,
                username: c.username,
                text: c.text,
                createdAt: c.createdAt,
                likes: c.likes,
                likedBy: c.likedBy,
              )).toList();
            }
          },
          postId: post.id,
          currentUserId: currentUserId ?? '',
          songPostService: _songPostService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NootAppBar(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ScrollablePositionedList.builder(
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return ThoughtsFeedCard(
            post: post,
            onLike: () => _handleLike(post),
            onComment: () => _handleComment(post),
            onPostUpdated: (updatedPost) {
              // Always remove from local list for immediate UI update
              setState(() {
                final index = _posts.indexWhere((p) => p.id == updatedPost.id);
                if (index != -1) {
                  _posts.removeAt(index);
                }
              });
              
              // Also call refresh callback if available
              if (widget.onRefresh != null) {
                widget.onRefresh!();
              }
            },
            onUserTap: (String userId, String? username) {
              // Optionally navigate to the tapped user's profile; left as no-op to avoid
              // introducing additional dependencies here.
            },
          );
        },
      ),
    );
  }
}
