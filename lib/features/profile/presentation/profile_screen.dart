import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/sign_in_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const ProfileScreen({super.key, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (context, snapshot) => _ProfileBody(
      user:
          snapshot.data?.session?.user ??
          Supabase.instance.client.auth.currentUser,
      onOpenSettings: onOpenSettings,
    ),
  );
}

class _ProfileBody extends StatelessWidget {
  final User? user;
  final VoidCallback onOpenSettings;
  const _ProfileBody({required this.user, required this.onOpenSettings});

  Future<String> _displayName(AppStrings s) async {
    final metadata = user!.userMetadata ?? const <String, dynamic>{};
    for (final key in ['displayName', 'display_name', 'full_name', 'name']) {
      final metadataName = metadata[key]?.toString().trim();
      if (metadataName != null && metadataName.isNotEmpty) return metadataName;
    }
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('displayName')
          .eq('id', user!.id)
          .maybeSingle();
      final profileName = profile?['displayName']?.toString().trim();
      if (profileName != null && profileName.isNotEmpty) return profileName;
    } catch (_) {}
    return s.student;
  }

  Future<int> _countListings({String? status}) async {
    if (user == null) return 0;
    var q = Supabase.instance.client
        .from('listings')
        .select('id')
        .eq('sellerId', user!.id);
    if (status != null) q = q.eq('status', status);
    final rows = await q;
    return rows.length;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);

    if (user == null) {
      return Scaffold(
        backgroundColor: palette.bg,
        appBar: AppBar(
          backgroundColor: palette.bg,
          elevation: 0,
          title: Text(
            s.profile,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 84,
                  color: palette.textSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  s.signIn,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.isKurdish
                      ? 'بۆ بینینی پرۆفایل و بابەتەکانت بچۆ ژوورەوە.'
                      : 'Sign in to see your profile and listings.',
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(
                    s.signIn,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        title: Text(
          s.profile,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: palette.accent,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: onOpenSettings,
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: palette.surfaceHighlight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: palette.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: palette.headerGradient ?? palette.buttonGradient,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: palette.isDark ? 0.25 : 0.08,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 2),
                      image:
                          (user!.userMetadata?['photoUrl']
                                  ?.toString()
                                  .isNotEmpty ==
                              true)
                          ? DecorationImage(
                              image: NetworkImage(
                                user!.userMetadata?['photoUrl']?.toString() ??
                                    '',
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child:
                        (user!.userMetadata?['photoUrl']
                                ?.toString()
                                .isNotEmpty !=
                            true)
                        ? const Icon(
                            Icons.person_rounded,
                            size: 38,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: _displayName(s),
                          builder: (context, nameSnapshot) => Text(
                            nameSnapshot.data ?? s.student,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user!.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  s.editProfile,
                                  style: const TextStyle(
                                    color: Colors.white,
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
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: FutureBuilder<int>(
                      future: _countListings(status: 'active'),
                      builder: (context, snap) => _EmeraldStat(
                        palette: palette,
                        title: s.isKurdish
                            ? 'بابەتە چالاکەکان'
                            : 'Active listings',
                        value: '${snap.data ?? 0}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FutureBuilder<int>(
                      future: _countListings(status: 'sold'),
                      builder: (context, snap) => _EmeraldStat(
                        palette: palette,
                        title: s.sold,
                        value: '${snap.data ?? 0}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _EmeraldMenuCard(
                  palette: palette,
                  icon: Icons.menu_book_rounded,
                  title: s.isKurdish
                      ? 'بابەتەکانی من'
                      : s.isArabic
                      ? 'إعلاناتي'
                      : 'My listings',
                  subtitle: s.isKurdish
                      ? 'بابەتە چالاکەکان، فرۆشراوەکان و بڵاوکردنەوەیەکی نوێ'
                      : 'Active, sold and relist your books',
                  onTap: () => Navigator.pushNamed(context, '/my-listings'),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF87171),
                    side: BorderSide(
                      color: const Color(0xFFF87171).withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    await PushNotificationService.unregisterCurrentDevice();
                    await Supabase.instance.client.auth.signOut();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    s.logout,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmeraldStat extends StatelessWidget {
  final AppPalette palette;
  final String title, value;
  const _EmeraldStat({
    required this.palette,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmeraldMenuCard extends StatelessWidget {
  final AppPalette palette;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _EmeraldMenuCard({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: palette.accent, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            fontSize: 14.5,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: palette.textSecondary, fontSize: 11.5),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}
