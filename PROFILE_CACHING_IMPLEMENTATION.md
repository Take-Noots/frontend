# Profile Caching Implementation

## Overview

This document explains the profile caching mechanism implemented in the Flutter frontend, similar to the feed caching in `home_screen.dart`.

## Implementation

### 1. ProfileProvider (Global State Management)

**Location:** `frontend/lib/core/providers/profile_provider.dart`

#### Features:

- **Multi-user cache**: Stores profiles for multiple users simultaneously (key: userId)
- **Cache duration**: 5 minutes (configurable)
- **Automatic validation**: Checks if cached data is still valid before using it
- **Force refresh**: Option to bypass cache and fetch fresh data
- **Cache invalidation**: Methods to clear specific or all cached profiles

#### Key Methods:

```dart
// Load profile (uses cache if valid)
Future<void> loadProfile(String userId, {bool forceRefresh = false, BuildContext? context})

// Force refresh profile
Future<void> refreshProfile(String userId, {BuildContext? context})

// Invalidate specific profile cache
void invalidateProfile(String userId)

// Update profile in cache (after edit)
void updateCachedProfile(String userId, ProfileModel updatedProfile)
```

### 2. CachedProfile Data Structure

Stores complete profile data:

- Profile information (ProfileModel)
- Posts list
- Album images
- Post count
- Loading state
- Error state
- Last fetch timestamp

### 3. Cache Validation Logic

```dart
bool get isValid {
  final now = DateTime.now();
  return now.difference(lastFetchTime) < ProfileProvider._cacheDuration;
}
```

## Usage in Screens

### Example: my_profile.dart

```dart
@override
void initState() {
  super.initState();
  _loadUserIdAndProfile();
}

Future<void> _loadUserIdAndProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final userDataString = prefs.getString('user_data');
  final userData = userDataString != null ? jsonDecode(userDataString) : null;

  if (userData != null) {
    final userId = userData['id'];
    final username = userData['name'];

    setState(() {
      this.userId = userId;
      this.username = username;
    });

    // Load profile through ProfileProvider (uses cache if available)
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.loadProfile(userId, context: context);
  }
}

// Manual refresh
Future<void> _refreshProfile() async {
  if (userId != null) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.refreshProfile(userId, context: context);
  }
}

// In build method
@override
Widget build(BuildContext context) {
  final profileProvider = Provider.of<ProfileProvider>(context);
  final cachedProfile = profileProvider.getCachedProfile(userId ?? '');

  if (cachedProfile == null || cachedProfile.isLoading) {
    return Center(child: CommonLoading.purple());
  }

  if (cachedProfile.hasError) {
    return Center(child: Text(cachedProfile.error ?? 'Error'));
  }

  final profile = cachedProfile.profile;
  // Use profile data...
}
```

## Benefits

1. **Performance**: Reduces unnecessary API calls
2. **User Experience**: Instant loading for recently viewed profiles
3. **Network Efficiency**: Saves bandwidth and server resources
4. **Offline Tolerance**: Shows cached data even if network request fails
5. **Multi-user Support**: Caches multiple profiles simultaneously

## Cache Invalidation Scenarios

### When to invalidate cache:

1. **After profile edit**: Call `updateCachedProfile()` with new data
2. **After follow/unfollow**: Call `invalidateProfile()` to refresh follower counts
3. **After post creation/deletion**: Call `invalidateProfile()` to refresh post list
4. **On logout**: Call `clearAllCache()` to remove all cached data

## Integration Checklist

- [x] Create ProfileProvider
- [x] Register in main.dart
- [ ] Update my_profile.dart to use ProfileProvider
- [ ] Update user_profile_screen.dart to use ProfileProvider
- [ ] Add refresh triggers after profile edits
- [ ] Add refresh triggers after post operations
- [ ] Test cache expiration (5 minutes)
- [ ] Test force refresh functionality

## Configuration

### Adjust cache duration:

```dart
// In profile_provider.dart
static const Duration _cacheDuration = Duration(minutes: 5); // Change here
```

### Disable caching temporarily:

```dart
// Always force refresh
await profileProvider.loadProfile(userId, forceRefresh: true);
```

---

_This caching mechanism follows the same pattern as FeedProvider and integrates seamlessly with the existing architecture._
