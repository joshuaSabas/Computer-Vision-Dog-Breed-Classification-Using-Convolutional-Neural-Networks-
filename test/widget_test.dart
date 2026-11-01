import 'package:flutter_test/flutter_test.dart';
import 'package:dog_breed_classifier/main.dart';

void main() {
  testWidgets('app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Dog Breed Classifier'), findsOneWidget);
  });
}
