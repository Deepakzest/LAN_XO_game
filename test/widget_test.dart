import 'package:flutter_test/flutter_test.dart';

import 'package:tic_tac_toe_hotspot/main.dart';

void main() {
  testWidgets('app loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TicTacToeApp());

    expect(find.text('Hotspot Tic Tac Toe'), findsOneWidget);
    expect(find.text('Host Game'), findsOneWidget);
    expect(find.text('Join Game'), findsOneWidget);
  });
}
