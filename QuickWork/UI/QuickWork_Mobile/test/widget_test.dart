// Basic smoke test for the QuickWork app.
import 'package:flutter_test/flutter_test.dart';

import 'package:quickwork_mobile/app/app.dart';

void main() {
  testWidgets('QuickWork app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const QuickWorkApp());

    // The placeholder home shows the app title.
    expect(find.text('QuickWork'), findsOneWidget);
  });
}

