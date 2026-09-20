import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scribble/scribble.dart';
import '../../core/i18n.dart';

class DrawingResult {
  final Uint8List pngBytes;
  DrawingResult({required this.pngBytes});
}

/// Τρόπος σχεδίασης.
enum _Tool { pen, brush, eraser }

class DrawingScreen extends StatefulWidget {
  final String? title;

  /// Προαιρετικό στιγμιότυπο (PNG) που εμφανίζεται ΚΑΤΩ από τον διάφανο
  /// καμβά σχεδίασης, ώστε ο χρήστης να ζωγραφίζει ΠΑΝΩ από ήδη υπάρχον
  /// περιεχόμενο (π.χ. όλη η σημείωση).
  final Uint8List? backgroundImageBytes;

  /// Αν true, το PNG που επιστρέφεται περιέχει **μόνο** τις πινελιές, με
  /// διάφανο φόντο (το background μένει έξω από το RepaintBoundary).
  /// Χρησιμοποιείται για το overlay layer της σημείωσης, ώστε η ζωγραφιά
  /// να μπαίνει ΠΑΝΩ από κείμενο/εικόνες χωρίς να τα «καίει» σε εικόνα.
  final bool transparentResult;

  /// Προαιρετικό υπάρχον overlay PNG — φορτώνεται ως οδηγός ώστε να
  /// συνεχίσεις μια προηγούμενη ζωγραφιά.
  final Uint8List? existingOverlayBytes;

  const DrawingScreen({
    super.key,
    this.title,
    this.backgroundImageBytes,
    this.transparentResult = false,
    this.existingOverlayBytes,
  });

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late ScribbleNotifier _notifier;
  final _repaintKey = GlobalKey();
  _Tool _tool = _Tool.pen;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4.0;
  bool _isSaving = false;

  /// Λόγος διαστάσεων (πλάτος/ύψος) που ΠΡΕΠΕΙ να έχει ο καμβάς ώστε οι
  /// πινελιές να ευθυγραμμίζονται pixel-perfect με το background (και,
  /// αντίστροφα, με το πού θα εμφανιστούν ξανά μέσα στη σημείωση). Χωρίς
  /// αυτό, ο καμβάς γέμιζε όλη την οθόνη (StackFit.expand) ενώ το
  /// background εμφανιζόταν με "letterboxing" (BoxFit.contain) — δύο
  /// διαφορετικοί χώροι συντεταγμένων, άρα ό,τι ζωγράφιζες εμφανιζόταν
  /// μετατοπισμένο όταν επέστρεφε στην Προβολή.
  double? _canvasAspectRatio;

  static const _palette = [
    Colors.black, Colors.white, Colors.red, Colors.orange,
    Colors.yellow, Colors.green, Colors.teal, Colors.blue,
    Colors.indigo, Colors.purple, Colors.pink, Colors.brown, Colors.grey,
  ];
  static const _strokeSizes = [2.0, 4.0, 8.0, 14.0, 22.0];

  @override
  void initState() {
    super.initState();
    _notifier = ScribbleNotifier();
    _applyTool();
    _resolveAspectRatio();
  }

  /// Βρίσκει τις πραγματικές διαστάσεις του background/overlay ώστε ο
  /// καμβάς να «κλειδώσει» στην ίδια αναλογία.
  Future<void> _resolveAspectRatio() async {
    final bytes = widget.backgroundImageBytes ?? widget.existingOverlayBytes;
    if (bytes == null) return;
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final ratio = frame.image.width / frame.image.height;
    frame.image.dispose();
    if (mounted) setState(() => _canvasAspectRatio = ratio);
  }

