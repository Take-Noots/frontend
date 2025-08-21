import 'package:flutter/material.dart';
import '../../../data/models/group_chat_model.dart';
import '../../../data/services/group_chat_service.dart';
import 'group_details_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupChatId;
  final String currentUserId;

  const GroupChatScreen({
    super.key, 
    required this.groupChatId, 
    required this.currentUserId
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GroupChatService _groupChatService = GroupChatService();
  
  List<GroupMessage> messages = [];
  GroupChat? groupChat;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroupChatData();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadMessages(showLoading: false);
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadGroupChatData() async {
    await Future.wait([
      _loadGroupDetails(),
      _loadMessages(),
    ]);
  }

  Future<void> _loadGroupDetails() async {
    try {
      final result = await _groupChatService.getGroupChatDetails(widget.groupChatId);
      
      if (result['success'] && mounted) {
        setState(() {
          groupChat = GroupChat.fromJson(result['data'], widget.currentUserId);
        });
      }
    } catch (e) {
      print('Error loading group details: $e');
    }
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final result = await _groupChatService.getGroupChatMessages(widget.groupChatId);
      
      if (result['success']) {
        final List<dynamic> messagesData = result['data'];
        final messageList = messagesData.map((json) => GroupMessage.fromJson(json, widget.currentUserId)).toList();
        
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
      final result = await _groupChatService.sendGroupMessage(widget.groupChatId, messageText);
      
      if (result['success']) {
        final newMessage = GroupMessage.fromJson(result['data'], widget.currentUserId);
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
          onTap: () {
            if (groupChat != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupDetailsScreen(
                    groupChat: groupChat!,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              ).then((_) => _loadGroupChatData());
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[600],
                backgroundImage: groupChat?.groupIcon != null && groupChat!.groupIcon!.isNotEmpty
                    ? (groupChat!.groupIcon!.startsWith('http')
                        ? NetworkImage(groupChat!.groupIcon!) as ImageProvider
                        : AssetImage(groupChat!.groupIcon!))
                    : null,
                child: groupChat?.groupIcon == null || groupChat!.groupIcon!.isEmpty
                    ? Icon(
                        Icons.group,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 24,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupChat?.name ?? 'Loading...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      groupChat != null ? '${groupChat!.members.length} members' : '',
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
            onPressed: () {
              if (groupChat != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupDetailsScreen(
                      groupChat: groupChat!,
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                ).then((_) => _loadGroupChatData());
              }
            },
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
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
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
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onPrimary, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
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
            Icon(Icons.chat_bubble_outline, color: Theme.of(context).colorScheme.onPrimary, size: 48),
            const SizedBox(height: 16),
            Text('No messages yet', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18)),
            Text('Start the conversation!', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
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
        return GroupMessageBubble(message: message);
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class GroupMessageBubble extends StatelessWidget {
  final GroupMessage message;

  const GroupMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                  if (!message.isMe)
                    Text(
                      message.senderUsername,
                      style: TextStyle(
                        color: Colors.green[300],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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