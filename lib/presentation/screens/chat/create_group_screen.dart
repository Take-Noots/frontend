import 'package:flutter/material.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/services/group_chat_service.dart';
import 'group_chat_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  final TextEditingController _groupIconController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  final ChatService _chatService = ChatService();
  final GroupChatService _groupChatService = GroupChatService();
  
  List<SearchUser> searchResults = [];
  List<SearchUser> selectedUsers = [];
  bool _isSearching = false;
  bool _isCreating = false;
  bool _showSearchResults = false;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _groupIconController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final userData = userDataString != null
        ? jsonDecode(userDataString)
        : {'id': '685fb750cc084ba7e0ef8533'};
    setState(() {
      currentUserId = userData['id'];
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
            .where((user) => user['_id'] != currentUserId)
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

  void _toggleUserSelection(SearchUser user) {
    setState(() {
      if (selectedUsers.any((u) => u.id == user.id)) {
        selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        selectedUsers.add(user);
      }
    });
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedUsers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 members'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final memberIds = selectedUsers.map((user) => user.id).toList();
      
      final result = await _groupChatService.createGroupChat(
        name: _groupNameController.text.trim(),
        description: _groupDescriptionController.text.trim().isNotEmpty 
            ? _groupDescriptionController.text.trim() 
            : null,
        groupIcon: _groupIconController.text.trim().isNotEmpty 
            ? _groupIconController.text.trim() 
            : null,
        memberIds: memberIds,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to group chat screen
          final groupChatData = result['data'];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatScreen(
                groupChatId: groupChatData['_id'],
                currentUserId: currentUserId!,
              ),
            ),
          );
        }
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
            content: Text('Error creating group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
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
        title: Text(
          'Create Group',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.green,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Create',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Group Details Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Group Icon URL Input
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _groupIconController,
                      decoration: InputDecoration(
                        hintText: 'Group icon URL (optional)',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        prefixIcon: Icon(
                          Icons.image,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Group Name Input
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _groupNameController,
                      decoration: InputDecoration(
                        hintText: 'Group name *',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        prefixIcon: Icon(
                          Icons.group,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Group Description Input
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _groupDescriptionController,
                      decoration: InputDecoration(
                        hintText: 'Group description (optional)',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        prefixIcon: Icon(
                          Icons.description,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),

            // Selected Users Section
            if (selectedUsers.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Members (${selectedUsers.length})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedUsers.length,
                        itemBuilder: (context, index) {
                          final user = selectedUsers[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                                          ? (user.profileImage!.startsWith('http')
                                              ? NetworkImage(user.profileImage!) as ImageProvider
                                              : AssetImage(user.profileImage!))
                                          : const AssetImage('assets/images/hehe.png'),
                                    ),
                                    Positioned(
                                      top: -5,
                                      right: -5,
                                      child: GestureDetector(
                                        onTap: () => _toggleUserSelection(user),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    user.username,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Search Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users to add...',
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

            // Search Results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_showSearchResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for users to add to your group',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 16,
              ),
            ),
            Text(
              'At least 2 members required',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

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
        final isSelected = selectedUsers.any((u) => u.id == user.id);
        
        return SearchUserItemForGroup(
          user: user,
          isSelected: isSelected,
          onToggle: () => _toggleUserSelection(user),
        );
      },
    );
  }
}

class SearchUserItemForGroup extends StatelessWidget {
  final SearchUser user;
  final bool isSelected;
  final VoidCallback onToggle;

  const SearchUserItemForGroup({
    super.key,
    required this.user,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.green.withOpacity(0.1) 
              : Colors.transparent,
        ),
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
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.green : Theme.of(context).colorScheme.secondary,
                  width: 2,
                ),
                color: isSelected ? Colors.green : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}