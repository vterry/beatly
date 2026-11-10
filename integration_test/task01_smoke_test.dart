import 'package:beatly/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ITC-01.01: Inicializa o BeatlyApp no tema Obsidian Dark sem erros', (tester) async {
    await tester.pumpWidget(const BeatlyApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('beatly_home_card')), findsOneWidget);
    expect(find.text('Beatly'), findsOneWidget);
  });
}

