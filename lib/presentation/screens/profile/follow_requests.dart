import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../data/services/profile_service.dart';

class FollowRequestsPage extends StatefulWidget {
  const FollowRequestsPage({Key? key}) : super(key: key);

  @override
  State<FollowRequestsPage> createState() => _FollowRequestsPageState();
}

class _FollowRequestsPageState extends State<FollowRequestsPage> {
  List<dynamic> requests = [];
  bool loading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      userId = userData['id'] as String?;
    }
    await _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (userId == null) return;
    setState(() => loading = true);
    final service = ProfileService();
    final result = await service.getFollowRequests(userId!);
    setState(() {
      requests = result;
      loading = false;
    });
  }

  Future<void> _accept(String requesterId) async {
    if (userId == null) return;
    final service = ProfileService();
    final res = await service.acceptFollowRequest(userId!, requesterId);
    if (res['success'] == true) {
      setState(() {
        requests.removeWhere(
            (r) => r['userId'] == requesterId || r['_id'] == requesterId);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res['message'] ?? 'Accepted')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to accept')));
    }
  }

  Future<void> _reject(String requesterId) async {
    if (userId == null) return;
    final service = ProfileService();
    final res = await service.rejectFollowRequest(userId!, requesterId);
    if (res['success'] == true) {
      setState(() {
        requests.removeWhere(
            (r) => r['userId'] == requesterId || r['_id'] == requesterId);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res['message'] ?? 'Rejected')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to reject')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow Requests'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? Center(
                  child: Text('No follow requests',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)))
              : ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final r = requests[index];
                    final requesterId =
                        (r['userId'] ?? r['_id'] ?? '').toString();
                    final username = r['username'] ?? r['fullName'] ?? 'User';
                    final profileImage = r['profileImage'] ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            profileImage.toString().startsWith('http')
                                ? NetworkImage(profileImage) as ImageProvider
                                : null,
                        child: profileImage == ''
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(username.toString(),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => _reject(requesterId),
                            child: const Text('Reject'),
                          ),
                          ElevatedButton(
                            onPressed: () => _accept(requesterId),
                            child: const Text('Accept'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
