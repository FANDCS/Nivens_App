import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Αποτέλεσμα επιλογής clip art: ήδη rasterized PNG bytes (διάφανο φόντο),
/// έτοιμο να αποθηκευτεί σαν αρχείο εικόνας και να εισαχθεί στη σημείωση.
class ClipArtResult {
  final Uint8List pngBytes;
  ClipArtResult({required this.pngBytes});
}

/// Βιβλιοθήκη ενσωματωμένων "clip art" — δεν χρειάζεται σύνδεση στο
/// διαδίκτυο ή εξωτερικά αρχεία: κάθε clip art είναι ένα εικονίδιο του
/// Material Icons, το οποίο "τυπώνεται" (rasterize) σε πραγματικό PNG με
/// το επιλεγμένο χρώμα, ώστε να λειτουργεί ακριβώς σαν εικόνα μέσα στη
/// σημείωση (μπορεί να μετακινηθεί/να αλλάξει μέγεθος όπως κάθε άλλη
/// εικόνα).
const List<IconData> _clipArtIcons = [
  Icons.star, Icons.favorite, Icons.celebration, Icons.emoji_emotions,
  Icons.local_florist, Icons.pets, Icons.wb_sunny, Icons.cloud,
  Icons.cake, Icons.icecream, Icons.sports_soccer, Icons.sports_basketball,
  Icons.music_note, Icons.camera_alt, Icons.lightbulb, Icons.rocket_launch,
  Icons.beach_access, Icons.local_pizza, Icons.school, Icons.flag,
  Icons.check_circle, Icons.warning_amber, Icons.thumb_up, Icons.card_giftcard,
  Icons.ac_unit, Icons.anchor, Icons.bolt, Icons.bug_report,
  Icons.directions_car, Icons.flight, Icons.home, Icons.location_on,
];

const List<Color> _clipArtColors = [
  Colors.black, Colors.red, Colors.orange, Colors.amber,
  Colors.green, Colors.teal, Colors.blue, Colors.indigo,
  Colors.purple, Colors.pink, Colors.brown, Colors.grey,
];

class ClipArtPickerScreen extends StatefulWidget {
  const ClipArtPickerScreen({super.key});

  @override
  State<ClipArtPickerScreen> createState() => _ClipArtPickerScreenState();
}

class _ClipArtPickerScreenState extends State<ClipArtPickerScreen> {
  IconData? _selected;
  Color _color = Colors.black;
  bool _rendering = false;

  Future<Uint8List> _renderIconToPng(IconData icon, Color color, double size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      textPainter.width.ceil().clamp(1, 4096),
      textPainter.height.ceil().clamp(1, 4096),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _rendering = true);
    try {
      final bytes = await _renderIconToPng(_selected!, _color, 512);
      if (mounted) Navigator.of(context).pop(ClipArtResult(pngBytes: bytes));
    } finally {
      if (mounted) setState(() => _rendering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clip art'),
        actions: [
          IconButton(
            icon: _rendering
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            tooltip: 'Εισαγωγή',
            onPressed: (_selected == null || _rendering) ? null : _confirm,
          ),
        ],
      ),
      body: Column(
        children: [
          // Χρώμα
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final c in _clipArtColors)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 32, height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: Border.all(
                          color: _color.value == c.value ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                          width: _color.value == c.value ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Grid εικονιδίων
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8,
              ),
              itemCount: _clipArtIcons.length,
              itemBuilder: (ctx, i) {
                final icon = _clipArtIcons[i];
                final isSelected = _selected == icon;
                return GestureDetector(
                  onTap: () => setState(() => _selected = icon),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).dividerColor,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: Icon(icon, color: _color, size: 32),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
