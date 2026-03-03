// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:hostel_fix/main.dart';

void main() {
  testWidgets('Landing page displays HostelFix title', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HostelFixApp());

    // Verify that our landing page displays the title.
    expect(find.text('HostelFix'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
