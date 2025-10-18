# User List Skeleton Loading Screens

This document explains how to use the skeleton loading screens for followers and following lists.

## Files Created

1. **`user_list_skeleton.dart`** - Reusable skeleton loading widget for user lists
2. **`followers_list_wrapper.dart`** - Stateful wrapper that handles async loading for followers
3. **`following_list_wrapper.dart`** - Stateful wrapper that handles async loading for following

## Features

### UserListSkeleton Widget

The `UserListSkeleton` widget provides:

- Animated pulsing effect (3-second cycle)
- Customizable title
- Configurable number of skeleton items
- Consistent styling with app theme (purple accent color)
- Skeleton items showing:
  - Circular avatar placeholder
  - Username placeholder
  - Full name placeholder

### Wrapper Pages

The wrapper pages (`FollowersListPageWrapper` and `FollowingListPageWrapper`) provide:

- Automatic data fetching on mount
- Skeleton loading state during data fetch
- Error handling with retry functionality
- Proper cleanup with mounted checks

## Usage

### Option 1: Using Wrapper Pages (Recommended)

Use the wrapper pages for automatic loading state management:

```dart
// For Followers
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FollowersListPageWrapper(
      userId: profile.userId,
    ),
  ),
);

// For Following
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FollowingListPageWrapper(
      userId: profile.userId,
    ),
  ),
);
```

### Option 2: Using Direct Pages with Manual Loading State

If you need more control over the loading state:

```dart
// Show skeleton while loading
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FollowersListPage(
      followers: [],
      isLoading: true,
    ),
  ),
);

// Then update with actual data
final followersList = await profileService.getFollowersListWithDetails(userId);
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => FollowersListPage(
      followers: followersList,
      isLoading: false,
    ),
  ),
);
```

### Option 3: Using UserListSkeleton Standalone

You can also use the skeleton widget independently:

```dart
// Show only the skeleton
const UserListSkeleton(
  title: 'Followers',
  itemCount: 15, // Optional, defaults to 10
);
```

## Customization

### Changing Skeleton Item Count

```dart
const UserListSkeleton(
  title: 'Followers',
  itemCount: 20, // Show 20 skeleton items
);
```

### Modifying Animation

Edit `user_list_skeleton.dart` to adjust:

- Animation duration (default: 3 seconds)
- Opacity range (default: 0.7 to 0.9)
- Animation curve (default: easeInOut)

```dart
_animationController = AnimationController(
  duration: const Duration(seconds: 2), // Change duration
  vsync: this,
)..repeat(reverse: true);

_animation = Tween<double>(begin: 0.5, end: 1.0).animate( // Change range
  CurvedAnimation(parent: _animationController, curve: Curves.linear), // Change curve
);
```

### Changing Colors

Modify the skeleton color in `user_list_skeleton.dart`:

```dart
static const Color skeletonBaseColor = Color(0xFF8E08EF); // Purple
static const double skeletonOpacityFactor = 0.2;
```

## Integration Points

### Update Existing Navigation

Replace the existing async navigation pattern in your profile screens:

**Before:**

```dart
onFollowersTap: () async {
  final profileService = ProfileService();
  final followersList = await profileService
      .getFollowersListWithDetails(profile!.userId);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FollowersListPage(
        followers: followersList,
      ),
    ),
  );
},
```

**After:**

```dart
onFollowersTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FollowersListPageWrapper(
        userId: profile!.userId,
      ),
    ),
  );
},
```

## Architecture

```
UserListSkeleton (Reusable Widget)
    ↑
    ├── FollowersListPageWrapper (Stateful, handles loading)
    │       ↓
    │   FollowersListPage (Stateless, displays data)
    │
    └── FollowingListPageWrapper (Stateful, handles loading)
            ↓
        FollowingListPage (Stateless, displays data)
```

## Benefits

1. **Better UX** - Users see immediate feedback with animated skeleton instead of blank screen
2. **Reduced Perceived Wait Time** - Animation makes loading feel faster
3. **Consistent Design** - Matches the profile loading screen skeleton pattern
4. **Error Recovery** - Built-in retry functionality for failed loads
5. **Reusable** - Same skeleton widget works for both followers and following

## Testing

Test the skeleton screens by:

1. Adding a delay in ProfileService methods
2. Simulating slow network conditions
3. Testing error states by throwing exceptions

```dart
// In ProfileService (for testing only)
Future<List<dynamic>> getFollowersListWithDetails(String userId) async {
  await Future.delayed(const Duration(seconds: 2)); // Test skeleton display
  // ... rest of implementation
}
```
