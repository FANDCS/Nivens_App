import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scribble/scribble.dart';

class DrawingResult {
  final Uint8List pngBytes;
  DrawingResult({required this.pngBytes});
}

class DrawingScreen extends StatefulWidget {
  final String? title;
  const DrawingScreen({super.key, this.title});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late ScribbleNotifier _notifier;
  final _repaintKey = GlobalKey();
  bool _erasing = false;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4.0;
  bool _isSaving = false;

  static const _palette = [
    Colors.black, Colors.white, Colors.red, Colors.orange,
    Colors.yellow, Colors.green, Colors.teal, Colors.blue,
    Colors.indigo, Colors.purple, Colors.pink, Colors.brown, Colors.grey,
  ];
  static const _strokeSizes = [2.0, 4.0, 8.0, 14.0, 22.0];

  @override
  void initState() {
    super.initState();
    // scribble 0.10.x API — χωρίς widthRange στον constructor
    _notifier = ScribbleNotifier();
    _applyPen();
  }

  void _applyPen() {
    _notifier.setColor(_selectedColor);
    _notifier.setStrokeWidth(_strokeWidth);
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  void _setColor(Color c) {
    setState(() { _selectedColor = c; _erasing = false; });
    _notifier.setColor(c);
  }

  void _setStroke(double w) {
    setState(() => _strokeWidth = w);
    _notifier.setStrokeWidth(w);
    if (_erasing) _notifier.setEraser();
  }

  void _toggleEraser() {
    setState(() => _erasing = !_erasing);
    if (_erasing) { _notifier.setEraser(); } else { _notifier.setColor(_selectedColor); }
  }

  /// Αποδίδει το canvas σε PNG χρησιμοποιώντας RepaintBoundary.
  Future<Uint8List> _captureAsPng() async {
    final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final png = await _captureAsPng();
      if (mounted) Navigator.of(context).pop(DrawingResult(pngBytes: png));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: Text(widget.title ?? 'Σχέδιο'),
        actions: [
          IconButton(icon: const Icon(Icons.undo), tooltip: 'Αναίρεση', onPressed: () => _notifier.undo()),
          IconButton(icon: const Icon(Icons.redo), tooltip: 'Επαναφορά', onPressed: () => _notifier.redo()),
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Καθαρισμός', onPressed: () => _notifier.clear()),
          IconButton(
            icon: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            tooltip: 'Αποθήκευση',
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Canvas ─────────────────────────────────────────────────────────
          Expanded(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Scribble(notifier: _notifier, drawPen: true),
            ),
          ),

          // ── Toolbar ────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Χρωματική παλέτα
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(children: [
                    // Eraser
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: _toggleEraser,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _erasing ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                              width: _erasing ? 3 : 1.5,
                            ),
                          ),
                          child: const Icon(Icons.auto_fix_normal, size: 18),
                        ),
                      ),
                    ),
                    // Palette
                    for (final color in _palette)
                      GestureDetector(
                        onTap: () => _setColor(color),
                        child: Container(
                          width: 30, height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: (!_erasing && _selectedColor.value == color.value)
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                              width: (!_erasing && _selectedColor.value == color.value) ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                    // Custom color picker
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await _showRgbPicker();
                        if (picked != null) _setColor(picked);
                      },
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const SweepGradient(colors: [
                            Colors.red, Colors.orange, Colors.yellow,
                            Colors.green, Colors.blue, Colors.purple, Colors.red,
                          ]),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: const Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
                // Μέγεθος πινέλου
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  child: Row(children: [
                    const Icon(Icons.brush, size: 16),
                    const SizedBox(width: 6),
                    for (final size in _strokeSizes)
                      GestureDetector(
                        onTap: () => _setStroke(size),
                        child: Container(
                          width: 36, height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _strokeWidth == size ? Theme.of(context).colorScheme.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: size.clamp(3, 26),
                              height: size.clamp(3, 26),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _erasing ? Theme.of(context).dividerColor : _selectedColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Color?> _showRgbPicker() {
    Color temp = _selectedColor;
    return showDialog<Color>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          int r = (temp.value >> 16) & 0xFF;
          int g = (temp.value >> 8) & 0xFF;
          int b = temp.value & 0xFF;
          return AlertDialog(
            title: const Text('Επιλογή χρώματος'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: temp, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 12),
                _slider(ctx, setS, 'R', r.toDouble(), (v) { r = v.toInt(); temp = Color.fromARGB(255, r, g, b); }),
                _slider(ctx, setS, 'G', g.toDouble(), (v) { g = v.toInt(); temp = Color.fromARGB(255, r, g, b); }),
                _slider(ctx, setS, 'B', b.toDouble(), (v) { b = v.toInt(); temp = Color.fromARGB(255, r, g, b); }),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Άκυρο')),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(temp), child: const Text('ΟΚ')),
            ],
          );
        },
      ),
    );
  }

  Widget _slider(BuildContext ctx, StateSetter setS, String label, double value, ValueChanged<double> onChanged) {
    return Row(children: [
      SizedBox(width: 16, child: Text(label, style: const TextStyle(fontSize: 12))),
      Expanded(
        child: Slider(
          value: value, max: 255, divisions: 255,
          onChanged: (v) => setS(() => onChanged(v)),
        ),
      ),
      SizedBox(width: 28, child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
    ]);
  }
}
