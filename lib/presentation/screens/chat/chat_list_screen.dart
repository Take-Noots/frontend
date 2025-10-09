import 'package:flutter/material.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/group_chat_model.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/services/group_chat_service.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'create_group_screen.dart';
import 'user_profile_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final GroupChatService _groupChatService = GroupChatService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Chat> chats = [];
  List<GroupChat> groupChats = [];
  List<SearchUser> searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _showSearchResults = false;
  String? _error;
  String? currentUserId;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndChats();
    _searchController.addListener(_onSearchChanged);
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && !_isLoading) {
        _loadChats(showLoading: false);
      }
    });
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _showSearchResults = false;
        searchResults.clear();
      });
    } else {
      _searchUsers(_searchController.text);
    }
  }

  Future<void> _loadUserIdAndChats() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final userData = userDataString != null
        ? jsonDecode(userDataString)
        : {'id': '685fb750cc084ba7e0ef8533'}; // Fallback for testing
    setState(() {
      currentUserId = userData['id'];
    });
    await _loadChats();
  }

  Future<void> _loadChats({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Load both regular chats and group chats
      final results = await Future.wait([
        _chatService.getUserChats(),
        _groupChatService.getUserGroupChats(),
      ]);

      final chatsResult = results[0];
      final groupChatsResult = results[1];
      
      if (chatsResult['success'] && groupChatsResult['success']) {
        final List<dynamic> chatsData = chatsResult['data'];
        final List<dynamic> groupChatsData = groupChatsResult['data'];
        
        final chatList = chatsData.map((json) => Chat.fromJson(json, currentUserId!)).toList();
        final groupChatList = groupChatsData.map((json) => GroupChat.fromJson(json, currentUserId!)).toList();
        
        if (mounted) {
          setState(() {
            chats = chatList;
            groupChats = groupChatList;
            if (showLoading) _isLoading = false;
          });
        }
      } else {
        if (mounted && showLoading) {
          setState(() {
            _error = chatsResult['message'] ?? groupChatsResult['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted && showLoading) {
        setState(() {
          _error = 'Error loading chats: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final result = await _chatService.searchUsers(query.trim());
      
      if (result['success']) {
        final List<dynamic> usersData = result['data'];
        final userList = usersData
            .where((user) => user['_id'] != currentUserId) // Exclude current user
            .map((json) => SearchUser.fromJson(json))
            .toList();
        
        setState(() {
          searchResults = userList;
          _showSearchResults = true;
          _isSearching = false;
        });
      } else {
        setState(() {
          searchResults = [];
          _showSearchResults = true;
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        searchResults = [];
        _showSearchResults = true;
        _isSearching = false;
      });
    }
  }

  Future<void> _startChat(SearchUser user) async {
    try {
      final result = await _chatService.createChat(user.id);
      
      if (result['success']) {
        final chatData = result['data'];
        final newChat = Chat.fromJson(chatData, currentUserId!);
        
        // Clear search and refresh chats
        _searchController.clear();
        setState(() {
          _showSearchResults = false;
          searchResults.clear();
        });
        
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chat: newChat,
              currentUserId: currentUserId!,
            ),
          ),
        ).then((_) => _loadChats());
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.group_add,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              ).then((_) => _loadChats());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            
            // Content area
            Expanded(
              child: _showSearchResults ? _buildSearchResults() : _buildChatList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, color: Theme.of(context).colorScheme.onPrimary, size: 48),
            const SizedBox(height: 16),
            Text('No users found', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18)),
            Text('Try a different username', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final user = searchResults[index];
        return SearchUserItem(
          user: user,
          onStartChat: () => _startChat(user),
        );
      },
    );
  }

  Widget _buildChatList() {
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
              onPressed: () => _loadChats(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (chats.isEmpty && groupChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, color: Theme.of(context).colorScheme.onPrimary, size: 48),
            const SizedBox(height: 16),
            Text('No chats yet', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18)),
            Text('Search for users to start chatting!', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
      );
    }

    // Combine and sort chats and group chats by last activity
    final allChats = <dynamic>[];
    allChats.addAll(chats);
    allChats.addAll(groupChats);
    
    // Sort by last message timestamp
    allChats.sort((a, b) {
      final aTime = a.lastMessage?.timestamp ?? (a is GroupChat ? a.createdAt : DateTime(2000));
      final bTime = b.lastMessage?.timestamp ?? (b is GroupChat ? b.createdAt : DateTime(2000));
      return bTime.compareTo(aTime);
    });

    return RefreshIndicator(
      onRefresh: () => _loadChats(),
      child: ListView.builder(
        itemCount: allChats.length,
        itemBuilder: (context, index) {
          final chatItem = allChats[index];
          
          if (chatItem is Chat) {
            return ChatListItem(
              chat: chatItem,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chat: chatItem,
                      currentUserId: currentUserId!,
                    ),
                  ),
                ).then((_) => _loadChats());
              },
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      userId: chatItem.user.id,
                      username: chatItem.user.username,
                    ),
                  ),
                );
              },
            );
          } else if (chatItem is GroupChat) {
            return GroupChatListItem(
              groupChat: chatItem,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupChatScreen(
                      groupChatId: chatItem.id,
                      currentUserId: currentUserId!,
                    ),
                  ),
                ).then((_) => _loadChats());
              },
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class SearchUserItem extends StatelessWidget {
  final SearchUser user;
  final VoidCallback onStartChat;

  const SearchUserItem({
    super.key,
    required this.user,
    required this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onStartChat,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                  ? (user.profileImage!.startsWith('http')
                      ? NetworkImage(user.profileImage!) as ImageProvider
                      : AssetImage(user.profileImage!))
                  : const AssetImage('assets/images/hehe.png'),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (user.email.isNotEmpty)
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Start Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  final VoidCallback onProfileTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: chat.user.profileImage != null && chat.user.profileImage!.isNotEmpty
                        ? (chat.user.profileImage!.startsWith('http')
                            ? NetworkImage(chat.user.profileImage!) as ImageProvider
                            : AssetImage(chat.user.profileImage!))
                        : const AssetImage('assets/images/hehe.png'),
                  ),
                  if (chat.user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
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
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: onProfileTap,
                        child: Text(
                          chat.user.username,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (chat.lastMessage != null)
                        Text(
                          _formatTime(chat.lastMessage!.timestamp),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage?.text ?? 'Start a conversation',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chat.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}

class GroupChatListItem extends StatelessWidget {
  final GroupChat groupChat;
  final VoidCallback onTap;

  const GroupChatListItem({
    super.key,
    required this.groupChat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[600],
              backgroundImage: groupChat.groupIcon != null && groupChat.groupIcon!.isNotEmpty
                  ? (groupChat.groupIcon!.startsWith('http')
                      ? NetworkImage(groupChat.groupIcon!) as ImageProvider
                      : AssetImage(groupChat.groupIcon!))
                  : null,
              child: groupChat.groupIcon == null || groupChat.groupIcon!.isEmpty
                  ? Icon(
                      Icons.group,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    )
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          groupChat.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (groupChat.lastMessage != null)
                        Text(
                          _formatTime(groupChat.lastMessage!.timestamp),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          groupChat.lastMessage != null
                              ? '${groupChat.lastMessage!.senderUsername}: ${groupChat.lastMessage!.text}'
                              : '${groupChat.members.length} members',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (groupChat.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            groupChat.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}