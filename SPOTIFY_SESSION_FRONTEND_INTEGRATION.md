# Frontend Implementation - Spotify Session Management with User Confirmation

## ✅ Files Created

### 1. Service Layer

**`lib/data/services/spotify_session_service.dart`**

- `SpotifySessionService` class for API communication
- `SpotifySessionStatus` model for session state
- Methods: `getSessionStatus()`, `confirmClearSession()`, `retryConnection()`

### 2. UI Components

**`lib/presentation/widgets/dialogs/spotify_connection_dialog.dart`**

- Beautiful Material Design dialog
- Shows retry count, error details
- Action buttons: Dismiss, Retry Connection, Disconnect & Re-link
- Auto-adapts UI based on error type (temporary vs permanent)

### 3. Mixin for Easy Integration

**`lib/presentation/mixins/spotify_session_mixin.dart`**

- `SpotifySessionMixin` - Add to any screen using Spotify
- Automatic status checking
- Built-in dialog handling
- Error handling helpers
- Snackbar notifications

---

## 🚀 How to Use

### Quick Integration (3 Steps)

#### Step 1: Add Mixin to Your Screen

```dart
// Before
class _HomeScreenState extends State<HomeScreen> {
  // ...
}

// After
class _HomeScreenState extends State<HomeScreen> with SpotifySessionMixin {
  // ...
}
```

#### Step 2: Check Status in initState

```dart
@override
void initState() {
  super.initState();

  // Check Spotify status when screen loads
  WidgetsBinding.instance.addPostFrameCallback((_) {
    checkSpotifySessionStatus();
  });

  // Your other initialization code...
}
```

#### Step 3: Handle Spotify Errors

```dart
// When you make a Spotify API call and it fails:
try {
  final response = await dio.post('/spotify/player/post/play', ...);
  // Success
} catch (e) {
  print('Error playing track: $e');

  // This will check if it's a token issue and show dialog if needed
  await onSpotifyError(e);
}
```

That's it! The mixin handles everything else automatically.

---

## 📋 Complete Example Integration

### Example: Home Screen with Spotify Features

```dart
import 'package:flutter/material.dart';
import '../mixins/spotify_session_mixin.dart';
// ... other imports

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ✅ Add the mixin here
class _HomeScreenState extends State<HomeScreen> with SpotifySessionMixin {
  String? _currentlyPlayingTrackId;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // ✅ Check Spotify status on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkSpotifySessionStatus();
    });

    _loadFeed();
  }

  // Your existing play track method
  Future<void> _playTrack(String trackId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.post(
        '/spotify/player/post/play',
        data: {'track_id': trackId},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _currentlyPlayingTrackId = trackId;
          _isPlaying = true;
        });
      }
    } catch (e) {
      print('Error playing track: $e');

      // ✅ Handle Spotify errors - shows dialog if token issue
      await onSpotifyError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Your UI code...
    );
  }
}
```

---

## 🎯 What Happens Automatically

### Scenario 1: Temporary Network Issue (3 Retries in Backend)

1. User tries to play a song
2. Backend retries 3 times automatically (3s, 6s, 9s delays)
3. If successful during retries → **User never knows!** ✅
4. If still failing → Snackbar shows: "Connection issue (attempt 2/3)"
5. No dialog shown until all retries exhausted

### Scenario 2: Token Revoked (Permanent Failure)

