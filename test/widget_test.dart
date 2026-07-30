import 'package:flutter_test/flutter_test.dart';
import 'package:terra_link/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    await tester.pumpWidget(const TerraLinkApp());
    expect(find.byType(TerraLinkApp), findsOneWidget);
  });
}
