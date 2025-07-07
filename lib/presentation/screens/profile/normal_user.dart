import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import 'tabs/album_art_posts_tab.dart';
import 'tabs/description_posts_tab.dart';
import 'tabs/tagged_posts_tab.dart';

class NormalUserProfilePage extends StatefulWidget {
  final String? username;
  
  const NormalUserProfilePage({Key? key, this.username}) : super(key: key);

  @override
  State<NormalUserProfilePage> createState() => _NormalUserProfilePageState();
}

class _NormalUserProfilePageState extends State<NormalUserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch user profile data from backend when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final username = widget.username ?? 'spotify_user';
      Provider.of<UserProfileProvider>(context, listen: false).fetchUserProfile(username);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final description = getRandomDescription();
    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Profile details (header, stats, description)
          AlbumArtPostsTab(
            username: username,
            posts: posts,
            followers: followers,
            following: following,
            albumArts: albumArts,
            description: description,
            showGrid: false, // Only show profile details, not grid
          ),
          // TabBar under profile details
          Container(
            color: Colors.black,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on)),
                Tab(icon: Icon(Icons.description)),
                Tab(icon: Icon(Icons.person_pin)),
              ],
            ),
          ),
          // TabBarView for posts
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AlbumArtPostsTab(
                  username: username,
                  posts: posts,
                  followers: followers,
                  following: following,
                  albumArts: albumArts,
                  description: description,
                  showGrid: true, // Only show grid
                ),
                const DescriptionPostsTab(),
                const TaggedPostsTab(),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
