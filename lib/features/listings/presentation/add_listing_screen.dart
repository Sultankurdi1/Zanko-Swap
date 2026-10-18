import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/academic_path.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/supabase_storage_service.dart';
import '../../academic/academic_path_picker.dart';
import '../../auth/presentation/sign_in_screen.dart';
import '../data/listing_repository.dart';

class AddListingScreen extends StatefulWidget {
  final String initialType;
  const AddListingScreen({super.key, this.initialType = 'book'});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final locationController = TextEditingController(text: 'Erbil');

  final picker = ImagePicker();
  final repository = ListingRepository();

  final List<XFile> photos = [];
  String condition = 'like_new';
  String transactionType = 'price';
  late String listingType;
  AcademicPath path = const AcademicPath();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    listingType = widget.initialType;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _showImageSourceDialog(AppPalette palette) {
    if (photos.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ناتوانیت زیاتر لە ٦ وێنە دابنێیت.')),
      );
      return;
    }

    showModalBottomSheet(
      backgroundColor: palette.surface,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: palette.accent),
              title: Text(
                'گرتنی وێنە بە کامێرا',
                style: TextStyle(color: palette.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: palette.accent),
              title: Text(
                'هەڵبژاردن لە گەلەری',
                style: TextStyle(color: palette.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() => photos.add(photo));
      }
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    try {
      final result = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (result.isNotEmpty) {
        setState(() {
          photos.addAll(result.take(6 - photos.length));
        });
      }
    } catch (_) {}
  }

  Future<List<String>> uploadPhotos(String ownerId) async {
    final urls = <String>[];
    for (var i = 0; i < photos.length; i++) {
      try {
        final url = await SupabaseStorageService.uploadListingImage(
          ownerId: ownerId,
          file: File(photos[i].path),
          fileName: '${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        urls.add(url);
      } catch (_) {}
    }
    return urls;
  }

  Future<void> publish() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تکایە ناونیشانی بابەتەکە دیاری بکە')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      var authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
        authUser = Supabase.instance.client.auth.currentUser;
      }
      final user = authUser;
      if (user == null) return;

      final urls = await uploadPhotos(user.id);
      final isDevice = listingType == 'device';
      final cityText = locationController.text.trim().isEmpty
          ? 'Erbil'
          : locationController.text.trim();

