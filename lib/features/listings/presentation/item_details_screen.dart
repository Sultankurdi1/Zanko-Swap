import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/auth_permissions.dart';
import '../../../core/data/favorites_store.dart';
import '../../../core/data/supabase_storage_service.dart';
import '../data/listing_repository.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../../core/localization/app_strings.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Listing listing;
  const ItemDetailsScreen({super.key, required this.listing});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  late Listing _currentListing;
  int _activeImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentListing = widget.listing;
  }

  String _formatCategory(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return 'Medical Equipment';
      case 'postgraduate':
        return 'Postgraduate Books';
      case 'device':
        return 'Electronics & Devices';
      case 'study_material':
      case 'handout':
        return 'Study Materials';
      case 'book':
      default:
        return 'Academic Books';
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = 'https://wa.me/$cleanPhone';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ناتوانرێت پەیوەندی بە وەتسئەپەوە بکرێت'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final isMyListing = myId != null && myId == _currentListing.sellerId;

    final price = _currentListing.transactionType == 'free'
        ? (s.isKurdish
              ? 'بەخۆڕایی'
              : s.isArabic
              ? 'مجاناً'
              : 'Free')
        : _currentListing.transactionType == 'exchange'
        ? (s.isKurdish
              ? 'ئاڵوگۆڕ'
              : s.isArabic
              ? 'مبادلة'
              : 'Exchange')
        : '${_currentListing.priceIQD} IQD';

    final canManage = AuthPermissions().canManage(_currentListing.sellerId);
    final locationText = _currentListing.universityName.isNotEmpty
        ? _currentListing.universityName
        : 'Erbil';

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 380,
                        width: double.infinity,
                        color: palette.surfaceHighlight,
                        child: _currentListing.images.isNotEmpty
                            ? PageView.builder(
                                itemCount: _currentListing.images.length,
                                onPageChanged: (i) =>
                                    setState(() => _activeImageIndex = i),
                                itemBuilder: (_, i) => Image.network(
                                  _currentListing.images[i],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 48,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 70,
                                  color: palette.textSecondary,
                                ),
                              ),
                      ),
                      if (_currentListing.images.length > 1)
                        Positioned(
                          bottom: 14,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _currentListing.images.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: _activeImageIndex == index ? 14 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _activeImageIndex == index
                                      ? palette.primary
                                      : Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 14,
                        right: 14,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: palette.surface.withValues(
                                alpha: 0.85,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color: palette.textPrimary,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const Spacer(),
                            if (canManage) ...[
                              CircleAvatar(
                                backgroundColor: palette.surface.withValues(
                                  alpha: 0.85,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: palette.textPrimary,
                                  ),
                                  onPressed: () =>
                                      _openEditDialog(context, palette),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: palette.surface.withValues(
                                  alpha: 0.85,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, palette),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            CircleAvatar(
                              backgroundColor: palette.surface.withValues(
                                alpha: 0.85,
                              ),
                              child: AnimatedBuilder(
                                animation: FavoritesStore.instance,
                                builder: (context, _) {
                                  final isSaved = FavoritesStore.instance
                                      .containsListing(_currentListing.id);
                                  return IconButton(
                                    onPressed: () => FavoritesStore.instance
                                        .toggleListing(_currentListing.id),
                                    icon: Icon(
                                      isSaved
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: isSaved
                                          ? const Color(0xFFF87171)
                                          : palette.textPrimary,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: palette.surface.withValues(
                                alpha: 0.85,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.share_outlined,
                                  color: palette.textPrimary,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('بەستەری بابەت کۆپی کرا'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentListing.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: palette.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: palette.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              locationText,
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Icon(
                              Icons.book_outlined,
                              size: 16,
                              color: palette.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatCategory(_currentListing.type),
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: palette.border),
                        const SizedBox(height: 16),
                        Text(
                          _currentListing.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: palette.textPrimary.withValues(alpha: 0.9),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Seller Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: palette.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: palette.primary.withValues(
                                  alpha: 0.15,
                                ),
                                child: Text(
                                  _currentListing.sellerName.isNotEmpty
                                      ? _currentListing.sellerName[0]
                                            .toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    color: palette.accent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _currentListing.sellerName.isNotEmpty
                                              ? _currentListing.sellerName
                                              : 'Zanko Student',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: palette.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: palette.accent,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Student • $locationText',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '4.9',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  color: palette.surface,
                  border: Border(top: BorderSide(color: palette.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: palette.isDark ? 0.35 : 0.08,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        onPressed: () => _openWhatsApp('9647500000000'),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF25D366),
                          size: 22,
                        ),
                        tooltip: 'WhatsApp',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isMyListing
                          ? Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: palette.surfaceHighlight,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: palette.border),
                              ),
                              child: Center(
                                child: Text(
                                  s.isKurdish
                                      ? 'ئەم بابەتە هی خۆتە'
                                      : 'Your Listing',
                                  style: TextStyle(
                                    color: palette.textSecondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: palette.buttonGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      listingId:
                                          int.tryParse(
                                            _currentListing.id.toString(),
                                          ) ??
                                          0,
                                      listingTitle: _currentListing.title,
                                      listingImage:
                                          _currentListing.images.isNotEmpty
                                          ? _currentListing.images.first
                                          : '',
                                      listingPrice: price,
                                      otherUserId: _currentListing.sellerId,
                                      otherUserName: _currentListing.sellerName,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.send_rounded, size: 18),
                                label: const Text(
                                  'Send Message',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, AppPalette palette) async {
    final titleController = TextEditingController(text: _currentListing.title);
    final priceController = TextEditingController(
      text: '${_currentListing.priceIQD}',
    );
    final descController = TextEditingController(
      text: _currentListing.description,
    );
    File? newImageFile;
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'دەستکاریکردنی بابەت',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.textSecondary,
                      ),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  style: TextStyle(color: palette.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'ناوی بابەت / Title',
                    labelStyle: TextStyle(color: palette.textSecondary),
                    filled: true,
                    fillColor: palette.surfaceHighlight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: palette.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'نرخ (IQD) / Price',
                    labelStyle: TextStyle(color: palette.textSecondary),
                    filled: true,
                    fillColor: palette.surfaceHighlight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: TextStyle(color: palette.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'ڕوونکردنەوە / Description',
                    labelStyle: TextStyle(color: palette.textSecondary),
                    filled: true,
                    fillColor: palette.surfaceHighlight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.accent,
                    side: BorderSide(
                      color: palette.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setModalState(() {
                        newImageFile = File(picked.path);
                      });
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    newImageFile != null
                        ? 'وێنە هەڵبژێردرا'
                        : 'گۆڕینی وێنە / Change Image',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newTitle = titleController.text.trim();
                          final newPrice =
                              int.tryParse(priceController.text.trim()) ??
                              _currentListing.priceIQD;
                          final newDesc = descController.text.trim();

                          if (newTitle.isEmpty) return;

                          setModalState(() => isSaving = true);

                          try {
                            List<String> updatedImages = List.from(
                              _currentListing.images,
                            );
                            if (newImageFile != null) {
                              final uploadedUrl =
                                  await SupabaseStorageService.uploadListingImage(
                                    ownerId: _currentListing.sellerId,
                                    file: newImageFile!,
                                    fileName:
                                        '${DateTime.now().millisecondsSinceEpoch}.jpg',
                                  );
                              updatedImages = [uploadedUrl];
                            }
                            final res = await Supabase.instance.client
                                .from('listings')
                                .update({
                                  'title': newTitle,
                                  'priceIQD': newPrice,
                                  'description': newDesc,
                                  'images': updatedImages,
                                })
                                .eq('id', _currentListing.id)
                                .select()
                                .single();

                            if (!mounted) return;
                            setState(() {
                              _currentListing = Listing.fromMap(res);
                            });
                            if (!bottomSheetContext.mounted) return;
                            Navigator.pop(bottomSheetContext);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'بابەتەکە بە سەرکەوتوویی نوێکرایەوە',
                                ),
                              ),
                            );
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(
                              this.context,
                            ).showSnackBar(SnackBar(content: Text('هەڵە: $e')));
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('پاشەکەوتکردن / Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppPalette palette) async {
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          s.deleteQuestion,
          style: TextStyle(color: palette.textPrimary),
        ),
        content: Text(
          s.cannotUndo,
          style: TextStyle(color: palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              s.cancel,
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF87171),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ListingRepository().deleteListing(
        _currentListing.id,
        _currentListing.sellerId,
      );
      if (!mounted) return;
      Navigator.of(this.context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
