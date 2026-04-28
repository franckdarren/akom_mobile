import 'package:flutter_test/flutter_test.dart';

import 'package:akom_scanner/shared/utils/fcfa_formatter.dart';

// fr_FR utilise U+00A0 (no-break space) ou U+202F (narrow no-break space)
// comme séparateur de milliers selon la version ICU. On normalise.
String _n(String s) => s
    .replaceAll(String.fromCharCode(0x00A0), ' ')
    .replaceAll(String.fromCharCode(0x202F), ' ');

void main() {
  group('formatFCFA', () {
    test('formats zero', () => expect(formatFCFA(0), '0 FCFA'));
    test('formats amount below 1000', () => expect(formatFCFA(500), '500 FCFA'));
    test('formats thousands with space separator', () {
      expect(_n(formatFCFA(1500)), '1 500 FCFA');
    });
    test('formats large amount', () {
      expect(_n(formatFCFA(25000)), '25 000 FCFA');
    });
    test('formats million', () {
      expect(_n(formatFCFA(1000000)), '1 000 000 FCFA');
    });
  });

  group('formatFCFACompact', () {
    test('small amount stays full format', () {
      expect(formatFCFACompact(500), '500 FCFA');
    });

    test('round thousand', () {
      expect(formatFCFACompact(2000), '2 k FCFA');
    });

    test('fractional thousand', () {
      expect(formatFCFACompact(1500), '1.5 k FCFA');
    });

    test('round million', () {
      expect(_n(formatFCFACompact(2000000)), '2 M FCFA');
    });

    test('fractional million rounds to nearest', () {
      expect(_n(formatFCFACompact(1500000)), '2 M FCFA');
    });
  });

  group('calculateChange', () {
    test('returns exact change', () {
      expect(calculateChange(1000, 2000), 1000);
    });

    test('returns zero when exact amount', () {
      expect(calculateChange(1000, 1000), 0);
    });

    test('returns null when amount insufficient', () {
      expect(calculateChange(1000, 500), isNull);
    });

    test('handles large amounts', () {
      expect(calculateChange(25000, 50000), 25000);
    });
  });
}
