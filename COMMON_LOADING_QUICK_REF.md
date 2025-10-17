# Common Loading Widget - Quick Reference

## 🎯 Quick Start

```dart
import '../../widgets/common_loading.dart';

// Basic purple loading (app theme)
CommonLoading()

// Using context extensions
context.purpleLoading
```

## 🎨 Color Options

| Code                                | Result       | Use Case              |
| ----------------------------------- | ------------ | --------------------- |
| `CommonLoading.purple()`            | Purple wheel | Default, most screens |
| `CommonLoading.white()`             | White wheel  | Dark backgrounds      |
| `CommonLoading.black()`             | Black wheel  | Light backgrounds     |
| `CommonLoading(color: Colors.blue)` | Custom color | Special cases         |

## 📏 Size Options

| Code                        | Size   | Use Case        |
| --------------------------- | ------ | --------------- |
| `CommonLoading.small()`     | 20px   | Buttons, inline |
| `CommonLoading.medium()`    | 30px   | Default, lists  |
| `CommonLoading.large()`     | 60px   | Full screen     |
| `CommonLoading(size: 80.0)` | Custom | Special layouts |

## 💬 With Messages

```dart
// Loading with text
CommonLoading.purple(message: "Loading...")

// Full screen with message
CommonLoading.fullScreen(message: "Please wait...")
```

## 🔧 Advanced Usage

```dart
// Custom everything
CommonLoading(
  message: "Fetching data...",
  color: Colors.green,
  size: 45.0,
  padding: EdgeInsets.all(24.0),
  mainAxisAlignment: MainAxisAlignment.start,
)
```

## 🔄 Migration Examples

### Before → After

```dart
// OLD
Center(child: CircularProgressIndicator())

// NEW
Center(child: CommonLoading.purple())
```

```dart
// OLD
CircularProgressIndicator(color: Color(0xFF8E08EF))

// NEW
CommonLoading.purple()
```

```dart
// OLD
CircularProgressIndicator(
  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
)

// NEW
CommonLoading.white()
```

## 📱 Context Extensions

```dart
// Easy access anywhere in widgets
context.purpleLoading   // Purple
context.whiteLoading    // White
context.blackLoading    // Black
context.smallLoading    // 20px
context.mediumLoading   // 30px
context.largeLoading    // 60px
```

## 🎯 Common Patterns

### Button Loading State

```dart
ElevatedButton(
  onPressed: isLoading ? null : _submit,
  child: isLoading
    ? Row(children: [
        CommonLoading.small(color: Colors.white),
        SizedBox(width: 8),
        Text("Saving..."),
      ])
    : Text("Save"),
)
```

### List Loading Item

```dart
if (isLoading) {
  return ListTile(
    leading: CommonLoading.small(),
    title: Text("Loading..."),
  );
}
```

### Full Screen Loading

```dart
return Scaffold(
  body: CommonLoading.fullScreen(
    message: "Loading your profile...",
  ),
);
```

## 📂 File Location

```
lib/presentation/widgets/common_loading.dart
```

## ✅ Benefits

- **Consistent** - Same loading style everywhere
- **Flexible** - Multiple sizes and colors
- **Easy** - Simple API with extensions
- **Maintainable** - Single source of truth
- **Accessible** - Proper contrast and animation

---

**Pro Tip:** Use `context.purpleLoading` for quick purple loading anywhere in your widgets!