1. User tries to play a song
2. Backend detects `invalid_grant` error
3. Sets `requires_user_confirmation = true` (doesn't delete token)
4. Frontend calls `checkSpotifySessionStatus()`
5. **Dialog appears** with two options:
   - **"Retry Connection"** → Calls backend to reset retry counter
   - **"Disconnect & Re-link"** → Shows confirmation, then deletes token
6. User chooses action

### Scenario 3: User Confirms Unlinking

1. User clicks "Disconnect & Re-link" in dialog
2. Confirmation dialog appears:

   ```
   "This will remove your Spotify connection. You'll need to
   reconnect your account to play music again.

   Are you sure you want to continue?"

   [Cancel]  [Yes, Disconnect]
   ```

3. If user clicks "Yes, Disconnect":
   - Calls `POST /spotify/session/confirm-clear`
   - Backend deletes token from database
   - Success snackbar appears
   - After 2 seconds, navigates to `/link-spotify` screen
4. User can now re-link their Spotify account

---

## 🎨 UI/UX Features

### Dialog Appearance

**For Temporary Failures:**

- Blue info icon
- Title: "Spotify Connection Issue"
- Shows retry count: "Retry attempts: 2/3"
- Buttons: [Dismiss] [Retry Connection] [Disconnect & Re-link]

**For Permanent Failures:**

- Orange warning icon
- Title: "Spotify Connection Lost"
- Message explains token was likely revoked
- Buttons: [Dismiss] [Reconnect Spotify]

### Expandable Error Details

- Click "Error Details" to see technical error message
- Helpful for debugging
- Optional - user can ignore it

### Color-Coded Snackbars

- 🟢 Green = Success ("Retry initiated")
- 🔴 Red = Error ("Failed to disconnect")
- 🟠 Orange = Warning ("Connection issue")
- 🔵 Blue = Loading ("Retrying connection...")

---

## 🛠️ Advanced Usage

### Manual Status Check

```dart
// Check status without showing dialog
final status = await spotifySessionService.getSessionStatus();

if (status != null && status.requiresConfirmation) {
  // Custom handling
  print('Spotify needs user action');
  print('Last error: ${status.lastError}');
  print('Retry count: ${status.retryCount}');
}
```

### Custom Dialog with Your Own UI

```dart
import '../widgets/dialogs/spotify_connection_dialog.dart';

// Show dialog manually
await showSpotifyConnectionDialog(
  context: context,
  status: status,
  onRetry: () async {
    // Your custom retry logic
    final success = await spotifySessionService.retryConnection();
    if (success) {
      // Do something
    }
  },
  onUnlink: () async {
    // Your custom unlink logic
    final success = await spotifySessionService.confirmClearSession();
    if (success) {
      // Navigate somewhere
    }
  },
  onDismiss: () {
    // User dismissed
  },
);
```

### Check Status on App Resume

```dart
class _HomeScreenState extends State<HomeScreen>
    with SpotifySessionMixin, WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check Spotify status when app comes to foreground
      checkSpotifySessionStatus();
    }
  }
}
```

---

## 📍 Where to Integrate

Add the mixin and status check to these screens:

### High Priority (Main Spotify Usage)

1. ✅ **Home Screen** (`home_screen.dart`)

   - Users play songs from feed
   - Check in initState

2. ✅ **Thought Feed** (`thought_feed.dart`)

   - Users play songs attached to thoughts
   - Check in initState

3. ✅ **Thought Posts Tab** (`thought_posts_tab.dart`)

   - Already has Spotify play functionality
   - Check in initState

4. ✅ **Create Noot** (`create_description_noot.dart`)
   - Users search for songs
   - Check when searching

### Medium Priority

5. **Fanbase Details** (`fanbase_details.dart`)

   - Has Spotify track playing
   - Check in initState

6. **Profile Feed** (`profile_feed_screen.dart`)
   - Users play songs from profile posts
   - Check in initState

### Low Priority (Optional)

7. **Settings/Options** screens
   - Show status in Spotify settings section
   - Manual check button

---

## 🧪 Testing Checklist

### Test Temporary Network Errors

- [ ] Disconnect internet while playing a song
- [ ] Snackbar shows "Connection issue (attempt X/3)"
- [ ] No dialog appears if retries < 3
- [ ] Dialog appears after 3 failed retries
- [ ] "Retry Connection" button works
- [ ] After retry, can play songs again

### Test Revoked Token

- [ ] Revoke Spotify access from Spotify dashboard
- [ ] Try to play a song
- [ ] Dialog appears immediately (no retries for invalid_grant)
- [ ] "Reconnect Spotify" button shown
- [ ] Clicking shows confirmation dialog
- [ ] Confirming unlinks and navigates to link screen

### Test User Flows

- [ ] User clicks "Dismiss" - dialog closes, no action
- [ ] User clicks "Retry Connection" - snackbar shows, dialog closes
- [ ] User clicks "Disconnect & Re-link" - confirmation appears
- [ ] User cancels confirmation - nothing happens
- [ ] User confirms - token deleted, navigates to link screen

### Test Edge Cases

- [ ] Check status when not linked to Spotify - no dialog
- [ ] Check status multiple times - no duplicate dialogs
- [ ] Navigate away during dialog - no crashes
- [ ] Spotify works after successful retry

---

## 🔧 Configuration

### Customize Retry Count Display

Edit `spotify_connection_dialog.dart`:

```dart
// Change "Retry attempts: 2/3" format
Text('Retry attempts: ${status.retryCount}/3')

// Or use progress indicator
LinearProgressIndicator(
  value: status.retryCount / 3,
)
```

### Customize Dialog Appearance

Edit colors, icons, text in `spotify_connection_dialog.dart`

### Customize Snackbar Duration

Edit `spotify_session_mixin.dart`:

```dart
duration: Duration(seconds: isLoading ? 2 : 3), // Change here
```

### Change Navigation After Unlink

Edit `spotify_session_mixin.dart`:

```dart
if (mounted) {
  context.push('/link-spotify'); // Change route here
}
```

---

## 📊 Status Model Reference

```dart
class SpotifySessionStatus {
  final bool isLinked;              // Has Spotify connected
  final bool requiresConfirmation;  // Needs user action
  final int retryCount;             // 0-3
  final String? lastError;          // Error message
  final String? message;            // User-friendly message

  // Computed properties
  bool get hasIssues;               // Any retry or confirmation needed
  bool get isPermanentFailure;      // Token revoked (needs unlink)
  bool get isTemporaryFailure;      // Network issue (auto-retry)
}
```

---

## 🎓 Best Practices

### ✅ DO:

- Check status in initState of screens with Spotify features
- Use `onSpotifyError()` in catch blocks
- Let the mixin handle the dialog logic
- Show snackbars for temporary issues
- Require confirmation before unlinking

### ❌ DON'T:

- Check status on every API call (too frequent)
- Show dialog for temporary failures (< 3 retries)
- Unlink without user confirmation
- Block UI while checking status
- Show technical errors to users

---

## 🚀 Quick Start Checklist

For each screen with Spotify features:

1. [ ] Add `with SpotifySessionMixin` to State class
2. [ ] Call `checkSpotifySessionStatus()` in initState
3. [ ] Wrap Spotify API calls in try-catch
4. [ ] Call `await onSpotifyError(e)` in catch block
5. [ ] Test with disconnected Spotify token

That's it! Five simple steps to add robust error handling.

---

## 📝 Summary

**Created Files:**

- ✅ `spotify_session_service.dart` - API service
- ✅ `spotify_connection_dialog.dart` - Beautiful dialog UI
- ✅ `spotify_session_mixin.dart` - Easy integration helper

**What It Does:**

- ✅ Checks Spotify session status
- ✅ Shows dialog when user action needed
- ✅ Handles retry automatically
- ✅ Requires confirmation before unlinking
- ✅ Navigates to re-link screen after unlink

**User Experience:**

- ✅ Temporary issues auto-retry (user never knows)
- ✅ Permanent issues show clear dialog
- ✅ User controls when to disconnect
- ✅ No surprise logouts

**Integration:**

- ✅ 3-step integration (mixin, initState, error handling)
- ✅ Works with existing code
- ✅ No breaking changes

Everything is ready to use! Just add the mixin to your screens and you're done! 🎉
