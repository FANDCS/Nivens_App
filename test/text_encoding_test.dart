import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/core/text_encoding.dart';

void main() {
  // Τιμές αναφοράς παρήχθησαν με τους codecs της CPython.
  group('γνωστές αντιστοιχίσεις (χαρακτήρας ↔ byte)', () {
    final cases = <(TextEncoding, String, int)>[
      (TextEncoding.cp1253, 'α', 0xE1),
      (TextEncoding.cp737, 'α', 0x98),
      (TextEncoding.cp437, 'é', 0x82),
      (TextEncoding.macRoman, 'é', 0x8E),
      (TextEncoding.koi8r, 'А', 0xE1),
      (TextEncoding.cp866, 'Ж', 0x86),
      (TextEncoding.cp1250, 'š', 0x9A),
      (TextEncoding.iso885915, '€', 0xA4),
      (TextEncoding.cp1255, 'א', 0xE0),
      (TextEncoding.cp1256, 'ا', 0xC7),
    ];
    for (final (enc, ch, byte) in cases) {
      test('${enc.label}: $ch = 0x${byte.toRadixString(16)}', () {
        expect(TextCodecs.encode(ch, enc), [byte]);
        expect(TextCodecs.decode(Uint8List.fromList([byte]), enc), ch);
      });
    }
  });

  test('κάθε μονοψήφια κωδικοποίηση: τα ορισμένα bytes κάνουν round-trip', () {
    for (final enc in TextEncoding.all) {
      if (enc.group == 'Unicode') continue;
      for (var b = 0x20; b <= 0xFF; b++) {
        final decoded = TextCodecs.decode(Uint8List.fromList([b]), enc);
        if (decoded == '�') continue; // απροσδιόριστο byte
        expect(TextCodecs.encode(decoded, enc), [b], reason: '${enc.label} 0x${b.toRadixString(16)}');
      }
    }
  });

  group('UTF-32', () {
    test('LE με BOM', () {
      final bytes = TextCodecs.encode('A', TextEncoding.utf32le);
      expect(bytes, [0xFF, 0xFE, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00]);
      expect(TextCodecs.detect(bytes), TextEncoding.utf32le);
      expect(TextCodecs.decode(bytes, TextEncoding.utf32le), 'A');
    });

    test('BE με BOM και χαρακτήρα εκτός BMP', () {
      final bytes = TextCodecs.encode('A😀', TextEncoding.utf32be);
      expect(bytes, [0x00, 0x00, 0xFE, 0xFF, 0x00, 0x00, 0x00, 0x41, 0x00, 0x01, 0xF6, 0x00]);
      expect(TextCodecs.detect(bytes), TextEncoding.utf32be);
      expect(TextCodecs.decode(bytes, TextEncoding.utf32be), 'A😀');
    });

    test('το UTF-16 LE BOM δεν μπερδεύεται με UTF-32 LE', () {
      final bytes = TextCodecs.encode('Aβ', TextEncoding.utf16le);
      expect(TextCodecs.detect(bytes), TextEncoding.utf16le);
    });
  });

  test('US-ASCII: οι μη-ASCII χαρακτήρες γίνονται ?', () {
    expect(TextCodecs.encode('aβc', TextEncoding.ascii7), [0x61, 0x3F, 0x63]);
  });

  group('countUnencodable', () {
    test('τα ελληνικά δεν χωράνε σε Windows-1252 αλλά χωράνε σε Windows-1253', () {
      expect(TextCodecs.countUnencodable('αβγ', TextEncoding.cp1252), 3);
      expect(TextCodecs.countUnencodable('αβγ', TextEncoding.cp1253), 0);
    });

    test('Unicode: ποτέ απώλεια', () {
      expect(TextCodecs.countUnencodable('αβγ😀', TextEncoding.utf8Enc), 0);
      expect(TextCodecs.countUnencodable('αβγ😀', TextEncoding.utf32le), 0);
    });

    test('ASCII και Latin-1', () {
      expect(TextCodecs.countUnencodable('aé', TextEncoding.ascii7), 1);
      expect(TextCodecs.countUnencodable('éβ', TextEncoding.latin1), 1);
    });
  });

  test('τα ids των κωδικοποιήσεων είναι μοναδικά και βρίσκονται με byId', () {
    final ids = TextEncoding.all.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final e in TextEncoding.all) {
      expect(TextEncoding.byId(e.id), e);
    }
  });
}
