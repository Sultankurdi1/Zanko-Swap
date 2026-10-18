import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/data/supabase_storage_service.dart';
import '../../../core/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final phone = TextEditingController();
  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  final picker = ImagePicker();
  XFile? pickedPhoto;
  String? existingPhotoUrl;
  bool saving = false;
  bool changingPassword = false;
  late String name;
  late String email;

  @override
  void initState() {
    super.initState();
    final u = Supabase.instance.client.auth.currentUser;
    final metadata = u?.userMetadata ?? const <String, dynamic>{};
    name =
        (metadata['displayName'] ??
                metadata['display_name'] ??
                metadata['full_name'] ??
                metadata['name'] ??
                '')
            .toString()
            .trim();
    email = u?.email ?? '';
    existingPhotoUrl = u?.userMetadata?['photoUrl']?.toString();
    _load();
  }

  Future<void> _load() async {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return;
    try {
      final r = await Supabase.instance.client
          .from('profiles')
          .select('phone, displayName, photoUrl')
          .eq('id', u.id)
          .maybeSingle();
      if (mounted) {
        phone.text = '${r?['phone'] ?? ''}';
        final profileName = r?['displayName']?.toString().trim();
        final profilePhoto = r?['photoUrl']?.toString();
        setState(() {
          if (name.trim().isEmpty &&
              profileName != null &&
              profileName.isNotEmpty) {
            name = profileName;
          }
          if ((existingPhotoUrl == null || existingPhotoUrl!.isEmpty) &&
              profilePhoto != null &&
              profilePhoto.isNotEmpty) {
            existingPhotoUrl = profilePhoto;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    phone.dispose();
    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    final s = AppStrings.of(context);
    final r = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (r == null) return;
    final ext = r.path.toLowerCase().split('.').last;
    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      _msg(
        s.isKurdish
            ? 'تەنها وێنەی JPG، JPEG یان PNG ڕێگەپێدراوە.'
            : 'Only JPG, JPEG, or PNG profile photos are allowed.',
      );
      return;
    }
    final size = await File(r.path).length();
    if (size > 2 * 1024 * 1024) {
      _msg(
        s.isKurdish
            ? 'قەبارەی وێنەکە نابێت لە ٢ مێگابایت زیاتر بێت.'
            : 'Profile photo must be 2 MB or smaller.',
      );
      return;
    }
    setState(() => pickedPhoto = r);
  }

  Future<void> save() async {
    final s = AppStrings.of(context);
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return;
    if (newPassword.text.isNotEmpty || confirmPassword.text.isNotEmpty) {
      if (newPassword.text != confirmPassword.text) {
        _msg(
          s.isKurdish
              ? 'وشەی نهێنی نوێ یەکسان نییە'
              : 'New passwords do not match',
        );
        return;
      }
      if (newPassword.text.length < 6) {
        _msg(
          s.isKurdish
              ? 'وشەی نهێنی لانیکەم ٦ پیت'
              : 'Password must be at least 6 characters',
        );
        return;
      }
    }
    setState(() => saving = true);
    try {
      String? photoUrl = existingPhotoUrl;
      if (pickedPhoto != null) {
        photoUrl = await SupabaseStorageService.uploadProfileImage(
          userId: u.id,
          file: File(pickedPhoto!.path),
        );
      }
      final meta = {
        ...u.userMetadata ?? {},
        'displayName': name,
        'photoUrl': photoUrl,
      };
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: meta,
          password: newPassword.text.isNotEmpty ? newPassword.text : null,
        ),
      );
      await Supabase.instance.client.from('profiles').upsert({
        'id': u.id,
        'email': u.email ?? '',
        'displayName': name,
        'phone': phone.text.trim(),
        'photoUrl': photoUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      _msg(s.profileUpdated);
      Navigator.pop(context, true);
    } on AuthException catch (e) {
      _msg(e.message);
    } catch (e) {
      _msg(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _msg(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  InputDecoration _inputDecor(
    AppPalette palette, {
    required String labelText,
    required Widget prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: palette.textSecondary, fontSize: 13),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);

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
          s.editProfile,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: palette.accent,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: palette.surfaceHighlight,
                  backgroundImage: pickedPhoto != null
                      ? FileImage(File(pickedPhoto!.path))
                      : ((existingPhotoUrl?.isNotEmpty ?? false)
                                ? NetworkImage(existingPhotoUrl!)
                                : null)
                            as ImageProvider?,
                  child:
                      pickedPhoto == null &&
                          (existingPhotoUrl == null ||
                              existingPhotoUrl!.isEmpty)
                      ? Icon(
                          Icons.person_rounded,
                          size: 46,
                          color: palette.textSecondary,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: pickPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: palette.buttonGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: palette.primary.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            readOnly: true,
            style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
            controller: TextEditingController(text: name),
            decoration: _inputDecor(
              palette,
              labelText: s.fullName,
              prefixIcon: Icon(Icons.person_outline, color: palette.accent),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            readOnly: true,
            style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
            controller: TextEditingController(text: email),
            decoration: _inputDecor(
              palette,
              labelText: s.email,
              prefixIcon: Icon(Icons.email_outlined, color: palette.accent),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
            decoration: _inputDecor(
              palette,
              labelText: s.phone,
              prefixIcon: Icon(Icons.phone_outlined, color: palette.accent),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            s.isKurdish
                ? 'گۆڕینی وشەی نهێنی'
                : s.isArabic
                ? 'تغيير كلمة المرور'
                : 'Change password',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: newPassword,
            obscureText: true,
            style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
            decoration: _inputDecor(
              palette,
              labelText: s.isKurdish
                  ? 'وشەی نهێنی نوێ'
                  : s.isArabic
                  ? 'كلمة مرور جديدة'
                  : 'New password',
              prefixIcon: Icon(Icons.lock_reset_rounded, color: palette.accent),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: confirmPassword,
            obscureText: true,
            style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
            decoration: _inputDecor(
              palette,
              labelText: s.isKurdish
                  ? 'دووبارەکردنەوەی وشەی نهێنی'
                  : 'Confirm new password',
              prefixIcon: Icon(Icons.lock_reset_rounded, color: palette.accent),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            height: 50,
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
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: saving ? null : save,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 19),
              label: Text(
                s.saveChanges,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
