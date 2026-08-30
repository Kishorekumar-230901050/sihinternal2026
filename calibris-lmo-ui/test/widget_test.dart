import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmo_app/app.dart';

Future<void> simulateAndroidBackButton(WidgetTester tester) async {
  final ByteData message =
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute'));
  await tester.binding.defaultBinaryMessenger
      .handlePlatformMessage('flutter/navigation', message, (_) {});
}

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LmoApp());
    expect(find.byType(LmoApp), findsOneWidget);
  });

  testWidgets('Dashboard back button shows exit confirmation dialog and cancel dismisses it', (WidgetTester tester) async {
    await tester.pumpWidget(const LmoApp());
    await tester.pumpAndSettle();

    // Login
    final loginButton = find.widgetWithText(ElevatedButton, 'LOGIN');
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify dashboard is shown
    expect(find.text('LMO Dashboard'), findsOneWidget);

    // Simulate system back button on Dashboard
    final backFuture = simulateAndroidBackButton(tester);
    await tester.pumpAndSettle();

    // Verify Exit confirmation dialog appears
    expect(find.text('Exit application?'), findsOneWidget);
    expect(find.text('Are you sure you want to exit the LMO Portal?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await backFuture;

    // Verify dialog is dismissed and still on Dashboard
    expect(find.text('Exit application?'), findsNothing);
    expect(find.text('LMO Dashboard'), findsOneWidget);
  });

  testWidgets('Secondary screen back button returns to previous screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LmoApp());
    await tester.pumpAndSettle();

    // Login
    await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
    await tester.pumpAndSettle();

    // Tap Notifications icon
    await tester.tap(find.byIcon(Icons.notifications));
    await tester.pumpAndSettle();

    // Verify Notifications screen is open
    expect(find.text('Notifications'), findsOneWidget);

    // Simulate system back button
    await simulateAndroidBackButton(tester);
    await tester.pumpAndSettle();

    // Verify returned to Dashboard
    expect(find.text('LMO Dashboard'), findsOneWidget);
  });

  testWidgets('Dashboard back button shows exit confirmation dialog and exit confirms exit', (WidgetTester tester) async {
    await tester.pumpWidget(const LmoApp());
    await tester.pumpAndSettle();

    // Login
    await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
    await tester.pumpAndSettle();

    // Verify dashboard is shown
    expect(find.text('LMO Dashboard'), findsOneWidget);

    // Simulate system back button on Dashboard
    final backFuture = simulateAndroidBackButton(tester);
    await tester.pumpAndSettle();

    // Verify Exit confirmation dialog appears
    expect(find.text('Exit application?'), findsOneWidget);

    // Tap Exit
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();
    await backFuture;

    // Verify dialog closed
    expect(find.text('Exit application?'), findsNothing);
  });

  testWidgets('Multi-level stack back navigation works correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const LmoApp());
    await tester.pumpAndSettle();

    // Login
    await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
    await tester.pumpAndSettle();

    // Open Applications list
    await tester.tap(find.text('New Applications'));
    await tester.pumpAndSettle();
    expect(find.text('Applications'), findsOneWidget);

    // Tap first application card to go to Application Details
    await tester.tap(find.text('APP-1001'));
    await tester.pumpAndSettle();
    expect(find.text('APP-1001'), findsWidgets);

    // Press Back from Application Details -> should return to Applications list
    await simulateAndroidBackButton(tester);
    await tester.pumpAndSettle();
    expect(find.text('Applications'), findsOneWidget);

    // Press Back from Applications list -> should return to Dashboard
    await simulateAndroidBackButton(tester);
    await tester.pumpAndSettle();
    expect(find.text('LMO Dashboard'), findsOneWidget);
  });
}
