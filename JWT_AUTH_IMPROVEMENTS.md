# JWT Authentication Improvements

## What Was Implemented

1. **Refresh Token Flow**

   - When JWT expires or a 401 is received, the app automatically attempts to refresh the JWT using a stored refresh token.
   - Only logs out if the refresh token is invalid or the refresh fails.

2. **Centralized Auth Logic**

   - All authentication checks and token refresh logic are handled in `auth_service.dart` and `token_manager_service.dart`.
   - Secure storage is used for tokens via `flutter_secure_storage`.

3. **Graceful Network Error Handling**

   - Network errors do not cause immediate logout.
   - Users see a retry dialog or snackbar for temporary issues.

4. **User Feedback**

   - Users are informed if their session expired due to token expiry or refresh failure.
   - Dialogs and snackbars provide clear messaging.

5. **Testing**
   - Simulated token expiry and network failures to ensure robust behavior.

## Example Flow

1. User makes a request with JWT.
2. If 401 received:
   - App attempts to refresh JWT using refresh token.
   - If refresh succeeds, original request is retried.
   - If refresh fails, user is logged out and shown a message.
3. If network error:
   - User sees retry option, not an immediate logout.

## Files Modified

- `lib/data/services/auth_service.dart`
- `lib/data/services/token_manager_service.dart`

---

**Result:**

- No more surprise logouts due to JWT expiry or network errors.
- User experience is smoother and more secure.

## Code changes (summary)

- `TokenManagerService`

  - Added `_refreshCompleter` to allow concurrent callers to await an in-progress refresh.
  - Exposed `refreshIfNeeded()` to attempt refresh during app initialization.
  - Added `onRefreshFailed` callback to allow `AuthService` to react before tokens are cleared.
  - Improved refresh concurrency handling and ensured awaiting callers are completed when refresh finishes.

- `AuthService`
  - Calls `refreshIfNeeded()` during `initialize()` to prevent immediate router redirects when a refresh can fix the session.
  - Subscribes to `onRefreshFailed` to ensure `authProvider.logout()` is executed if refresh ultimately fails.

## Quick test checklist

1. Start app with expired JWT but valid refresh cookie/token. App should stay on protected routes and not redirect to login.
2. Trigger a request that returns 401: the app should attempt refresh and retry the request automatically.
3. If refresh ultimately fails, the user should be logged out and taken to login screen with a friendly message.
4. Network errors (timeouts) should show retry UI, not immediate logout.

If you want, I can also add unit tests for the `TokenManagerService` refresh behavior.

## Proactive refresh implemented

- Token expiry is parsed from the JWT `exp` claim. The app schedules a proactive refresh when the token will expire within 60 seconds (configurable).
- This scheduling is handled in `TokenManagerService` and starts after tokens are loaded or saved.
- If proactive refresh fails, `onRefreshFailed` is called so `AuthService` can logout and the UI can show a message.

Files changed:

- `lib/data/services/token_manager_service.dart` (proactive refresh, single-flight refresh, interceptor update, clearTokens logging)
- `lib/data/services/auth_service.dart` (initialize wiring for refreshIfNeeded/onRefreshFailed)

Testing notes:

- To test proactive refresh, issue a token with short expiry (<2 minutes) and start the app; watch logs for "Proactive refresh triggered".
