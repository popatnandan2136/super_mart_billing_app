import 'package:flutter_test/flutter_test.dart';
import 'package:super_mart_billing_app/main.dart';

void main() {
  testWidgets('Super Mart Billing App renders home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SuperMartBillingApp());

    // Verify that store title and location are displayed.
    expect(find.text('SUPER MART'), findsOneWidget);
    expect(find.text('Rajkot, Gujarat'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
  });
}
