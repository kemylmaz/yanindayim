import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaninda/app.dart';

void main() {
  testWidgets('Mode selection screen shows two cards', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: YanindaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Mağdur'), findsOneWidget);
    expect(find.text('Kurtarıcı'), findsOneWidget);
  });
}
