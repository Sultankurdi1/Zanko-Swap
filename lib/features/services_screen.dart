import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/data/auth_permissions.dart';
import '../core/data/external_links.dart';
import '../core/data/supabase_storage_service.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';

class ServicesScreen extends StatefulWidget {
  final String initialCategory;
  const ServicesScreen({super.key, this.initialCategory = 'all'});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final db = Supabase.instance.client;
  final search = TextEditingController();
  late String category;
  String query = '';
  bool get isDedicated => category != 'all';

  String _getHeaderImageUrl(String cat) {
    switch (cat) {
      case 'copy':
        return 'https://images.unsplash.com/photo-1588072432836-e10032774350?auto=format&fit=crop&w=1200&q=80';
      case 'restaurant':
        return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80';
      case 'cafe':
        return 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=1200&q=80';
      default:
        return 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=80';
    }
  }

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _addService(AppPalette palette) async {
    final user = db.auth.currentUser;
    if (user == null) {
      _showMessage(AppStrings.of(context).signIn);
      return;
    }
    final draft = await showDialog<_ServiceDraft>(
      context: context,
      builder: (_) => _AddServiceDialog(
        palette: palette,
        initialType: isDedicated ? category : 'copy',
        lockType: isDedicated,
      ),
    );
    if (draft == null) return;
    try {
      String? imageUrl;
      if (draft.image != null) {
        imageUrl = await SupabaseStorageService.uploadServiceImage(
          ownerId: user.id,
          file: File(draft.image!.path),
        );
      }

      final parsedCopyPrice = draft.type == 'copy' && draft.copyPrice.isNotEmpty
          ? int.tryParse(draft.copyPrice.replaceAll(RegExp(r'[^0-9]'), ''))
          : null;

      final insertedPlace = await db
          .from('services')
          .insert({
            'ownerId': user.id,
            'name': draft.name,
            'type': draft.type,
            'address': draft.address,
            'offer': draft.offer.isEmpty ? null : draft.offer,
            'phone': draft.phone.isEmpty ? null : draft.phone,
            'menuUrl': draft.menuUrl.isEmpty ? null : draft.menuUrl,
            'copyPrice': parsedCopyPrice,
            'latitude': draft.latitude,
            'longitude': draft.longitude,
            'imageUrl': imageUrl,
            'active': true,
          })
          .select('id')
          .single();
      try {
        await db.functions.invoke(
          'send-new-place-notification',
          body: {'serviceId': insertedPlace['id'].toString()},
        );
      } catch (_) {}
      if (mounted) _showMessage(AppStrings.of(context).placeAdded);
    } catch (e) {
      _showMessage('$e');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteService(
    Map<String, dynamic> row,
    AppPalette palette,
  ) async {
    final s = AppStrings.of(context);
    final permissions = AuthPermissions(client: db);
    if (!permissions.canManage('${row['ownerId'] ?? ''}')) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.isArabic
              ? 'حذف المكان؟'
              : s.isKurdish
              ? 'شوێنەکە بسڕیتەوە؟'
              : 'Delete this place?',
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          s.isArabic
              ? 'هل تريد حذف هذا المكان؟'
              : s.isKurdish
              ? 'دەتەوێ ئەم شوێنە بسڕیتەوە؟'
              : 'Do you want to delete this place?',
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
            child: Text(
              s.delete,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await db.from('services').delete().eq('id', row['id']);
      if (mounted) setState(() {});
    } catch (e) {
      _showMessage('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);

    final title = isDedicated
        ? (category == 'restaurant'
              ? s.restaurants
              : category == 'cafe'
              ? s.cafes
              : s.stationery)
        : s.nearbyServices;

    final searchHint = isDedicated
        ? (category == 'restaurant'
              ? (s.isKurdish
                    ? 'گەڕان بۆ چێشتخانە...'
                    : s.isArabic
                    ? 'ابحث عن مطاعم...'
                    : s.restaurants)
              : category == 'cafe'
              ? (s.isKurdish
                    ? 'گەڕان بۆ کافێ...'
                    : s.isArabic
                    ? 'ابحث عن مقاهٍ...'
                    : s.cafes)
              : (s.isKurdish
                    ? 'گەڕان بۆ پەراوگە و فۆتۆکۆپی...'
                    : s.isArabic
                    ? 'ابحث عن قرطاسية ومراكز نسخ...'
                    : s.stationery))
        : s.search;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: palette.accent,
            letterSpacing: -0.5,
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: palette.buttonGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          onPressed: () => _addService(palette),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            s.addPlace,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 110,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    image: DecorationImage(
                      image: NetworkImage(_getHeaderImageUrl(category)),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          palette.bg.withValues(alpha: 0.9),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    alignment: Alignment.bottomRight,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.border),
                  ),
                  child: TextField(
                    controller: search,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 13.5,
                    ),
                    onChanged: (val) {
                      setState(() {
                        query = val.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: TextStyle(
                        color: palette.textSecondary.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: palette.accent,
                        size: 20,
                      ),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                search.clear();
                                setState(() => query = '');
                              },
                              icon: Icon(
                                Icons.clear_rounded,
                                color: palette.textSecondary,
                              ),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                if (!isDedicated) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(s.all, 'all', palette),
                        _filterChip(s.copyShops, 'copy', palette),
                        _filterChip(s.restaurants, 'restaurant', palette),
                        _filterChip(s.cafes, 'cafe', palette),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: db
                  .from('services')
                  .stream(primaryKey: ['id'])
                  .eq('active', true)
                  .order('createdAt', ascending: false),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _ServiceSkeleton(palette: palette);
                }
                if (snap.hasError) {
                  return _ErrorRetry(
                    palette: palette,
                    message: '${snap.error}',
                    onRetry: () => setState(() {}),
                  );
                }

                final rows = (snap.data ?? const <Map<String, dynamic>>[])
                    .where((row) {
                      final type = (row['type'] ?? '').toString().toLowerCase();
                      final typeMatch =
                          category == 'all' ||
                          type == category ||
                          type.contains(category);

                      if (!typeMatch) return false;
                      if (query.isEmpty) return true;

                      final name = (row['name'] ?? '').toString().toLowerCase();
                      final address = (row['address'] ?? '')
                          .toString()
                          .toLowerCase();
                      final offer = (row['offer'] ?? '')
                          .toString()
                          .toLowerCase();

                      return name.contains(query) ||
                          address.contains(query) ||
                          offer.contains(query);
                    })
                    .toList();

                if (rows.isEmpty) {
                  return _EmptyState(label: s.noPlaces, palette: palette);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  itemCount: rows.length,
                  itemBuilder: (context, index) =>
                      _serviceCard(context, rows[index], palette),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, AppPalette palette) {
    final selected = category == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: palette.primary,
        backgroundColor: palette.surface,
        labelStyle: TextStyle(
          color: selected ? Colors.white : palette.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        side: BorderSide(color: selected ? palette.primary : palette.border),
        onSelected: (_) => setState(() => category = value),
      ),
    );
  }

  Widget _serviceCard(
    BuildContext context,
    Map<String, dynamic> row,
    AppPalette palette,
  ) {
    final s = AppStrings.of(context);
    final imageUrl = '${row['imageUrl'] ?? ''}';
    final owner = '${row['ownerId'] ?? ''}';
    final permissions = AuthPermissions(client: db);
    final phone = '${row['phone'] ?? ''}'.trim();
    final address = '${row['address'] ?? ''}'.trim();
    final lat = double.tryParse('${row['latitude'] ?? ''}');
    final lng = double.tryParse('${row['longitude'] ?? ''}');
    final menuUrl = '${row['menuUrl'] ?? ''}'.trim();
    final copyPrice = '${row['copyPrice'] ?? ''}'.trim();
    final type = '${row['type'] ?? ''}'.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: palette.surfaceHighlight,
                          child: Icon(
                            Icons.storefront_rounded,
                            color: palette.textSecondary,
                          ),
                        ),
                      )
                    : Container(
                        color: palette.surfaceHighlight,
                        child: Icon(
                          Icons.storefront_rounded,
                          color: palette.textSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${row['name'] ?? ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (address.isNotEmpty)
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  if ('${row['offer'] ?? ''}'.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${row['offer']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (type == 'copy' && copyPrice.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${s.isKurdish
                            ? 'نرخی کۆپی'
                            : s.isArabic
                            ? 'سعر النسخ'
                            : 'Copy price'}: $copyPrice',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _action(
                        palette: palette,
                        icon: Icons.map_rounded,
                        label: s.isKurdish
                            ? 'نەخشە'
                            : s.isArabic
                            ? 'الخرائط'
                            : 'Maps',
                        onTap: () async {
                          final ok = await ExternalLinks.openMaps(
                            address: address,
                            latitude: lat,
                            longitude: lng,
                          );
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppStrings.of(context).couldNotOpenMaps,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      if (phone.isNotEmpty)
                        _action(
                          palette: palette,
                          icon: Icons.chat_rounded,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () async {
                            final ok = await ExternalLinks.openWhatsApp(phone);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.of(context).couldNotOpenWhatsApp,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      if (menuUrl.isNotEmpty)
                        _action(
                          palette: palette,
                          icon: Icons.restaurant_menu_rounded,
                          label: s.isKurdish
                              ? 'مێنیو'
                              : s.isArabic
                              ? 'القائمة'
                              : 'Menu',
                          onTap: () async {
                            final ok = await launchUrl(
                              Uri.parse(menuUrl),
                              mode: LaunchMode.externalApplication,
                            );
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.of(context).couldNotOpenLink,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      if (permissions.canManage(owner))
                        IconButton(
                          tooltip: s.delete,
                          onPressed: () => _deleteService(row, palette),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFF87171),
                            size: 20,
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
    );
  }

  Widget _action({
    required AppPalette palette,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? palette.primary).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? palette.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color ?? palette.accent,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ServiceDraft {
  final String name, type, address, offer, phone, menuUrl, copyPrice;
  final double? latitude, longitude;
  final XFile? image;
  const _ServiceDraft({
    required this.name,
    required this.type,
    required this.address,
    required this.offer,
    required this.phone,
    required this.menuUrl,
    required this.copyPrice,
    this.latitude,
    this.longitude,
    this.image,
  });
}

class _AddServiceDialog extends StatefulWidget {
  final AppPalette palette;
  final String initialType;
  final bool lockType;
  const _AddServiceDialog({
    required this.palette,
    required this.initialType,
    required this.lockType,
  });
  @override
  State<_AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<_AddServiceDialog> {
  final name = TextEditingController();
  final address = TextEditingController();
  final offer = TextEditingController();
  final phone = TextEditingController();
  final menuUrl = TextEditingController();
  final copyPrice = TextEditingController();
  final locationLink = TextEditingController();
  late String type;
  XFile? image;

  @override
  void initState() {
    super.initState();
    type = widget.initialType;
  }

  @override
  void dispose() {
    for (final c in [
      name,
      address,
      offer,
      phone,
      menuUrl,
      copyPrice,
      locationLink,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  (double?, double?) _extractCoords(String link) {
    if (link.isEmpty) return (null, null);
    try {
      final reg = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
      final match = reg.firstMatch(link);
      if (match != null) {
        return (
          double.tryParse(match.group(1)!),
          double.tryParse(match.group(2)!),
        );
      }
      final qReg = RegExp(r'q=(-?\d+\.\d+),(-?\d+\.\d+)');
      final qMatch = qReg.firstMatch(link);
      if (qMatch != null) {
        return (
          double.tryParse(qMatch.group(1)!),
          double.tryParse(qMatch.group(2)!),
        );
      }
    } catch (_) {}
    return (null, null);
  }

  InputDecoration _dialogInputDecor(
    String label, {
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      labelStyle: TextStyle(color: widget.palette.textSecondary, fontSize: 13),
      hintStyle: TextStyle(
        color: widget.palette.textSecondary.withValues(alpha: 0.6),
        fontSize: 12,
      ),
      filled: true,
      fillColor: widget.palette.surfaceHighlight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.palette.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isCopyShop = type == 'copy';

    return AlertDialog(
      backgroundColor: widget.palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        s.addPlace,
        style: TextStyle(
          color: widget.palette.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                style: TextStyle(
                  color: widget.palette.textPrimary,
                  fontSize: 13,
                ),
                decoration: _dialogInputDecor(s.placeName),
              ),
              const SizedBox(height: 10),
              if (!widget.lockType) ...[
                DropdownButtonFormField<String>(
                  initialValue: type,
                  dropdownColor: widget.palette.surface,
                  style: TextStyle(
                    color: widget.palette.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: _dialogInputDecor(s.type),
                  items: [
                    DropdownMenuItem(value: 'copy', child: Text(s.copyShops)),
                    DropdownMenuItem(
                      value: 'restaurant',
                      child: Text(s.restaurants),
                    ),
                    DropdownMenuItem(value: 'cafe', child: Text(s.cafes)),
                  ],
                  onChanged: (v) => setState(() => type = v ?? type),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: address,
                style: TextStyle(
                  color: widget.palette.textPrimary,
                  fontSize: 13,
                ),
                decoration: _dialogInputDecor(
                  s.address,
                  hint: s.isKurdish
                      ? 'گەڕەک، شەقام، نزیک زانکۆ...'
                      : s.isArabic
                      ? 'الحي، الشارع، قرب الجامعة...'
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  color: widget.palette.textPrimary,
                  fontSize: 13,
                ),
                decoration: _dialogInputDecor(s.phone),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: offer,
                style: TextStyle(
                  color: widget.palette.textPrimary,
                  fontSize: 13,
                ),
                decoration: _dialogInputDecor(s.studentDiscount),
              ),
              const SizedBox(height: 10),
              if (isCopyShop) ...[
                TextField(
                  controller: copyPrice,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: widget.palette.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: _dialogInputDecor(
                    s.isKurdish
                        ? 'نرخی کۆپی بۆ هەر پەڕە (ژمارە)'
                        : 'Copy price per page',
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (!isCopyShop) ...[
                TextField(
                  controller: menuUrl,
                  style: TextStyle(
                    color: widget.palette.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: _dialogInputDecor(
                    s.isKurdish
                        ? 'بەستەری مێنیو'
                        : s.isArabic
                        ? 'رابط القائمة'
                        : 'Menu link',
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: locationLink,
                style: TextStyle(
                  color: widget.palette.textPrimary,
                  fontSize: 13,
                ),
                decoration: _dialogInputDecor(
                  s.isKurdish
                      ? 'بەستەری لۆکەیشن (Google Maps)'
                      : s.isArabic
                      ? 'رابط الموقع (خرائط Google)'
                      : 'Maps Link',
                  hint: 'https://maps.app.goo.gl/...',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: widget.palette.accent,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(image!.path),
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.palette.accent,
                  side: BorderSide(
                    color: widget.palette.accent.withValues(alpha: 0.3),
                  ),
                ),
                onPressed: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (picked != null && mounted) setState(() => image = picked);
                },
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(image == null ? s.addPhoto : s.photoSelected),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            s.cancel,
            style: TextStyle(color: widget.palette.textSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: widget.palette.primary,
          ),
          onPressed: () {
            if (name.text.trim().isEmpty || address.text.trim().isEmpty) return;
            final coords = _extractCoords(locationLink.text.trim());
            Navigator.pop(
              context,
              _ServiceDraft(
                name: name.text.trim(),
                type: type,
                address: address.text.trim(),
                offer: offer.text.trim(),
                phone: phone.text.trim(),
                menuUrl: isCopyShop ? '' : menuUrl.text.trim(),
                copyPrice: isCopyShop ? copyPrice.text.trim() : '',
                latitude: coords.$1,
                longitude: coords.$2,
                image: image,
              ),
            );
          },
          child: Text(
            s.add,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _ServiceSkeleton extends StatelessWidget {
  final AppPalette palette;
  const _ServiceSkeleton({required this.palette});

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 6,
    itemBuilder: (_, __) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 112,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String label;
  final AppPalette palette;
  const _EmptyState({required this.label, required this.palette});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70),
    child: Column(
      children: [
        Icon(
          Icons.store_mall_directory_outlined,
          size: 64,
          color: palette.textSecondary.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textSecondary),
        ),
      ],
    ),
  );
}

class _ErrorRetry extends StatelessWidget {
  final AppPalette palette;
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({
    required this.palette,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: palette.primary),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
