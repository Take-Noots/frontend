import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Noot/data/models/post_model.dart';
import 'package:Noot/data/services/song_post_service.dart';

String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return DateFormat('dd MMM').format(dateTime);
}

class CommentSection extends StatefulWidget {
  final List<Comment> comments;
  final Function(String) onAddComment;
  final String postId;
  final String currentUserId;
  final SongPostService songPostService;
  
  const CommentSection({
    Key? key,
    required this.comments,
    required this.onAddComment,
    required this.postId,
    required this.currentUserId,
    required this.songPostService,
  }) : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late List<Comment> _comments;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;
  bool _isSendingComment = false;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.comments);
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _sendButtonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sendButtonController.dispose();
    super.dispose();
  }

  // Modern color scheme with glassmorphism
  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A23).withOpacity(0.8)  
        : Colors.white.withOpacity(0.9);           
  }

  Color _getCardBlurColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF000000)
        : const Color(0xFFF8F9FD);
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFE8E8F0)
        : const Color(0xFF1A1A2E);
  }

  Color _getSubTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFA0A0B0)
        : const Color(0xFF6B7280);
  }

  Color _getInputBgColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A2E).withOpacity(0.9)  
        : const Color(0xFFF8F9FA).withOpacity(0.95); 
  }

  Color _getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);
  }

  LinearGradient _getGradientOverlay(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.1),
              const Color(0xFFA855F7).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.05),
              const Color(0xFFA855F7).withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF000000)        
            : Colors.white,                 
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            // Modern Avatar with gradient
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF000000),
                                    Color(0xFFA855F7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (comment.username?.isNotEmpty == true 
                                      ? comment.username![0].toUpperCase() 
                                      : '?'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Comment content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        comment.username ?? 'Unknown user',
                                        style: TextStyle(
                                          color: _getTextColor(context),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8, 
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getSubTextColor(context).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          timeAgo(comment.createdAt),
                                          style: TextStyle(
                                            color: _getSubTextColor(context),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    comment.text,
                                    style: TextStyle(
                                      color: _getSubTextColor(context),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Like section
                            Column(
                              children: [
                                GestureDetector(
                                  onTap: () async {
    // print('[DEBUG] Comment like: postId=${widget.postId}, commentId=${comment.id}, userId=${widget.currentUserId}');
                                    final result = await widget.songPostService.likeComment(
                                      widget.postId, 
                                      comment.id, 
                                      widget.currentUserId,
                                      context,
                                    );
                                    
                                    //print('[DEBUG] Comment like result: $result');
                                    //print('[DEBUG] Comment like result keys: ${result.keys}');
                                    
                                    if (result['success'] == true) {
                                      setState(() {
                                        // Handle different response structures
                                        List<dynamic>? commentsList;
                                        
                                        if (result['data']['comments'] != null) {
                                          commentsList = result['data']['comments'] as List<dynamic>;
                                        } else if (result['data'] is List) {
                                          commentsList = result['data'] as List<dynamic>;
                                        } else if (result['comments'] != null) {
                                          commentsList = result['comments'] as List<dynamic>;
                                        }
                                        
                                        if (commentsList != null) {
                                          final updatedComment = commentsList
                                              .where((c) => c['_id'] == comment.id || c['id'] == comment.id)
                                              .firstOrNull;
                                          if (updatedComment != null) {
                                            _comments[index] = Comment.fromJson(updatedComment);
                                          }
                                        } else {
                                          // Fallback: just toggle the like status optimistically
                                          final currentComment = _comments[index];
                                          final isCurrentlyLiked = currentComment.likedBy.contains(widget.currentUserId);
                                          if (isCurrentlyLiked) {
                                            _comments[index] = Comment(
                                              id: currentComment.id,
                                              userId: currentComment.userId,
                                              username: currentComment.username,
                                              text: currentComment.text,
                                              createdAt: currentComment.createdAt,
                                              likes: currentComment.likes - 1,
                                              likedBy: currentComment.likedBy.where((id) => id != widget.currentUserId).toList(),
                                            );
                                          } else {
                                            _comments[index] = Comment(
                                              id: currentComment.id,
                                              userId: currentComment.userId,
                                              username: currentComment.username,
                                              text: currentComment.text,
                                              createdAt: currentComment.createdAt,
                                              likes: currentComment.likes + 1,
                                              likedBy: [...currentComment.likedBy, widget.currentUserId],
                                            );
                                          }
                                        }
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.transparent, 
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      comment.likedBy.contains(widget.currentUserId)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: comment.likedBy.contains(widget.currentUserId)
                                          ? const Color(0xFF800080)
                                          : _getSubTextColor(context),
                                      size: 18,
                                    ),
                                  ),
                                ),
                                if (comment.likes > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${comment.likes}',
                                      style: TextStyle(
                                        color: _getSubTextColor(context),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Modern input section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF000000)     
                  : Colors.white.withOpacity(0.98),           
              border: Border(
                top: BorderSide(
                  color: _getBorderColor(context),
                  width: 1,
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: _getInputBgColor(context),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _getBorderColor(context),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: TextField(
                        controller: _controller,
                        enabled: !_isSendingComment,
                        style: TextStyle(
                          color: _getTextColor(context),
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Share your thoughts...',
                          hintStyle: TextStyle(
                            color: _getSubTextColor(context),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ScaleTransition(
                      scale: _sendButtonScale,
                      child: GestureDetector(
                        onTapDown: _isSendingComment ? null : (_) => _sendButtonController.forward(),
                        onTapUp: _isSendingComment ? null : (_) => _sendButtonController.reverse(),
                        onTapCancel: _isSendingComment ? null : () => _sendButtonController.reverse(),
                        onTap: _isSendingComment ? null : () async {
                          if (_controller.text.trim().isNotEmpty && !_isSendingComment) {
                            setState(() {
                              _isSendingComment = true;
                            });
                            
                            try {
                              final newComments = await widget.onAddComment(_controller.text.trim());
                              setState(() {
                                _comments.clear();
                                _comments.addAll(newComments);
                                _isSendingComment = false;
                              });
                              _controller.clear();
                            } catch (e) {
                              setState(() {
                                _isSendingComment = false;
                              });
                              // Error handling is done in the parent widget
                            }
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFFA855F7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF800080).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isSendingComment
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}