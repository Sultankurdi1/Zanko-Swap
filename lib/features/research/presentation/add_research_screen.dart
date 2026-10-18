import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

      final payload = <String, dynamic>{
        'title': cleanTitle,
        'description': cleanDesc,
        'file_url': cleanUrl,
        'stage': path.stage,
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
        String message = 'هەڵەیەک ڕوویدا لە بڵاوکردنەوەدا: $e';
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
          TextField(
            controller: fileUrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: s.contentOrLink,
              helperText: s.isKurdish
                  ? 'لینکی فایلی PDF یان ناوەڕۆک'
                  : 'PDF URL or content',
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
