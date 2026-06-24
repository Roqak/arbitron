import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arbitron/core/theme/app_theme.dart';
import 'package:arbitron/core/widgets/status_chip.dart';

void main() {
  testWidgets('StatusChip renders label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: const Scaffold(body: StatusChip(label: 'Active', tone: ChipTone.accent))),
    );
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('AppTheme dark builds without error', (tester) async {
    expect(() => AppTheme.dark(), returnsNormally);
    expect(() => AppTheme.light(), returnsNormally);
  });
}