  void _applyTool() {
    switch (_tool) {
      case _Tool.pen:
        _notifier.setColor(_selectedColor.withOpacity(1.0));
        _notifier.setStrokeWidth(_strokeWidth);
        break;
      case _Tool.brush:
        // Πιο «μαλακή» πινελιά: μεγαλύτερο πάχος, μερική διαφάνεια.
        _notifier.setColor(_selectedColor.withOpacity(0.55));
        _notifier.setStrokeWidth(_strokeWidth * 2.2);
        break;
      case _Tool.eraser:
        _notifier.setEraser();
        break;
    }
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  void _selectTool(_Tool t) {
    setState(() => _tool = t);
    _applyTool();
  }

  void _setColor(Color c) {
    setState(() {
      _selectedColor = c;
      if (_tool == _Tool.eraser) _tool = _Tool.pen;
    });
    _applyTool();
  }

  void _setStroke(double w) {
    setState(() => _strokeWidth = w);
    _applyTool();
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
    final needsAspectLock = widget.transparentResult &&
        (widget.backgroundImageBytes != null || widget.existingOverlayBytes != null);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: Text(widget.title ?? tr(context, el: 'Σχέδιο', en: 'Drawing')),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: tr(context, el: 'Αναίρεση', en: 'Undo'),
            onPressed: () => _notifier.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: tr(context, el: 'Επαναφορά', en: 'Redo'),
            onPressed: () => _notifier.redo(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: tr(context, el: 'Καθαρισμός', en: 'Clear'),
            onPressed: () => _notifier.clear(),
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            tooltip: tr(context, el: 'Αποθήκευση', en: 'Save'),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Canvas ─────────────────────────────────────────────────────
          // Ο καμβάς σχεδίασης είναι πάντα το ΠΙΟ ΨΗΛΟ layer· ό,τι
          // ζωγραφίζεις εμφανίζεται πάνω από ό,τι υπάρχει από κάτω.
          Expanded(
            child: (needsAspectLock && _canvasAspectRatio == null)
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: needsAspectLock
                        ? AspectRatio(
                            aspectRatio: _canvasAspectRatio!,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Οδηγός φόντου (π.χ. η σημείωση όπως
                                // φαίνεται στην Προβολή) — ΜΟΝΟ για
                                // αναφορά ενώ ζωγραφίζεις. Είναι ΕΚΤΟΣ
                                // του RepaintBoundary, άρα δεν μπαίνει
                                // στο τελικό διάφανο PNG.
                                if (widget.backgroundImageBytes != null)
                                  Positioned.fill(
                                    child: Image.memory(widget.backgroundImageBytes!, fit: BoxFit.fill),
                                  ),
                                _buildLayers(),
                              ],
                            ),
                          )
                        : _buildLayers(),
                  ),
          ),

          // ── Toolbar ────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Εργαλείο: Στυλό / Βούρτσα / Γόμα
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(children: [
                    Expanded(
                      child: _toolButton(
                        _Tool.pen,
                        Icons.edit_outlined,
                        tr(context, el: 'Στυλό', en: 'Pen'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _toolButton(
                        _Tool.brush,
                        Icons.brush_outlined,
                        tr(context, el: 'Βούρτσα', en: 'Brush'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _toolButton(
                        _Tool.eraser,
                        Icons.auto_fix_normal_outlined,
                        tr(context, el: 'Γόμα', en: 'Eraser'),
                      ),
                    ),
                  ]),
                ),
                // Χρωματική παλέτα (ανενεργή όταν είναι επιλεγμένη η γόμα)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(children: [
                    for (final color in _palette)
                      GestureDetector(
                        onTap: _tool == _Tool.eraser ? null : () => _setColor(color),
                        child: Opacity(
                          opacity: _tool == _Tool.eraser ? 0.35 : 1.0,
                          child: Container(
                            width: 30, height: 30,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: (_tool != _Tool.eraser && _selectedColor.value == color.value)
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).dividerColor,
                                width: (_tool != _Tool.eraser && _selectedColor.value == color.value) ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _tool == _Tool.eraser
                          ? null
                          : () async {
                              final picked = await _showRgbPicker();
                              if (picked != null) _setColor(picked);
                            },
                      child: Opacity(
                        opacity: _tool == _Tool.eraser ? 0.35 : 1.0,
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
                    ),
                  ]),
                ),
                // Μέγεθος πινέλου
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  child: Row(children: [
                    const Icon(Icons.line_weight, size: 16),
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
                                color: _tool == _Tool.eraser ? Theme.of(context).dividerColor : _selectedColor,
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

  Widget _toolButton(_Tool tool, IconData icon, String label) {
    final selected = _tool == tool;
    return OutlinedButton.icon(
      onPressed: () => _selectTool(tool),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? Theme.of(context).colorScheme.primaryContainer : null,
        foregroundColor: selected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
        side: BorderSide(
          color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
          width: selected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  /// Τα layers του καμβά: background (μόνο αν ΔΕΝ ζητήθηκε διάφανο
  /// αποτέλεσμα), υπάρχον overlay (οδηγός), και ο καμβάς σχεδίασης —
  /// όλα μέσα στο ΙΔΙΟ RepaintBoundary/κουτί, ώστε να ταιριάζουν ακριβώς
  /// σε θέση και μέγεθος με ό,τι θα φανεί ξανά στην Προβολή.
  Widget _buildLayers() {
    return RepaintBoundary(
      key: _repaintKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Bake-in mode (transparentResult == false): το background
          // ΜΠΑΙΝΕΙ μέσα στο αποτέλεσμα. Δεν χρησιμοποιείται σήμερα από
          // την εφαρμογή, αλλά μένει διαθέσιμο για μελλοντική χρήση.
          if (widget.backgroundImageBytes != null && !widget.transparentResult)
            Positioned.fill(
              child: Image.memory(widget.backgroundImageBytes!, fit: BoxFit.fill),
            ),
          // Το προηγούμενο overlay ΜΠΑΙΝΕΙ στο αποτέλεσμα (συσσωρευτική
          // ζωγραφική: οι παλιές πινελιές μένουν, προστίθενται νέες).
          if (widget.existingOverlayBytes != null)
            Positioned.fill(
              child: Image.memory(widget.existingOverlayBytes!, fit: BoxFit.fill),
            ),
          Scribble(notifier: _notifier, drawPen: true),
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
            title: Text(tr(context, el: 'Επιλογή χρώματος', en: 'Pick a color')),
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
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(tr(context, el: 'Άκυρο', en: 'Cancel'))),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(temp), child: const Text('OK')),
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
