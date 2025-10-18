# Common Loading Widget Documentation

## Overview

The `CommonLoading` widget provides a unified, consistent loading experience throughout the Flutter app. It replaces scattered `CircularProgressIndicator` implementations with a centralized, customizable loading component.

## Features

- ✅ **Consistent Design** - Purple theme matching app branding
- ✅ **Multiple Sizes** - Small, medium, large, and custom sizes
- ✅ **Multiple Colors** - Purple, white, black, and custom colors
- ✅ **Optional Messages** - Display loading text when needed
- ✅ **Flexible Layout** - Configurable alignment and padding
- ✅ **Easy Extensions** - Context extensions for quick access
- ✅ **Factory Constructors** - Convenient named constructors

## Basic Usage

### Import

```dart
import '../../widgets/common_loading.dart';
```

### Simple Purple Loading (Default)

```dart
// Basic usage - purple loading wheel
return CommonLoading();

// Or using extension
return context.purpleLoading;
```

### Different Colors

```dart
// Purple (default app theme)
CommonLoading.purple(message: "Loading...")

// White (for dark backgrounds)
CommonLoading.white(message: "Loading...")

// Black (for light backgrounds)
CommonLoading.black(message: "Loading...")

// Custom color
CommonLoading(color: Colors.blue, message: "Loading...")
```

### Different Sizes

```dart
// Small (20px) - for inline use
CommonLoading.small()

// Medium (30px) - default size
CommonLoading.medium()

// Large (60px) - for prominent loading
CommonLoading.large()

// Custom size
CommonLoading(size: 80.0)
```

### Full Screen Loading

```dart
// Full screen overlay
return Scaffold(
  body: CommonLoading.fullScreen(
    message: "Please wait...",
  ),
);
```

## Advanced Usage

### Custom Configuration

```dart
CommonLoading(
  message: "Fetching data...",
  color: Colors.green,
  size: 45.0,
  showMessage: true,
  padding: const EdgeInsets.all(24.0),
  mainAxisAlignment: MainAxisAlignment.start,
  crossAxisAlignment: CrossAxisAlignment.center,
)
```

### In Lists and Cards

```dart
ListView.builder(
  itemBuilder: (context, index) {
    if (isLoading) {
      return Card(
        child: ListTile(
          leading: CommonLoading.small(),
          title: Text("Loading item..."),
        ),
      );
    }
    // ... normal item
  },
)
```

### Loading States in Buttons

```dart
ElevatedButton(
  onPressed: isLoading ? null : _submit,
  child: isLoading
    ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommonLoading.small(color: Colors.white),
          const SizedBox(width: 8),
          const Text("Saving..."),
        ],
      )
    : const Text("Save"),
)
```

## Migration Guide

### Replace Existing CircularProgressIndicator

**Before:**

```dart
Center(
  child: CircularProgressIndicator(
    color: Color(0xFF8E08EF),
  ),
)
```

**After:**

```dart
CommonLoading.purple()
```

### Replace White Loading

**Before:**

```dart
CircularProgressIndicator(
  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
)
```

**After:**

```dart
CommonLoading.white()
```

### Replace Sized Loading

**Before:**

```dart
SizedBox(
  width: 30,
  height: 30,
  child: CircularProgressIndicator(
    strokeWidth: 3,
    color: Colors.purple,
  ),
)
```

**After:**

```dart
CommonLoading.medium() // 30px with proportional stroke
```

## Extension Methods

Use context extensions for even easier access:

```dart
// In any widget with BuildContext
return context.purpleLoading;    // Purple loading
return context.whiteLoading;     // White loading
return context.blackLoading;     // Black loading
return context.smallLoading;     // Small size
return context.mediumLoading;    // Medium size
return context.largeLoading;     // Large size
```

## Color Reference

| Color  | Hex Code  | Usage                               |
| ------ | --------- | ----------------------------------- |
| Purple | `#8E08EF` | Primary app color, default loading  |
| White  | `#FFFFFF` | Dark backgrounds (splash, overlays) |
| Black  | `#000000` | Light backgrounds                   |

## Size Reference

| Size   | Dimensions | Use Case                            |
| ------ | ---------- | ----------------------------------- |
| Small  | 20x20px    | Inline loading, buttons, list items |
| Medium | 30x30px    | Default, general purpose            |
| Large  | 60x60px    | Full screen, prominent loading      |
| Custom | Any size   | Special cases                       |

## Implementation Details

### Stroke Width

- Automatically calculated as 10% of size
- Ensures proportional appearance across sizes
- Small (20px) = 2px stroke
- Medium (30px) = 3px stroke
- Large (60px) = 6px stroke

### Performance

- Uses `AlwaysStoppedAnimation` for consistent color
- No unnecessary rebuilds
- Lightweight widget with minimal overhead

### Accessibility

- Respects system animation settings
- Clear visual feedback
- Optional text for screen readers

## Examples in App

### Profile Loading

```dart
// Replace in profile_loading_screen.dart
CircularProgressIndicator(color: Color(0xFF8E08EF))

// With
CommonLoading.purple()
```

### Splash Screen

```dart
// Replace in splash_screen.dart
CircularProgressIndicator(
  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
)

// With
CommonLoading.white()
```

### Search Results

```dart
// Replace in search_feed_screen.dart
Center(child: CircularProgressIndicator())

// With
Center(child: CommonLoading.purple(message: "Searching..."))
```

### Post Tabs

```dart
// Replace in thought_posts_tab.dart
Center(child: CircularProgressIndicator())

// With
Center(child: CommonLoading.purple(message: "Loading posts..."))
```

## Testing

### Visual Testing

- Test all color variants on different backgrounds
- Verify sizes look proportional
- Check message alignment

### Integration Testing

- Replace existing loading indicators gradually
- Test in different screen sizes
- Verify no performance impact

## Future Enhancements

Potential improvements for the future:

- Loading states with progress (0-100%)
- Different animation styles (pulse, bounce, etc.)
- Loading with icons or illustrations
- Themed loading based on app sections

## File Location

```
lib/presentation/widgets/common_loading.dart
```

## Dependencies

- Flutter SDK
- No external packages required

---

**Note:** This widget centralizes loading UI patterns and ensures consistency across the entire application. Use it everywhere you previously used `CircularProgressIndicator` for a unified user experience.
