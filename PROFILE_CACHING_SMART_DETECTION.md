# Profile Caching Implementation with Smart Change Detection

## Overview

This document explains the intelligent profile caching mechanism implemented in the Flutter frontend. Unlike simple time-based caching, this implementation uses **change detection** to ensure users always see up-to-date data while minimizing unnecessary API calls.

## Key Features

### 1. **Smart Cache Validation**

- **Time-based validation**: Cache expires after 5 minutes (maximum stale time)
- **Change detection**: Even if cache is valid (<5 min), checks server for updates
- **Lightweight checks**: Uses minimal API calls to detect changes without fetching full data

### 2. **Change Detection Strategies**

#### Strategy 1: Post Count Check

- Compares cached post count with server post count
- Detects when new posts are created or deleted
- Very lightweight (single API call)

#### Strategy 2: Follower/Following Count Check

- Compares follower and following counts
- Detects when users follow/unfollow
- Part of profile fetch (no extra API call)

#### Strategy 3: Profile Update Timestamp (Future Enhancement)

- Checks `updatedAt` field if available from backend
- Detects profile edits (bio, profile picture, etc.)
- Currently commented out - requires backend support

## How It Works

### Cache Decision Flow:

```
User opens profile
  ↓
Force refresh? → YES → Fetch fresh data
  ↓ NO
Cache exists? → NO → Fetch fresh data
  ↓ YES
Cache > 5 min old? → YES → Fetch fresh data
  ↓ NO
Check server for changes (lightweight)
  ↓
Post count changed? → YES → Fetch fresh data
  ↓ NO
Followers changed? → YES → Fetch fresh data
  ↓ NO
Following changed? → YES → Fetch fresh data
  ↓ NO
Use cached data (no changes detected)
```

## What Gets Detected Automatically

| Change Type                 | Detection Method           | Detected? |
| --------------------------- | -------------------------- | --------- |
| New post created            | Post count comparison      | ✅ YES    |
| Post deleted                | Post count comparison      | ✅ YES    |
| User followed profile       | Follower count comparison  | ✅ YES    |
| User unfollowed profile     | Follower count comparison  | ✅ YES    |
| Profile followed someone    | Following count comparison | ✅ YES    |
| Profile unfollowed someone  | Following count comparison | ✅ YES    |
| Profile edited (bio, image) | TODO: updatedAt field      | ⏳ Future |

## Usage in Screens

### Pull-to-Refresh Implementation:

```dart
@override
Widget build(BuildContext context) {
  return RefreshIndicator(
    onRefresh: _handleRefresh, // Swipe down to refresh
    child: Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final cachedProfile = profileProvider.getCachedProfile(userId);

        if (cachedProfile == null || cachedProfile.isLoading) {
          return Center(child: CommonLoading.purple());
        }

        if (cachedProfile.hasError) {
          return Center(child: Text(cachedProfile.error ?? 'Error'));
        }

        final profile = cachedProfile.profile;
        // Use profile data...
      },
    ),
  );
}

Future<void> _handleRefresh() async {
  final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
  // Force refresh: bypasses cache, fetches immediately
  await profileProvider.refreshProfile(userId, context: context);
}
```

## Real-World Scenarios

### Scenario 1: User Views Profile (First Time)

```
- No cache exists
- Fetches fresh data from server
- Stores in cache with timestamp
- Displays profile
```

### Scenario 2: User Views Profile Again (Within 5 Minutes, No Changes)

```
- Cache exists and is valid (<5 min)
- Checks server for changes:
  ✓ Post count: 10 → 10 (no change)
  ✓ Followers: 25 → 25 (no change)
  ✓ Following: 30 → 30 (no change)
- Uses cached data (fast load!)
- No unnecessary API calls
```

### Scenario 3: User Views Profile Again (Within 5 Minutes, New Follower)

```
- Cache exists and is valid (<5 min)
- Checks server for changes:
  ✓ Post count: 10 → 10 (no change)
  ✗ Followers: 25 → 26 (CHANGED!)
- Fetches fresh data
- Updates cache
- Displays updated profile with new follower
```

### Scenario 4: User Swipes to Refresh (Pull-to-Refresh)

```
- Force refresh triggered
- Bypasses all cache checks
- Fetches fresh data immediately
- Updates cache
- Displays profile
```

### Scenario 5: Cache Expired (>5 Minutes)

```
- Cache exists but expired
- Fetches fresh data (no change detection needed)
- Updates cache
- Displays profile
```

## Benefits

### ✅ **Always Up-to-Date**

- Detects server-side changes even within cache validity period
- Users see new posts, followers, and profile edits without waiting 5 minutes
- No stale data issues

### ✅ **Performance Optimized**

- Uses cache when no changes detected
- Lightweight change detection (minimal API overhead)
- Reduces unnecessary full profile fetches

### ✅ **Network Efficient**

- Post count check: Single lightweight API call
- Follower/following check: Part of profile fetch (no extra call)
- Only fetches full data when changes detected

### ✅ **User Experience**

- Manual refresh always available (swipe down)
- Fast loading when cache is valid and unchanged
- Instant updates when changes detected

## Integration Checklist

- [x] Create ProfileProvider with change detection
- [x] Register in main.dart
- [ ] Update my_profile.dart to use ProfileProvider
- [ ] Update user_profile_screen.dart to use ProfileProvider
- [ ] Add RefreshIndicator for pull-to-refresh
- [ ] Test new post detection
- [ ] Test follow/unfollow detection
- [ ] Test cache expiration (5 minutes)
- [ ] Test force refresh functionality

## Configuration

### Adjust cache duration:

```dart
// In profile_provider.dart
static const Duration _cacheDuration = Duration(minutes: 5); // Change here
```

### Force refresh programmatically:

```dart
await profileProvider.refreshProfile(userId, context: context);
```

## Future Enhancements

### Backend Support Needed:

1. **Add `updatedAt` timestamp** to profile model
2. **Add lightweight "check updates" endpoint**
   - Returns only: `{ postCount, followerCount, followingCount, updatedAt }`
   - Single endpoint replaces multiple checks
   - Even more efficient

---

_This intelligent caching mechanism ensures users always see fresh data while maintaining optimal performance and minimal network usage._
