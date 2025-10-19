// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:Noot/main.dart';
import 'package:Noot/core/providers/auth_provider.dart';
import 'package:Noot/core/providers/theme_provider.dart';
import 'package:Noot/data/services/auth_service.dart';
import 'package:Noot/core/router/app_router.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Create providers
    final authProvider = AuthProvider();
    final themeProvider = ThemeProvider();

    // Load user data from shared preferences (mock for test)
    await authProvider.loadUserDataFromSharedPreferences();

    // Create auth service
    final authService = AuthService(authProvider);

    // Initialize services (catch errors for test)
    await authService.initialize().catchError((e) {
      // Ignore errors in test
    });

    // Create the router instance
    final appRouter = AppRouter(authProvider);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: authProvider),
          Provider.value(value: authService),
        ],
        child: MyApp(appRouter: appRouter),
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
