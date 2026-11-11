import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/localization/app_strings.dart';

/// Shows [child] only to signed-out visitors and to signed-in people who have
/// confirmed they are 13 or older. Everyone else is asked for their date of
/// birth once. Under-13 accounts are deleted and signed out.
class AgeGate extends StatefulWidget {
  final Widget child;
  const AgeGate({super.key, required this.child});

  static const minimumAge = 13;

  static int ageOn(DateTime birth, DateTime today) {
    var age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age;
  }

  @override
  State<AgeGate> createState() => _AgeGateState();
}

enum _Status { checking, ok, needsBirthDate }

class _AgeGateState extends State<AgeGate> {
  final _db = Supabase.instance.client;
  StreamSubscription<AuthState>? _sub;
  String? _userId;
  _Status _status = _Status.ok;

  @override
  void initState() {
    super.initState();
    _check(_db.auth.currentUser?.id);
    _sub = _db.auth.onAuthStateChange.listen((event) {
      final id = event.session?.user.id;
      if (id != _userId) _check(id);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _key(String id) => 'age_ok_$id';

  Future<void> _check(String? id) async {
    _userId = id;
    if (id == null) {
      if (mounted) setState(() => _status = _Status.ok);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_key(id)) == true) {
      if (mounted && _userId == id) setState(() => _status = _Status.ok);
      return;
    }
    if (mounted) setState(() => _status = _Status.checking);
    try {
      final row = await _db
          .from('age_checks')
          .select('user_id')
          .eq('user_id', id)
          .maybeSingle();
      if (row != null) await prefs.setBool(_key(id), true);
      if (mounted && _userId == id) {
        setState(
          () => _status = row != null ? _Status.ok : _Status.needsBirthDate,
        );
      }
    } catch (_) {
      // Offline or server not ready: do not lock people out; ask next time.
      if (mounted && _userId == id) setState(() => _status = _Status.ok);
    }
  }

  Future<void> _submit(DateTime birth) async {
    final id = _userId;
    if (id == null) return;
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (AgeGate.ageOn(birth, DateTime.now()) < AgeGate.minimumAge) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(s.tooYoungTitle),
          content: Text(s.tooYoungBody),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.okLabel),
            ),
          ],
        ),
      );
      try {
        await _db.rpc('delete_my_account');
      } catch (_) {}
      await _db.auth.signOut();
      return;
    }

    try {
      final date =
          '${birth.year.toString().padLeft(4, '0')}-${birth.month.toString().padLeft(2, '0')}-${birth.day.toString().padLeft(2, '0')}';
      await _db.from('age_checks').upsert({'user_id': id, 'birth_date': date});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(id), true);
      if (mounted) setState(() => _status = _Status.ok);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.errorFor(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _Status.ok:
        return widget.child;
      case _Status.checking:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _Status.needsBirthDate:
        return _BirthDateScreen(onSubmit: _submit);
    }
  }
}

class _BirthDateScreen extends StatefulWidget {
  final Future<void> Function(DateTime) onSubmit;
  const _BirthDateScreen({required this.onSubmit});

  @override
  State<_BirthDateScreen> createState() => _BirthDateScreenState();
}

class _BirthDateScreenState extends State<_BirthDateScreen> {
  DateTime? _birth;
  bool _busy = false;

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) setState(() => _birth = picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final b = _birth;
    return Directionality(
      textDirection: s.isKurdish || s.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(Icons.cake_rounded, size: 64, color: scheme.primary),
                const SizedBox(height: 20),
                Text(
                  s.birthDateTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.birthDateExplain,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    b == null
                        ? s.pickBirthDate
                        : '${b.year} / ${b.month} / ${b.day}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                  onPressed: b == null || _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          await widget.onSubmit(b);
                          if (mounted) setState(() => _busy = false);
                        },
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Text(s.continueLabel),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Supabase.instance.client.auth.signOut(),
                  child: Text(s.logout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
