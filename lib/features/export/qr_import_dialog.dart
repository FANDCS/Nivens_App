import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/i18n.dart';

/// Εισαγωγή μέσω QR — αντίστροφο της "Εξαγωγή -> QR κωδικός". Το export
/// ΔΕΝ κρυπτογραφεί το περιεχόμενο (είναι το ίδιο plain .fnotes κείμενο,
/// απλά κωδικοποιημένο ως QR), οπότε ούτε το import χρειάζεται κωδικό —
/// επιστρέφει απευθείας το raw κείμενο (ή null αν ακυρώθηκε).
///
/// Η σάρωση με κάμερα υποστηρίζεται όπου το mobile_scanner έχει native
/// υλοποίηση (Android/iOS/macOS)· σε Linux desktop δεν υπάρχει σαρωτής
/// κάμερας οπότε μένει μόνο η επικόλληση κειμένου (π.χ. από ένα QR app
/// στο κινητό σου που αντέγραψε το αποκωδικοποιημένο κείμενο).
Future<String?> showQrImportDialog({required BuildContext context}) {
  final canScan = Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _QrImportSheet(canScan: canScan),
  );
}

class _QrImportSheet extends StatefulWidget {
  final bool canScan;
  const _QrImportSheet({required this.canScan});

  @override
  State<_QrImportSheet> createState() => _QrImportSheetState();
}

class _QrImportSheetState extends State<_QrImportSheet> {
  final _controller = TextEditingController();

  Future<void> _scan() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScannerScreen(), fullscreenDialog: true),
    );
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr(context, el: 'Εισαγωγή μέσω QR', en: 'Import via QR'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.canScan) ...[
              FilledButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(tr(context, el: 'Σάρωση με κάμερα', en: 'Scan with camera')),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              widget.canScan
                  ? tr(context, el: 'Ή επικόλλησε το περιεχόμενο του QR:', en: 'Or paste the QR content:')
                  : tr(context,
                      el: 'Η σάρωση με κάμερα δεν είναι διαθέσιμη σε αυτή τη συσκευή — επικόλλησε το περιεχόμενο του QR:',
                      en: 'Camera scanning is not available on this device — paste the QR content:'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: tr(context, el: 'Κείμενο QR...', en: 'QR text...'),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr(context, el: 'Άκυρο', en: 'Cancel')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _controller.text.trim().isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_controller.text.trim()),
                  child: Text(tr(context, el: 'Εισαγωγή', en: 'Import')),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, el: 'Σάρωση QR', en: 'Scan QR'))),
      body: MobileScanner(controller: _controller, onDetect: _onDetect),
    );
  }
}
