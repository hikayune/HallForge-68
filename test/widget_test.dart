import 'package:flutter_test/flutter_test.dart';

import 'package:hallforge68/main.dart';

void main() {
  testWidgets('shows HallForge shell', (WidgetTester tester) async {
    await tester.pumpWidget(const HallForgeApp());

    expect(find.text('HallForge 68'), findsWidgets);
    expect(find.text('Device'), findsWidgets);
    expect(find.text('Lighting'), findsWidgets);
  });
}
