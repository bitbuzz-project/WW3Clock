import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ww3_clock/main.dart';

void main() {
  testWidgets('WW3 Clock app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WW3ClockApp());

    // Verify that our app loads with the WW3 Clock title
    expect(find.text('WW3 Clock'), findsOneWidget);
    
    // Verify that the main screen navigation elements exist
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}