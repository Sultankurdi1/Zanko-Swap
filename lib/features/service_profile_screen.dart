import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/data/auth_permissions.dart';
import '../core/data/external_links.dart';
import '../core/data/supabase_storage_service.dart';
import '../core/localization/app_strings.dart';

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
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
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
                ? 'نوێکردنەوەی ڕۆژانە'
                : 'Daily update',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: InputDecoration(
                    labelText: AppStrings.of(dialogCtx).isKurdish
                        ? 'سەردێڕ'
                        : 'Title',
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    title.dispose();
    body.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final service = widget.service;
    final image = '${service['imageUrl'] ?? ''}';
    final phone = '${service['phone'] ?? ''}'.trim();
    final menu = '${service['menuUrl'] ?? ''}'.trim();
    final permissions = AuthPermissions(client: db);
    final canDelete = permissions.canManage('${service['ownerId'] ?? ''}');
    return Scaffold(
      appBar: AppBar(
        title: Text('${service['name'] ?? ''}'),
        actions: [
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
              ? 'نوێکردنەوە'
              : s.isArabic
              ? 'تحديث يومي'
              : 'Daily update',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 190,
              child: image.isNotEmpty
                  ? Image.network(image, fit: BoxFit.cover)
                  : ColoredBox(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.storefront_rounded, size: 72),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${service['name'] ?? ''}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text('${service['type'] ?? ''} • ${service['address'] ?? ''}'),
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
                    final ok = await launchUrl(
                      Uri.parse(menu),
                      mode: LaunchMode.externalApplication,
                    );
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
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${s.studentDiscount}: ${service['offer']}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
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
          Text(
            s.isKurdish
                ? 'نوێترین نوێکردنەوەکان'
                : 'Daily updates and products',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: updates,
            builder: (context, snap) {
              if (snap.hasError) {
                return Text('Error: ${snap.error}');
              }
              final rows = snap.data ?? const <Map<String, dynamic>>[];
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    s.isKurdish
                        ? 'هێشتا نوێکردنەوە نییە.'
                        : s.isArabic
                        ? 'لا توجد تحديثات بعد.'
                        : 'No updates yet.',
                  ),
                );
              }
              return Column(
                children: rows
                    .map(
                      (r) => Card(
                        child: ListTile(
                          leading: r['imageUrl'] == null
                              ? const Icon(Icons.update_rounded)
                              : Image.network(
                                  '${r['imageUrl']}',
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                          title: Text(
                            '${r['title'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text('${r['body'] ?? ''}'),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
