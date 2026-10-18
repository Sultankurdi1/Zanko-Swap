import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../core/data/document_cache_service.dart';
import '../../../core/localization/app_strings.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  const PdfViewerScreen({super.key, required this.url, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool downloading = false;

  Future<void> _download() async {
    setState(() => downloading = true);
    try {
      final file = await DocumentCacheService.downloadToDocuments(
        widget.url,
        fileName: '${widget.title}.pdf',
      );
      if (!mounted) return;
      setState(() => localPath = file.path);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).pdfSaved)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = localPath;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: AppStrings.of(context).download,
            onPressed: downloading ? null : _download,
            icon: downloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: source != null
          ? PdfViewer.file(source)
          : PdfViewer.uri(Uri.parse(widget.url)),
    );
  }
}
