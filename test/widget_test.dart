import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_tracker/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const NexusTrackerApp());
    await tester.pump();
    expect(find.text('Nexus Tracker'), findsOneWidget);
  });
}
