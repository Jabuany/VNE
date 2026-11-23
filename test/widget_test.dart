import 'package:flutter_test/flutter_test.dart';
import 'package:vne/main.dart';

void main() {
  testWidgets('VNE shows its title at launch', (tester) async {
    await tester.pumpWidget(const VneApp());

    expect(find.text('VNE'), findsOneWidget);
  });
}
