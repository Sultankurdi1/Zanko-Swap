import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DocumentCacheService {
  const DocumentCacheService._();

  static Future<File> downloadToDocuments(
    String url, {
    String? fileName,
  }) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Download failed (${response.statusCode})');
    }
    final directory = await getApplicationDocumentsDirectory();
    final safeName = (fileName == null || fileName.trim().isEmpty)
        ? 'zankoswap_${DateTime.now().millisecondsSinceEpoch}.pdf'
        : fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final file = File('${directory.path}/$safeName');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }
}
