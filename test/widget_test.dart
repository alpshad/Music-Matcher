// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_matcher/signin/signin-flow.dart';
import 'package:music_matcher/spotify/spotify-profile.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as s;
import 'package:music_matcher/main.dart';

import 'firebase_mock.dart';

void main() {
  Widget createWidgetForTesting({required Widget child}){
    return MaterialApp(
      home: child,
    );
  }

  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  final client = s.StreamChatClient(
    '3zcmfx8umv2e',
    logLevel: s.Level.INFO,);

  testWidgets('Login test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(createWidgetForTesting(child: LoginScreen(client: client, title: "Login",)));

    // Verify that our counter starts at 0.
    expect(find.text("Log in"), findsOneWidget);
  });

  testWidgets('signup test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(createWidgetForTesting(child: SignupScreen(client: client,)));

    // Verify that our counter starts at 0.
    expect(find.text("Sign up"), findsOneWidget);
  });

  testWidgets('MainPageTest', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(createWidgetForTesting(child: HomeScreen(client: client)));

    // Verify that our counter starts at 0.
    expect(find.text("Chat!"), findsOneWidget);
    expect(find.text('Nearby Friends!'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });
}
