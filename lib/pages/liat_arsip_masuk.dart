import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatelessWidget {
  final String pdfUrl;

  const PdfViewerPage({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(
        children: [
          const Text('Lihat Lampiran'),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.download, size: 24),
          ),
          SizedBox(width: 10),
        ],
      )),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}
