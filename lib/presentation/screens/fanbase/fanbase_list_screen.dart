import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../data/models/fanbase_model.dart';
import '../../../data/services/fanbase_service.dart';
import 'fanbase_details.dart';

class FanbaseListScreen extends StatefulWidget {
  const FanbaseListScreen({Key? key}) : super(key: key);

  @override
  State<FanbaseListScreen> createState() => _FanbaseListScreenState();
}

class _FanbaseListScreenState extends State<FanbaseListScreen> {
  late Future<List<Fanbase>> _fanbasesFuture;
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFanbases();
  }

  /// Loads current user ID from SharedPreferences and fetches fanbases
  Future<void> _loadUserIdAndFanbases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        setState(() {
          _currentUserId = userData['id'];
        });
        print('Current user ID loaded: $_currentUserId');
      }
      _loadFanbases();
    } catch (e) {
      print('Error loading current user ID: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetches all fanbases from the service
  void _loadFanbases() {
    setState(() {
      _fanbasesFuture = FanbaseService.getAllFanbases(context);
      _isLoading = false;
    });
  }

  /// Navigates to fanbase detail screen
  void _navigateToFanbaseDetail(String fanbaseId) {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to view fanbase details'),
        ),
      );
      return;
    }

    print('Navigating to fanbase: $fanbaseId with userId: $_currentUserId');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FanbaseDetailScreen(
          fanbaseId: fanbaseId,
          userId: _currentUserId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Fanbases')),
      body: FutureBuilder<List<Fanbase>>(
        future: _fanbasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadFanbases,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No fanbases found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final fanbases = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _loadFanbases();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: fanbases.length,
              itemBuilder: (context, index) {
                final fanbase = fanbases[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: fanbase.fanbasePhotoUrl != null
                          ? NetworkImage(fanbase.fanbasePhotoUrl!)
                          : null,
                      child: fanbase.fanbasePhotoUrl == null
                          ? const Icon(Icons.group)
                          : null,
                    ),
                    title: Text(fanbase.fanbaseName),
                    subtitle: Text(
                      '${fanbase.joinedUserIds.length} members • ${fanbase.fanbaseTopic}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _navigateToFanbaseDetail(fanbase.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
