import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Προβολή ενός PDF αρχείου μέσα στην εφαρμογή — πέρα από την εξαγωγή
/// κειμένου, ο χρήστης μπορεί τώρα να δει το PDF όπως είναι (σελίδες,
/// διάταξη, εικόνες), με zoom και αναζήτηση κειμένου.
class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String? title;
  const PdfViewerScreen({super.key, required this.filePath, this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  bool _searching = false;
  final _searchController = TextEditingController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  @override
  void dispose() {
    _searchController.dispose();
    _searchResult.clear();
    super.dispose();
  }

  void _doSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _searchResult = _controller.searchText(query.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Αναζήτηση στο PDF...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onSubmitted: _doSearch,
              )
            : Text(widget.title ?? 'PDF'),
        actions: [
          if (_searching && _searchResult.hasResult) ...[
            IconButton(icon: const Icon(Icons.keyboard_arrow_up), onPressed: () => _searchResult.previousInstance()),
            IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => _searchResult.nextInstance()),
          ],
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _searchController.clear();
                _searchResult.clear();
              }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Μεγέθυνση',
            onPressed: () => _controller.zoomLevel = (_controller.zoomLevel + 0.25).clamp(1.0, 4.0),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Σμίκρυνση',
            onPressed: () => _controller.zoomLevel = (_controller.zoomLevel - 0.25).clamp(1.0, 4.0),
          ),
        ],
      ),
      body: SfPdfViewer.file(
        File(widget.filePath),
        controller: _controller,
        enableTextSelection: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}