      await repository.createListing({
        'sellerId': user.id,
        'sellerName':
            user.userMetadata?['displayName']?.toString() ?? 'Student',
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'type': listingType,
        'transactionType': transactionType,
        'priceIQD': transactionType == 'price'
            ? int.tryParse(priceController.text.trim()) ?? 0
            : 0,
        'condition': condition,
        'edition': null,
        'subject': null,
        'semester': null,
        'images': urls,
        'pdfUrl': null,
        'cityId': cityText,
        'universityName': cityText,
        if (!isDevice) ...path.toMap(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('بابەتەکەت بە سەرکەوتوویی بڵاوکرایەوە!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('هەڵە: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDevice = listingType == 'device';
    final palette = AppThemeScope.of(context);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: palette.textSecondary,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          children: [
            Text(
              'Post New Listing',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: palette.accent,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill in the details to list your item.',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upload Photos',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        'Add up to 6 (${photos.length}/6)',
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 88,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ...List.generate(photos.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(photos[i].path),
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => photos.removeAt(i)),
                                    child: const CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.black87,
                                      child: Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (photos.length < 6)
                          GestureDetector(
                            onTap: () => _showImageSourceDialog(palette),
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: palette.surfaceHighlight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: palette.accent.withValues(alpha: 0.3),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: palette.accent,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: palette.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _label('Category / جۆری بابەت', palette),
            DropdownButtonFormField<String>(
              initialValue: listingType,
              dropdownColor: palette.surface,
              style: TextStyle(color: palette.textPrimary, fontSize: 13),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: palette.textSecondary,
              ),
              decoration: _inputDecoration(palette),
              items: [
                DropdownMenuItem(
                  value: 'book',
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'کتێب (Academic Book)',
                        style: TextStyle(color: palette.textPrimary),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'handout',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: Color(0xFF06B6D4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ملزەمە و پوختە (Handout / Summary)',
                        style: TextStyle(color: palette.textPrimary),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'medical',
                  child: Row(
                    children: [
                      Icon(
                        Icons.health_and_safety_outlined,
                        size: 18,
                        color: palette.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'کەلوپەلی پزیشکی (Medical & Dental)',
                        style: TextStyle(color: palette.textPrimary),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'postgraduate',
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 18,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'خوێندنی باڵا (Postgraduate Master/PhD)',
                        style: TextStyle(color: palette.textPrimary),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'device',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.laptop_mac_rounded,
                        size: 18,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ئامێر و پێداویستی (Devices & Essentials)',
                        style: TextStyle(color: palette.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (v) => setState(() => listingType = v ?? 'book'),
            ),

            const SizedBox(height: 16),

            _label('Title / ناونیشانی بابەت', palette),
            _inputBox(
              palette: palette,
              controller: titleController,
              hint: 'ناوی کتێب، ملزەمە یان ئامێرەکە...',
            ),

            const SizedBox(height: 16),

            _label('Transaction / شێوازی مامەڵە', palette),
            DropdownButtonFormField<String>(
              initialValue: transactionType,
              dropdownColor: palette.surface,
              style: TextStyle(color: palette.textPrimary, fontSize: 13),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: palette.textSecondary,
              ),
              decoration: _inputDecoration(palette),
              items: [
                DropdownMenuItem(
                  value: 'price',
                  child: Text(
                    'Price / بە پارە',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                ),
                DropdownMenuItem(
                  value: 'free',
                  child: Text(
                    'Free / بەخۆڕایی',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                ),
                DropdownMenuItem(
                  value: 'exchange',
                  child: Text(
                    'Exchange / ئاڵوگۆڕ',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => transactionType = v ?? 'price'),
            ),

            if (transactionType == 'price') ...[
              const SizedBox(height: 16),
              _label('Price (IQD) / نرخ بە دینار', palette),
              _inputBox(
                palette: palette,
                controller: priceController,
                hint: '15000',
                keyboardType: TextInputType.number,
              ),
            ],

            const SizedBox(height: 16),

            _label('Condition / دۆخی کاڵا', palette),
            DropdownButtonFormField<String>(
              initialValue: condition,
              dropdownColor: palette.surface,
              style: TextStyle(color: palette.textPrimary, fontSize: 13),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: palette.textSecondary,
              ),
              decoration: _inputDecoration(palette),
              items: [
                DropdownMenuItem(
                  value: 'like_new',
                  child: Text(
                    'Like New / وەک نوێ',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                ),
                DropdownMenuItem(
                  value: 'new',
                  child: Text(
                    'Brand New / نوێ',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                ),
                DropdownMenuItem(
                  value: 'good',
                  child: Text(
                    'Good / باش',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                ),
                DropdownMenuItem(
                  value: 'used',
                  child: Text(
                    'Used / بەکارهاتوو',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => condition = v ?? 'like_new'),
            ),

            if (!isDevice) ...[
              const SizedBox(height: 16),
              _label('Academic Path / بەش و زانکۆ', palette),
              Container(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: AcademicPathPicker(
                  initialValue: path,
                  onChanged: (v) => path = v,
                ),
              ),
            ],

            const SizedBox(height: 16),

            _label('Location / شوێن', palette),
            _inputBox(
              palette: palette,
              controller: locationController,
              hint: 'Erbil, Sulaimani, Duhok...',
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: palette.accent,
                size: 20,
              ),
            ),

            const SizedBox(height: 16),

            _label('Description / وەسف و وردەکاری', palette),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              style: TextStyle(color: palette.textPrimary, fontSize: 13),
              decoration: _inputDecoration(
                palette,
                hint: 'تایبەتمەندی و وەسفی کاڵاکە بنووسە...',
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: palette.buttonGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
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
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Post Listing',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, AppPalette palette) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
        color: palette.textSecondary,
      ),
    ),
  );

  Widget _inputBox({
    required AppPalette palette,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: palette.textPrimary, fontSize: 13),
      decoration: _inputDecoration(palette, hint: hint, prefixIcon: prefixIcon),
    );
  }

  InputDecoration _inputDecoration(
    AppPalette palette, {
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: palette.textSecondary.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
    );
  }
}
