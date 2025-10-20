import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/route_names.dart';
import './user_profiles.dart';
import '../../../data/services/auth_service.dart';
import 'dart:convert';
import '../../../data/services/profile_service.dart';
import '../../../core/styles/app_colors.dart';

class FollowRequestsPage extends StatefulWidget {
  const FollowRequestsPage({Key? key}) : super(key: key);

  @override
  State<FollowRequestsPage> createState() => _FollowRequestsPageState();
}

class _FollowRequestsPageState extends State<FollowRequestsPage> {
  List<dynamic> requests = [];
  bool loading = true;
  String? userId;
  // track processing states per request id (accept/reject)
  // track processing action per request id: 'accept', 'reject', or null
  final Map<String, String?> _processing = {};

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
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final service = ProfileService(authService: authService);
      final result = await service.getFollowRequests(userId!);
      setState(() {
        requests = result;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load requests: $e')),
      );
    }
  }

  Future<void> _accept(String requesterId) async {
    if (userId == null) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final service = ProfileService(authService: authService);
    // mark this request as processing accept
    setState(() => _processing[requesterId] = 'accept');
    try {
      final res = await service.acceptFollowRequest(userId!, requesterId);
      if (res['success'] == true) {
        setState(() {
          requests.removeWhere(
              (r) => (r['userId'] ?? r['_id'] ?? '').toString() == requesterId);
          _processing.remove(requesterId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Accepted')));
      } else {
        setState(() => _processing.remove(requesterId));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to accept')));
      }
    } catch (e) {
      setState(() => _processing.remove(requesterId));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
    }
  }

  Future<void> _reject(String requesterId) async {
    if (userId == null) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final service = ProfileService(authService: authService);
    // mark this request as processing reject
    setState(() => _processing[requesterId] = 'reject');
    try {
      final res = await service.rejectFollowRequest(userId!, requesterId);
      if (res['success'] == true) {
        setState(() {
          requests.removeWhere(
              (r) => (r['userId'] ?? r['_id'] ?? '').toString() == requesterId);
          _processing.remove(requesterId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Rejected')));
      } else {
        setState(() => _processing.remove(requesterId));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to reject')));
      }
    } catch (e) {
      setState(() => _processing.remove(requesterId));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to reject: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow Requests'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : requests.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Center(
                          child: Padding(
                        padding: const EdgeInsets.only(top: 48.0),
                        child: Text('No follow requests',
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                      ))
                    ],
                  )
                : ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final r = requests[index];
                      final requesterId =
                          (r['userId'] ?? r['_id'] ?? '').toString();
                      final username = r['username'] ?? r['fullName'] ?? 'User';
                      final profileImage = r['profileImage'] ?? '';
                      final processingAction = _processing[requesterId];
                      final processing = processingAction != null;
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
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                        onTap: () {
                          final authProvider =
                              Provider.of<AuthProvider>(context, listen: false);
                          final currentUserId = authProvider.user?.id;
                          if (requesterId == currentUserId) {
                            // navigate to own profile route
                            context.go(AppRoutes.profile);
                          } else {
                            // open other user's profile page
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => UserProfilePage(
                                  userId: requesterId,
                                  username: username.toString(),
                                ),
                              ),
                            );
                          }
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Compact Reject button: uses an outlined style on light background
                            SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                // disable button when any action on this request is processing
                                onPressed: processing
                                    ? null
                                    : () => _reject(requesterId),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(72, 36),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                  side: BorderSide(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.textPrimary
                                        : AppColors.backgroundDark,
                                  ),
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.backgroundDark
                                          : AppColors.backgroundLight,
                                  foregroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.textPrimary
                                          : Colors.black,
                                ),
                                // only show spinner on reject button when reject is the processing action
                                child: processingAction == 'reject'
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppColors.textPrimary
                                                : Colors.black,
                                          ),
                                        ),
                                      )
                                    : Text('Reject',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? AppColors.textPrimary
                                                    : Colors.black)),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Compact Accept button: filled purple pill
                            SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                // disable while any action for this request is processing
                                onPressed: processing
                                    ? null
                                    : () => _accept(requesterId),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(72, 36),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  backgroundColor: AppColors.primaryPurple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                  elevation: 2,
                                ),
                                // only show spinner on accept button when accept is the processing action
                                child: processingAction == 'accept'
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text('Accept',
                                        style: TextStyle(fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
