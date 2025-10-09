import 'package:flutter/material.dart';
import '../../../data/models/group_chat_model.dart';
import '../../../data/services/group_chat_service.dart';
import 'user_profile_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final GroupChat groupChat;
  final String currentUserId;

  const GroupDetailsScreen({
    super.key,
    required this.groupChat,
    required this.currentUserId,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final GroupChatService _groupChatService = GroupChatService();
  late GroupChat groupChat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    groupChat = widget.groupChat;
  }

  bool get isCreator => groupChat.createdBy == widget.currentUserId;

  void _showEditGroupDialog() {
    final nameController = TextEditingController(text: groupChat.name);
    final descriptionController = TextEditingController(text: groupChat.description ?? '');
    final iconController = TextEditingController(text: groupChat.groupIcon ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Edit Group',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: iconController,
              decoration: InputDecoration(
                labelText: 'Icon URL (optional)',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _updateGroup(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  icon: iconController.text.trim(),
                );
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateGroup({
    required String name,
    required String description,
    required String icon,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _groupChatService.updateGroupChat(
        groupChatId: groupChat.id,
        name: name,
        description: description.isEmpty ? null : description,
        groupIcon: icon.isEmpty ? null : icon,
      );

      if (result['success']) {
        setState(() {
          groupChat = GroupChat.fromJson(result['data'], widget.currentUserId);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group updated successfully!'),
              backgroundColor: Colors.green,
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
            content: Text('Error updating group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeMember(GroupChatUser member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Remove Member',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        content: Text(
          'Are you sure you want to remove ${member.username} from the group?',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _groupChatService.removeMemberFromGroup(
          groupChat.id,
          member.id,
        );

        if (result['success']) {
          setState(() {
            groupChat = GroupChat.fromJson(result['data'], widget.currentUserId);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${member.username} removed from group'),
                backgroundColor: Colors.green,
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
              content: Text('Error removing member: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _viewMemberProfile(GroupChatUser member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: member.id,
          username: member.username,
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
        title: Text(
          'Group Info',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isCreator)
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _showEditGroupDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Group Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
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
                                  size: 40,
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          groupChat.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (groupChat.description != null && groupChat.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            groupChat.description!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${groupChat.members.length} members',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Created ${_formatDate(groupChat.createdAt)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Members Section
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text(
                                'Members (${groupChat.members.length})',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (isCreator)
                                IconButton(
                                  icon: Icon(
                                    Icons.person_add,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    // TODO: Add member functionality
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Add member feature coming soon!'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: groupChat.members.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final member = groupChat.members[index];
                            final isCurrentUser = member.id == widget.currentUserId;
                            final isMemberCreator = member.id == groupChat.createdBy;

                            return InkWell(
                              onTap: () => _viewMemberProfile(member),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundImage: member.profileImage != null && member.profileImage!.isNotEmpty
                                              ? (member.profileImage!.startsWith('http')
                                                  ? NetworkImage(member.profileImage!) as ImageProvider
                                                  : AssetImage(member.profileImage!))
                                              : const AssetImage('assets/images/hehe.png'),
                                        ),
                                        if (member.isOnline)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 14,
                                              height: 14,
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
                                    
                                    const SizedBox(width: 16),
                                    
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                member.username,
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (isCurrentUser) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Text(
                                                    'You',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (isMemberCreator) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Text(
                                                    'Admin',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          Text(
                                            member.isOnline ? 'Online' : member.lastSeen,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.secondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    if (isCreator && !isCurrentUser && !isMemberCreator)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _removeMember(member),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions Section
                  if (isCreator) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              // TODO: Add delete group functionality
                              _showDeleteGroupDialog();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Delete Group',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              // TODO: Add leave group functionality
                              _showLeaveGroupDialog();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.exit_to_app,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Leave Group',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _showDeleteGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Delete Group',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete group
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete group feature coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Leave Group',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        content: Text(
          'Are you sure you want to leave this group?',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement leave group
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Leave group feature coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }
}