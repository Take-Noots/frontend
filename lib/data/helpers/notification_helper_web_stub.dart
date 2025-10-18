// notification_helper_web_stub.dart
// This file provides stub implementations for web platform

class FlutterLocalNotificationsPlugin {
  // Stub implementation - does nothing on web
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
  }) async {
    return true;
  }

  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    // Do nothing on web
  }

  T? resolvePlatformSpecificImplementation<T>() {
    return null;
  }
}

class IOSFlutterLocalNotificationsPlugin {
  Future<bool?> requestPermissions({
    bool? alert,
    bool? badge,
    bool? sound,
  }) async {
    return true;
  }
}

class Permission {
  static const notification = Permission._();
  const Permission._();
  Future<PermissionStatus> request() async => PermissionStatus.granted;
}

enum PermissionStatus { granted }

class AndroidInitializationSettings {
  const AndroidInitializationSettings(String icon);
}

class DarwinInitializationSettings {
  const DarwinInitializationSettings({
    bool? requestSoundPermission,
    bool? requestBadgePermission,
    bool? requestAlertPermission,
  });
}

class InitializationSettings {
  const InitializationSettings({
    AndroidInitializationSettings? android,
    DarwinInitializationSettings? iOS,
  });
}

class NotificationResponse {
  final String? payload;
  const NotificationResponse({this.payload});
}

class AndroidNotificationDetails {
  const AndroidNotificationDetails(
    String channelId,
    String channelName, {
    String? channelDescription,
    Importance? importance,
    Priority? priority,
    String? icon,
    Color? color,
    bool? enableLights,
    bool? enableVibration,
    bool? playSound,
    AndroidNotificationCategory? category,
    StyleInformation? styleInformation,
  });
}

class DarwinNotificationDetails {
  const DarwinNotificationDetails({
    bool? presentAlert,
    bool? presentBadge,
    bool? presentSound,
  });
}

class NotificationDetails {
  const NotificationDetails({
    AndroidNotificationDetails? android,
    DarwinNotificationDetails? iOS,
  });
}

class BigTextStyleInformation implements StyleInformation {
  const BigTextStyleInformation(String text);
}

abstract class StyleInformation {}

enum Importance { high }
enum Priority { high }
enum AndroidNotificationCategory { message }

class Color {
  final int value;
  const Color(this.value);
}

// Platform stub
class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
}