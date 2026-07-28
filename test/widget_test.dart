import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/drop_in_mandiri_page.dart';

void main() {
  testWidgets('Drop-in Mandiri full flow test', (WidgetTester tester) async {
    // Build our widget.
    await tester.pumpWidget(
      const MaterialApp(
        home: DropInMandiriScreen(),
      ),
    );

    // Verify we start at step 0 (Drop point selection)
    expect(find.text('Drop Point Margonda'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);

    // Tap "Lanjut" to go to Step 1
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    // Verify Step 1 (Waste Details)
    expect(find.text('PILIH JENIS SAMPAH'), findsOneWidget);

    // Tap "Lanjut" to go to Step 2
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    // Verify Step 2 (Photo Upload)
    expect(find.text('Ambil atau unggah foto'), findsOneWidget);

    // Tap "Lanjut" to go to Step 3
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    // Verify Step 3 (Confirmation)
    expect(find.text('Total estimasi poin'), findsOneWidget);
    
    // Tap "Konfirmasi Setor" button at the bottom
    final buttonFinder = find.descendant(
      of: find.byType(OutlinedButton),
      matching: find.text('Konfirmasi Setor'),
    );
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    // Verify Step 4 (Success)
    expect(find.text('Setor berhasil dibuat!'), findsOneWidget);
  });
}
