import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/supabase_storage_service.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/exam_paper.dart';
import '../data/exam_repository.dart';

class AddExamPaperScreen extends StatefulWidget {
  final ExamPaper? existing;
  const AddExamPaperScreen({super.key, this.existing});

  bool get isEditing => existing != null;

  @override
  State<AddExamPaperScreen> createState() => _AddExamPaperScreenState();
}

class _AddExamPaperScreenState extends State<AddExamPaperScreen> {
  final subject = TextEditingController();
  final year = TextEditingController();
  final repository = ExamRepository();
  final picker = ImagePicker();

  final List<XFile> images = [];
  late List<String> existingImages;
  late String track;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    track = e?.track ?? 'scientific';
    existingImages = List<String>.from(e?.images ?? const <String>[]);
    subject.text = e?.subject ?? '';
    year.text = e?.year ?? '';
  }

  Future<void> chooseImages() async {
    final remaining = 6 - existingImages.length - images.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ناتوانیت لە ٦ وێنە زیاتر دابنێیت.')),
      );
      return;
    }

    try {
      final picked = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (!mounted || picked.isEmpty) return;
      setState(() => images.addAll(picked.take(remaining)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کێشەیەک لە هەڵبژاردنی وێنەکان ڕوویدا.'),
          ),
        );
      }
    }
  }

  Future<List<String>> uploadImages(String ownerId) async {
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      final file = File(images[i].path);
      if (!await file.exists()) continue;
      final fileName =
          'exam_${ownerId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final url = await SupabaseStorageService.uploadListingImage(
        ownerId: ownerId,
        file: file,
        fileName: fileName,
      );
      urls.add(url);
    }
    return urls;
  }

  @override
  void dispose() {
    subject.dispose();
    year.dispose();
    super.dispose();
  }

  Future<void> publish() async {
    final s = AppStrings.of(context);

    final cleanSubject = subject.text.trim();
    final cleanYear = year.text.trim();

    if (cleanSubject.isEmpty || cleanYear.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تکایە ناوی وانە و ساڵ بنووسە.')),
      );
      return;
    }

    if (existingImages.isEmpty && images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تکایە وێنەی ئەسیلەکە دابنێ.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception(
          s.isKurdish
              ? 'تکایە سەرەتا بە هەژمارەکەت بچۆ ژوورەوە.'
              : 'Please sign in first.',
        );
      }

      List<String> uploaded = [];
      if (images.isNotEmpty) {
        uploaded = await uploadImages(user.id);
      }

      final data = <String, dynamic>{
        'subject': cleanSubject,
        'track': track,
        'year': cleanYear,
        'images': [...existingImages, ...uploaded],
      };

      if (widget.isEditing) {
        await repository.update(widget.existing!.id, data);
      } else {
        await repository.add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(
              widget.isEditing
                  ? 'بە سەرکەوتوویی دەستکاری کرا'
                  : 'ئەسیلەکە بە سەرکەوتوویی زیادکرا',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red.shade700, content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final count = existingImages.length + images.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? '${s.addExamPaper} • ${s.isKurdish
                    ? 'دەستکاریکردن'
                    : s.isArabic
                    ? 'تعديل'
                    : 'Edit'}'
              : s.addExamPaper,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: track,
            decoration: InputDecoration(
              labelText: s.track,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'scientific',
                child: Text(s.scientificTrack),
              ),
              DropdownMenuItem(value: 'literary', child: Text(s.literaryTrack)),
            ],
            onChanged: (v) => setState(() => track = v ?? track),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: subject,
            decoration: InputDecoration(
              labelText: s.subject,
              hintText: 'نموونە: بیرکاری',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: year,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: s.year,
              hintText: 'نموونە: 2024',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: saving ? null : chooseImages,
            icon: const Icon(Icons.add_photo_alternate_rounded),
            label: Text(
              '${s.isKurdish
                  ? 'وێنەی ئەسیلە'
                  : s.isArabic
                  ? 'صور الأسئلة'
                  : 'Exam images'} ($count/6)',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (existingImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: existingImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        existingImages[index],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 3,
                      top: 3,
                      child: InkWell(
                        onTap: () =>
                            setState(() => existingImages.removeAt(index)),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(images[index].path),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 3,
                      top: 3,
                      child: InkWell(
                        onTap: () => setState(() => images.removeAt(index)),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
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
                              ? 'پاشەکەوتکردنی گۆڕانکارییەکان'
                              : 'Save changes')
                        : s.addExamPaper,
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
