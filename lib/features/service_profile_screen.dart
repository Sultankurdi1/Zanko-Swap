import 'dart:io';
import '../core/data/removed_rows.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/data/auth_permissions.dart';
import '../core/data/external_links.dart';
import '../core/data/supabase_storage_service.dart';
import '../core/localization/app_strings.dart';
import '../core/widgets/report_content.dart';
import '../core/theme/app_theme.dart';

class ServiceProfileScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  const ServiceProfileScreen({super.key, required this.service});
  @override
  State<ServiceProfileScreen> createState() => _ServiceProfileScreenState();
}

class _ServiceProfileScreenState extends State<ServiceProfileScreen> {
  final db = Supabase.instance.client;
  Future<List<Map<String, dynamic>>>? updates;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    updates = db
        .from('service_updates')
        .select()
        .eq('serviceId', widget.service['id'])
        .order('createdAt', ascending: false);
  }

  Future<void> _openLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    final errorMsg = AppStrings.of(context).couldNotOpenMaps;
    final address = '${widget.service['address'] ?? ''}'.trim();
    final lat = double.tryParse('${widget.service['latitude'] ?? ''}');
    final lng = double.tryParse('${widget.service['longitude'] ?? ''}');
    final ok = await ExternalLinks.openMaps(
      address: address,
      latitude: lat,
      longitude: lng,
    );
    if (!ok && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  Future<void> _openWhatsApp() async {
    final messenger = ScaffoldMessenger.of(context);
    final errorMsg = AppStrings.of(context).couldNotOpenWhatsApp;
    final ok = await ExternalLinks.openWhatsApp(
      '${widget.service['phone'] ?? ''}',
    );
    if (!ok && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  Future<void> _deleteService() async {
    final s = AppStrings.of(context);
    final permissions = AuthPermissions(client: db);
    if (!permissions.canManage('${widget.service['ownerId'] ?? ''}')) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          s.isKurdish
              ? 'دەتەوێ شوێنەکە بسڕیتەوە؟'
              : s.isArabic
              ? 'هل تريد حذف المكان؟'
              : 'Delete this place?',
        ),
        content: Text(
          s.isKurdish
              ? 'ئەم کردارە ناگەڕێتەوە.'
              : s.isArabic
              ? 'لا يمكن التراجع عن هذا الإجراء.'
              : 'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await db.from('services').delete().eq('id', widget.service['id']);
      RemovedRows.mark('services', widget.service['id']);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).errorFor(e))),
        );
      }
    }
  }

  Future<void> _addUpdate() async {
    final user = db.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).signIn)));
      }
      return;
    }
    final title = TextEditingController();
    final body = TextEditingController();
    XFile? photo;
    final draft = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            AppStrings.of(dialogCtx).isKurdish
                ? 'زیادکردنی بابەتی نوێ'
                : AppStrings.of(dialogCtx).isArabic
                ? 'إضافة عنصر جديد'
                : 'Add new item',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: InputDecoration(
                    labelText: AppStrings.of(dialogCtx).isKurdish
                        ? 'ناوی بابەت (بۆ نموونە: بریانی)'
                        : AppStrings.of(dialogCtx).isArabic
                        ? 'اسم العنصر (مثال: مشوي)'
                        : 'Item name (e.g. Grilled chicken)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: body,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: AppStrings.of(dialogCtx).isKurdish
                        ? 'وردەکاری'
                        : 'Update / product details',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final p = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 82,
                    );
                    if (p != null) {
                      setDialogState(() => photo = p);
                    }
                  },
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(
                    photo == null
                        ? AppStrings.of(dialogCtx).addPhoto
                        : AppStrings.of(dialogCtx).photoSelected,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(AppStrings.of(dialogCtx).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(AppStrings.of(dialogCtx).add),
            ),
          ],
        ),
      ),
    );
    if (draft != true || title.text.trim().isEmpty) {
      title.dispose();
      body.dispose();
      return;
    }
    try {
      String? imageUrl;
      if (photo != null) {
        imageUrl = await SupabaseStorageService.uploadServiceImage(
          ownerId: user.id,
          file: File(photo!.path),
        );
      }
      await db.from('service_updates').insert({
        'serviceId': widget.service['id'],
        'ownerId': user.id,
        'title': title.text.trim(),
        'body': body.text.trim(),
        'imageUrl': imageUrl,
      });
      if (mounted) {
        setState(_reload);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).errorFor(e))),
        );
      }
    }
    title.dispose();
    body.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);
    final service = widget.service;
    final image = '${service['imageUrl'] ?? ''}';
    final phone = '${service['phone'] ?? ''}'.trim();
    final menu = '${service['menuUrl'] ?? ''}'.trim();
    final type = '${service['type'] ?? ''}'.toLowerCase();
    final permissions = AuthPermissions(client: db);
    final canDelete = permissions.canManage('${service['ownerId'] ?? ''}');
    final typeIcon = type == 'copy'
        ? Icons.content_copy_rounded
        : type == 'restaurant'
        ? Icons.restaurant_rounded
        : Icons.local_cafe_rounded;
    final typeLabel = type == 'copy'
        ? (s.isKurdish
              ? 'پەراوگە / فۆتۆکۆپی'
              : s.isArabic
              ? 'قرطاسية ونسخ'
              : 'Copy / Print')
        : type == 'restaurant'
        ? (s.isKurdish
              ? 'چێشتخانە'
              : s.isArabic
              ? 'مطعم'
              : 'Restaurant')
        : (s.isKurdish
              ? 'کافێ'
              : s.isArabic
              ? 'مقهى'
              : 'Cafe');
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        title: Text(
          '${service['name'] ?? ''}',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: palette.textPrimary,
          ),
        ),
        actions: [
          if (!canDelete)
            IconButton(
              tooltip: s.reportAction,
              icon: Icon(Icons.flag_outlined, color: palette.textPrimary),
              onPressed: () => reportContent(
                context,
                contentType: 'service',
                contentId: '${service['id']}',
              ),
            ),
          if (canDelete)
            IconButton(
              tooltip: s.delete,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _deleteService,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUpdate,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(
          s.isKurdish
              ? 'زیادکردنی بابەت'
              : s.isArabic
              ? 'إضافة عنصر'
              : 'Add item',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: image.isNotEmpty
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: palette.surfaceHighlight,
                            child: Icon(
                              typeIcon,
                              size: 72,
                              color: palette.textSecondary,
                            ),
                          ),
                        )
                      : ColoredBox(
                          color: palette.surfaceHighlight,
                          child: Icon(
                            typeIcon,
                            size: 72,
                            color: palette.textSecondary,
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: palette.bg.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 14, color: palette.accent),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${service['name'] ?? ''}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: palette.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${service['address'] ?? ''}',
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _openLocation,
                icon: const Icon(Icons.map_rounded),
                label: Text(
                  s.isKurdish
                      ? 'نەخشە'
                      : s.isArabic
                      ? 'خرائط Google'
                      : 'Google Maps',
                ),
              ),
              if (phone.isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: _openWhatsApp,
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('WhatsApp'),
                ),
              if (menu.isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final errorMsg = AppStrings.of(context).couldNotOpenLink;
                    final ok = await ExternalLinks.openWebUrl(menu);
                    if (!ok && mounted) {
                      messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
                    }
                  },
                  icon: const Icon(Icons.restaurant_menu_rounded),
                  label: Text(
                    s.isKurdish
                        ? 'مێنیو'
                        : s.isArabic
                        ? 'القائمة'
                        : 'Menu',
                  ),
                ),
            ],
          ),
          if ('${service['offer'] ?? ''}'.trim().isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer_rounded,
                    size: 16,
                    color: palette.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${s.studentDiscount}: ${service['offer']}',
                      style: TextStyle(
                        color: palette.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if ('${service['copyPrice'] ?? ''}'.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${s.isKurdish
                    ? 'نرخی کۆپی'
                    : s.isArabic
                    ? 'سعر النسخة للصفحة'
                    : 'Copy price per page'}: ${service['copyPrice']}',
              ),
            ),
          const SizedBox(height: 22),
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                s.isKurdish ? 'بابەتەکان و نوێکردنەوەکان' : 'Items and updates',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: updates,
            builder: (context, snap) {
              if (snap.hasError) {
                return Text('Error: ${snap.error}');
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final rows = snap.data ?? const <Map<String, dynamic>>[];
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Colors.grey.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.isKurdish
                            ? 'هێشتا هیچ بابەتێک زیاد نەکراوە.'
                            : s.isArabic
                            ? 'لا توجد عناصر بعد.'
                            : 'No items added yet.',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final r = rows[i];
                  final imgUrl = '${r['imageUrl'] ?? ''}';
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: imgUrl.isNotEmpty
                                ? Image.network(
                                    imgUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 32,
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.image_outlined, size: 32),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r['title'] ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              if ('${r['body'] ?? ''}'.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${r['body']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
