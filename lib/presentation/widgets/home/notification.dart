import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/services/song_post_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final SongPostService _songPostService = SongPostService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchNotifications();
  }

  Future<void> _loadUserIdAndFetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      setState(() {
        _userId = userData['id'];
      });
      if (_userId != null) {
        _fetchAllNotifications();
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "User not logged in.";
      });
    }
  }

  Future<void> _fetchAllNotifications() async {
    if (_userId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _songPostService.getNotifications(_userId!);
      if (mounted) {
        if (response['success']) {
          setState(() {
            _notifications = response['data'];
          });
        } else {
          setState(() {
            _errorMessage = response['message'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "An error occurred: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_notifications.isEmpty) {
      return const Center(child: Text('No new notifications.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        if (notification['type'] == 'like') {
          return _buildLikeNotificationTile(notification);
        } else if (notification['type'] == 'comment') {
          return _buildCommentNotificationTile(notification);
        }
        return const SizedBox.shrink(); // Should not happen
      },
    );
  }

  Widget _buildLikeNotificationTile(Map<String, dynamic> notification) {
    final List<String> actors =
        List<String>.from(notification['actors'] ?? []);
    final String albumImage = notification['albumImage'] ?? '';

    String likedByText;
    if (actors.length > 2) {
      likedByText = '${actors.take(2).join(', ')} and others';
    } else {
      likedByText = actors.join(', ');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade800,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: <TextSpan>[
              TextSpan(
                  text: likedByText,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' liked your post.'),
            ],
          ),
        ),
        trailing: albumImage.isNotEmpty
            ? Image.network(
                albumImage,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    'https://picsum.photos/seed/picsum/200/300',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  );
                },
              )
            : Container(
                width: 50,
                height: 50,
                color: Colors.grey.shade800,
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
        onTap: () {},
      ),
    );
  }

  Widget _buildCommentNotificationTile(Map<String, dynamic> notification) {
    final String username = (notification['actors'] as List).first;
    final String commentText = notification['message'] ?? '';
    final String albumImage = notification['albumImage'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade800,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                text: username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' commented: "$commentText"'),
            ],
          ),
        ),
        trailing: albumImage.isNotEmpty
            ? Image.network(
                albumImage,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    'https://picsum.photos/seed/picsum/200/300',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  );
                },
              )
            : Container(
                width: 50,
                height: 50,
                color: Colors.grey.shade800,
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
        onTap: () {},
      ),
    );
  }
}
