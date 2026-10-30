import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledcare_mobile/app.dart';
import 'package:ledcare_mobile/core/auth/token_storage.dart';

/// Supplied with `--dart-define=LEDCARE_TEST_PASSWORD=...` (never hardcoded).
const testPassword = String.fromEnvironment('LEDCARE_TEST_PASSWORD');

/// Pumps until [finder] matches or [timeout] elapses (real network).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out after $timeout waiting for $finder');
}

/// Starts the real app against the real API with an empty session.
Future<ProviderContainer> startSignedOut(WidgetTester tester) async {
  await SecureTokenStore().clear();
  await tester.pumpWidget(const ProviderScope(retry: noRetry, child: LedCareApp()));
  await pumpUntilFound(tester, find.byKey(const Key('loginScreen')));
  return ProviderScope.containerOf(tester.element(find.byType(LedCareApp)));
}

Future<void> login(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const Key('emailField')), email);
  await tester.enterText(find.byKey(const Key('passwordField')), testPassword);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}
