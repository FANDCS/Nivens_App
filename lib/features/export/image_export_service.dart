import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;

import '../../core/storage/nivens_folder.dart';

/// Εξαγωγή σημείωσης ως εικόνα/ες PNG — «σαν στιγμιότυπο οθόνης».
///
/// Δύο πηγές:
///  * [captureBoundary]: στιγμιότυπο του RepaintBoundary της Προβολής
///    (αποδοσμένο markdown + πολυμέσα + ζωγραφιά όπως φαίνονται);
///  * [renderText]: στιγμιότυπο του κειμένου της λειτουργίας επεξεργασίας.
///    Το TextField του editor έχει ύψος οθόνης και scrollάρει, οπότε ένα
///    απλό screenshot θα έπιανε μόνο το ορατό κομμάτι· εδώ το κείμενο
///    ζωγραφίζεται ΟΛΟΚΛΗΡΟ (με το ίδιο TextSpan/στυλ του editor).
///
/// Αν το αποτέλεσμα είναι ψηλότερο από [maxSliceHeightPx] κόβεται σε
/// περισσότερες εικόνες ίσου ύψους (στο κείμενο η κοπή γίνεται ΑΝΑΜΕΣΑ σε
/// γραμμές, ώστε να μη «κόβεται» κανένας χαρακτήρας στη μέση).
class ImageExportService {
  ImageExportService._();

  /// Μέγιστο ύψος (σε pixel) μίας εικόνας εξόδου.
  static const int maxSliceHeightPx = 4000;

  /// Μέγιστο ύψος ενός ενιαίου στιγμιότυπου της Προβολής (όριο υφής GPU) —
  /// για πολύ μεγάλες σημειώσεις μειώνεται αυτόματα η ανάλυση.
  static const int _maxCapturePx = 16000;

  // ── Προβολή (RepaintBoundary) ────────────────────────────────────────────

  static Future<List<Uint8List>> captureBoundary(
    RenderRepaintBoundary boundary, {
    double pixelRatio = 2.0,
  }) async {
    var ratio = pixelRatio;
    final h = boundary.size.height;
    if (h * ratio > _maxCapturePx) {
      ratio = (_maxCapturePx / h).clamp(0.5, pixelRatio).toDouble();
    }
    final image = await boundary.toImage(pixelRatio: ratio);
    try {
      return await _slice(image);
    } finally {
      image.dispose();
    }
  }

  /// Κόβει μια εικόνα σε N κομμάτια ίσου ύψους (≤ [maxSliceHeightPx]) και
  /// τα κωδικοποιεί σε PNG. Μία εικόνα αν χωράει.
  static Future<List<Uint8List>> _slice(ui.Image image) async {
    final w = image.width;
    final h = image.height;
    if (h <= maxSliceHeightPx) return [await _png(image)];

    final count = (h / maxSliceHeightPx).ceil();
    final sliceH = (h / count).ceil();
    final out = <Uint8List>[];
    for (var top = 0; top < h; top += sliceH) {
      final thisH = (top + sliceH > h) ? h - top : sliceH;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, top.toDouble(), w.toDouble(), thisH.toDouble()),
        Rect.fromLTWH(0, 0, w.toDouble(), thisH.toDouble()),
        Paint(),
      );
      final picture = recorder.endRecording();
      final slice = await picture.toImage(w, thisH);
      picture.dispose();
      try {
        out.add(await _png(slice));
      } finally {
        slice.dispose();
      }
    }
    return out;
  }

  // ── Επεξεργασία (κείμενο) ────────────────────────────────────────────────

  /// Ζωγραφίζει το [span] σε πλάτος [width] (λογικά pixel, ΣΥΜΠΕΡΙΛΑΜΒΑΝΕΤΑΙ
  /// το [padding]) πάνω σε φόντο [background] και το επιστρέφει ως PNG(ς).
  static Future<List<Uint8List>> renderText({
    required InlineSpan span,
    required double width,
    required Color background,
    TextScaler textScaler = TextScaler.noScaling,
    EdgeInsets padding = const EdgeInsets.all(16),
    double pixelRatio = 2.0,
  }) async {
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    );
    try {
      painter.layout(maxWidth: (width - padding.horizontal).clamp(40.0, double.infinity).toDouble());
      final contentH = painter.height;
      final maxSliceLogical = maxSliceHeightPx / pixelRatio;

      // Σημεία κοπής (σε συντεταγμένες κειμένου) ανάμεσα σε γραμμές.
      final cuts = <double>[0];
      var prevBottom = 0.0;
      for (final m in painter.computeLineMetrics()) {
        final top = m.baseline - m.ascent;
        final bottom = m.baseline + m.descent;
        if (bottom - cuts.last + padding.vertical > maxSliceLogical && prevBottom > cuts.last) {
          cuts.add((prevBottom + top) / 2); // στη μέση του κενού ανάμεσα στις γραμμές
        }
        prevBottom = bottom;
      }
      cuts.add(contentH);

      final out = <Uint8List>[];
      for (var i = 0; i < cuts.length - 1; i++) {
        final from = cuts[i];
        final to = cuts[i + 1];
        final padTop = i == 0 ? padding.top : 0.0;
        final padBottom = i == cuts.length - 2 ? padding.bottom : 0.0;
        final sliceH = (to - from) + padTop + padBottom;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.scale(pixelRatio);
        canvas.drawRect(Rect.fromLTWH(0, 0, width, sliceH), Paint()..color = background);
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(0, padTop, width, to - from));
        canvas.translate(padding.left, padTop - from);
        painter.paint(canvas, Offset.zero);
        canvas.restore();
        final picture = recorder.endRecording();
        final image = await picture.toImage(
          (width * pixelRatio).ceil(),
          (sliceH * pixelRatio).ceil().clamp(1, 1 << 30).toInt(),
        );
        picture.dispose();
        try {
          out.add(await _png(image));
        } finally {
          image.dispose();
        }
      }
      return out;
    } finally {
      painter.dispose();
    }
  }

  // ── Αποθήκευση ───────────────────────────────────────────────────────────

  /// Γράφει τα PNG στον φάκελο Documents/Nivens/exports και επιστρέφει τα
  /// paths. Όνομα: `<baseName>_<ημερομηνία>_<ώρα>[_NN].png` (με αριθμό
  /// μόνο όταν είναι περισσότερες από μία εικόνες).
  static Future<List<String>> savePngs(List<Uint8List> pngs, String baseName) async {
    final dir = await NivensFolder.sub('exports');
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
    final paths = <String>[];
    for (var i = 0; i < pngs.length; i++) {
      final suffix = pngs.length == 1 ? '' : '_${two(i + 1)}';
      final path = p.join(dir.path, '${baseName}_$stamp$suffix.png');
      await File(path).writeAsBytes(pngs[i]);
      paths.add(path);
    }
    return paths;
  }

  static Future<Uint8List> _png(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('Αποτυχία κωδικοποίησης PNG');
    return data.buffer.asUint8List();
  }
}
