import 'package:flutter_test/flutter_test.dart';

import 'package:educampus_app/main.dart';

void main() {
  testWidgets('La app arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const EduCampusApp());

    expect(find.byType(EduCampusApp), findsOneWidget);
  });
}
