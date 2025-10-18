/// Route names for the application
class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String username = '/username';
  static const String linkSpotify = '/link-spotify';

  // Main app routes (inside shell)
  static const String home = '/home';
  static const String search = '/search';
  static const String createNoot = '/create-noot';
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  // Profile sub-routes
  static const String myProfile = '/profile/me';
  static const String userProfile = '/profile/user';
  static const String editProfile = '/profile-edit';
  static const String createProfile = '/profile/create';
  static const String settings = '/profile/settings';
  static const String options = '/profile/options';
  static const String privacy = '/profile/privacy';
  static const String help = '/profile/help';
  static const String about = '/profile/about';
  static const String savedPosts = '/profile/saved-posts';
  static const String hiddenPosts = '/profile/hidden-posts';
  static const String followers = '/profile/followers';
  static const String following = '/profile/following';
  static const String profileFeed = '/profile/feed';
  static const String thoughtFeed = '/profile/thoughts';

  // Post routes
  static const String updatePost = '/post/update';
  static const String postDetails = '/post/details';

  // Create noot sub-routes
  static const String searchSong = '/create-noot/search';
  static const String createDescriptionNoot = '/create-noot/description';
  static const String createNootPreview = '/create-noot/preview';

  // Fanbase routes
  static const String fanbasePost = '/fanbase';
  static const String fanbaseList = '/fanbases';
  static const String fanbaseDetails = '/fanbases/:fanbaseId';

  // Helper method to generate fanbase detail route
  static String fanbaseDetailRoute(String fanbaseId, String userId) {
    return '/fanbases/$fanbaseId?userId=$userId';
  }

  // Request routes
  static const String requests = '/requests';

  // Chat routes
  static const String chat = '/chat';

  // Advertisement routes
  static const String createAdvertisement = '/create/advertisement';
  static const String setAudience = '/create/advertisement/set-audience';
}
