import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/drop_in_mandiri_page.dart';

void main() {
  testWidgets('Drop-in Mandiri full flow test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DropInMandiriScreen()));

    expect(find.text('Drop Point Margonda'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('PILIH JENIS SAMPAH'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('Ambil atau unggah foto'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('Total estimasi poin'), findsOneWidget);

    final buttonFinder = find.descendant(
      of: find.byType(OutlinedButton),
      matching: find.text('Konfirmasi Setor'),
    );
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Setor berhasil dibuat!'), findsOneWidget);
  });
}
