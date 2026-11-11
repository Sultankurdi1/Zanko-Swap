import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/supabase_storage_service.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/academic_path.dart';
import '../../../core/models/research_paper.dart';
import '../../academic/academic_path_picker.dart';
import '../data/research_repository.dart';

class AddResearchScreen extends StatefulWidget {
  final AcademicPath initialPath;
  final ResearchPaper? existing;
  const AddResearchScreen({
    super.key,
    this.initialPath = const AcademicPath(),
    this.existing,
  });

  bool get isEditing => existing != null;

  @override
  State<AddResearchScreen> createState() => _AddResearchScreenState();
}

class _AddResearchScreenState extends State<AddResearchScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  final fileUrl = TextEditingController();
  final repository = ResearchRepository();
  late AcademicPath path;
  bool saving = false;
  String? pdfName;
  Uint8List? pdfBytes;

  Future<void> pickPdf() async {
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null) return;
    final size = await file.length() ?? 0;
    if (size > SupabaseStorageService.maxPdfMb * 1024 * 1024) {
      messenger.showSnackBar(
        SnackBar(content: Text(s.pdfTooLarge(SupabaseStorageService.maxPdfMb))),
      );
      return;
    }
    final bytes = await file.readAsBytes();
    final isPdf =
        bytes.length > 5 &&
        String.fromCharCodes(bytes.sublist(0, 5)) == '%PDF-';
    if (!isPdf) {
      messenger.showSnackBar(SnackBar(content: Text(s.onlyPdf)));
      return;
    }
    if (mounted) {
      setState(() {
        pdfName = file.name;
        pdfBytes = bytes;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    path = widget.existing?.path ?? widget.initialPath;
    final r = widget.existing;
    title.text = r?.title ?? '';
    description.text = r?.description ?? '';
    fileUrl.text = r?.linkOrContent ?? '';
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    fileUrl.dispose();
    super.dispose();
  }

  Future<void> publish() async {
    final s = AppStrings.of(context);
    final cleanTitle = title.text.trim();
    final cleanDesc = description.text.trim();
    final cleanUrl = fileUrl.text.trim();

    if (pdfBytes == null &&
        cleanUrl.isEmpty &&
        cleanTitle.isNotEmpty &&
        !path.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.researchContentRequired)));
      return;
    }

    if (cleanTitle.isEmpty || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.isKurdish
                ? 'تکایە ناونیشانی توێژینەوە و بەشە ئەکادیمییەکە دەستنیشان بکە.'
                : s.academicPath,
          ),
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception(
          s.isKurdish
              ? 'تکایە سەرەتا بچۆ ژوورەوە.'
              : s.isArabic
              ? 'يرجى تسجيل الدخول أولاً.'
              : s.signIn,
        );
      }

      final fileUrl = pdfBytes != null
          ? await SupabaseStorageService.uploadResearchPdf(
              ownerId: user.id,
              bytes: pdfBytes!,
            )
          : cleanUrl;

      final payload = <String, dynamic>{
        if (!widget.isEditing) 'authorId': user.id,
        if (!widget.isEditing)
          'authorName': user.userMetadata?['displayName']?.toString() ?? '',
        'title': cleanTitle,
        'description': cleanDesc,
        'file_url': fileUrl,
        'stage': path.stage,
        'universityId': path.institutionId,
        'universityName': path.institutionName,
        'collegeId': path.collegeName,
        'departmentId': path.departmentName,
      };

      if (widget.isEditing) {
        await repository.update(widget.existing!.id, payload);
      } else {
        await repository.add(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(
              widget.isEditing
                  ? 'توێژینەوەکە بە سەرکەوتوویی نوێکرایەوە'
                  : 'توێژینەوەکە بە سەرکەوتوویی بڵاوکرایەوە',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final errorText = e.toString().toLowerCase();
        String message = AppStrings.of(context).errorFor(e);
        if (errorText.contains('network') || errorText.contains('socket')) {
          message = 'کێشە لە هێڵی ئینتەرنێت هەیە، دووبارە هەوڵبدەرەوە.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(message),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? '${s.addResearch} • ${s.isKurdish
                    ? 'دەستکاریکردن'
                    : s.isArabic
                    ? 'تعديل'
                    : 'Edit'}'
              : s.addResearch,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        children: [
          AcademicPathPicker(
            initialValue: path,
            onChanged: (v) => setState(() => path = v),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: title,
            decoration: InputDecoration(
              labelText: s.researchTitle,
              hintText: 'نموونە: زیرەکی دەستکرد لە پزیشکیدا',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: description,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: s.isKurdish
                  ? 'کورتەیەک لەبارەی توێژینەوەکە'
                  : s.isArabic
                  ? 'وصف مختصر'
                  : 'Short description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: saving ? null : pickPdf,
            icon: Icon(
              pdfBytes == null
                  ? Icons.upload_file_rounded
                  : Icons.picture_as_pdf_rounded,
              color: pdfBytes == null ? null : Colors.red.shade600,
            ),
            label: Text(
              pdfBytes == null
                  ? s.attachPdf
                  : '$pdfName  (${(pdfBytes!.length / 1048576).toStringAsFixed(1)} MB)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (pdfBytes != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: saving
                    ? null
                    : () => setState(() {
                        pdfName = null;
                        pdfBytes = null;
                      }),
                child: Text(s.cancel),
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: fileUrl,
            enabled: pdfBytes == null,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: s.contentOrLink,
              helperText: s.orPasteLink,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 26),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: saving ? null : publish,
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.isEditing
                        ? (s.isKurdish
                              ? 'پاشەکەوتکردن'
                              : s.isArabic
                              ? 'حفظ التغييرات'
                              : 'Save changes')
                        : s.addResearch,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
