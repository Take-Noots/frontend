import 'package:flutter/material.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/services/profile_service.dart';
import 'user_profile_screen.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final String currentUserId;

  const ChatScreen(
      {super.key, required this.chat, required this.currentUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  List<Message> messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && !_isLoading) {
        _loadMessages(showLoading: false);
      }
    });
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final result = await _chatService.getChatMessages(widget.chat.id);

      if (result['success']) {
        final List<dynamic> messagesData = result['data'];
        final messageList = messagesData
            .map((json) => Message.fromJson(json, widget.currentUserId))
            .toList();

        if (mounted) {
          setState(() {
            messages = messageList;
            if (showLoading) _isLoading = false;
          });

          if (showLoading) _scrollToBottom();
        }
      } else {
        if (mounted && showLoading) {
          setState(() {
            _error = result['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted && showLoading) {
        setState(() {
          _error = 'Error loading messages: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final result =
          await _chatService.sendMessage(widget.chat.id, messageText);

      if (result['success']) {
        final newMessage =
            Message.fromJson(result['data'], widget.currentUserId);
        setState(() {
          messages.add(newMessage);
          _isSending = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _isSending = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
        // Restore the message text if sending failed
        _messageController.text = messageText;
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Restore the message text if sending failed
      _messageController.text = messageText;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: widget.chat.user.id,
          username: widget.chat.user.username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _navigateToProfile,
          child: Row(
            children: [
              ProfilePictureWidget(
                userId: widget.chat.user.id,
                radius: 20,
                showOnlineIndicator: true,
                isOnline: widget.chat.user.isOnline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chat.user.username,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.chat.user.isOnline
                          ? 'Online'
                          : widget.chat.user.lastSeen,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: _navigateToProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: _buildMessagesContent(),
            ),

            // Message input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        maxLines: null,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isSending,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.green,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.green,
                          ),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.onPrimary, size: 48),
            const SizedBox(height: 16),
            Text(_error!,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadMessages(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                color: Theme.of(context).colorScheme.onPrimary, size: 48),
            const SizedBox(height: 16),
            Text('No messages yet',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18)),
            Text('Send the first message!',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageBubble(message: message);
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            const CircleAvatar(
              radius: 12,
              backgroundImage: AssetImage('assets/images/hehe.png'),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isMe
                    ? Colors.green
                    : Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isMe
                          ? Colors.white
                          : Theme.of(context).colorScheme.onPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isMe
                          ? Colors.white70
                          : Theme.of(context).colorScheme.secondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 12,
              backgroundImage: AssetImage('assets/images/hehe.png'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }
}

// ProfilePictureWidget to fetch and display real profile pictures
class ProfilePictureWidget extends StatefulWidget {
  final String? userId;
  final double radius;
  final bool showOnlineIndicator;
  final bool isOnline;

  const ProfilePictureWidget({
    super.key,
    required this.userId,
    required this.radius,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
  }

  @override
  void didUpdateWidget(ProfilePictureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _fetchProfileImage();
    }
  }

  Future<void> _fetchProfileImage() async {
    if (widget.userId == null || widget.userId!.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final profileService = ProfileService();
      final profileResult = await profileService.getUserProfile(widget.userId!);

      if (profileResult['success'] == true && profileResult['data'] != null) {
        final profileData = profileResult['data'];
        if (mounted) {
          setState(() {
            profileImageUrl = profileData['profileImage'] as String?;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _openUserProfile(BuildContext context) async {
    if (widget.userId == null || widget.userId!.isEmpty) return;

    try {
      String username = 'User'; // Default username (non-nullable)

      // Try to get username
      final profileResult = await ProfileService().getUserProfile(widget.userId!);
      if (profileResult['success'] == true && profileResult['data'] != null) {
        username = profileResult['data']['username'] ?? 'User';
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            userId: widget.userId!,
            username: username,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load user profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openUserProfile(context),
      child: Stack(
        children: [
          isLoading
              ? CircleAvatar(
                  radius: widget.radius,
                  backgroundColor: Colors.grey[300],
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : CircleAvatar(
                  radius: widget.radius,
                  backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                      ? NetworkImage(profileImageUrl!)
                      : const AssetImage('assets/images/hehe.png') as ImageProvider,
                ),
          if (widget.showOnlineIndicator && widget.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: widget.radius * 0.6,
                height: widget.radius * 0.6,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
