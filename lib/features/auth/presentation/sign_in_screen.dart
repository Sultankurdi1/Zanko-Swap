import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool isRegister = false;
  bool usePhone = false;
  bool busy = false;
  String? error;
  String? info;

  static const String _webClientId =
      '878815878632-6esnk6heuf196cc8qhva748f3e7835qu.apps.googleusercontent.com';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(User user, {String? fallbackName}) async {
    try {
      final meta = user.userMetadata ?? const <String, dynamic>{};
      final name =
          (meta['displayName'] ??
                  meta['display_name'] ??
                  meta['full_name'] ??
                  meta['name'] ??
                  fallbackName ??
                  '')
              .toString()
              .trim();
      final photo =
          (meta['photoUrl'] ?? meta['picture'] ?? meta['avatar_url'] ?? '')
              .toString()
              .trim();
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'displayName': name,
        'photoUrl': photo.isEmpty ? null : photo,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
      info = null;
    });

    try {
      final identifier = _emailCtrl.text.trim();
      final password = _passCtrl.text;

      if (isRegister) {
        final result = usePhone
            ? await Supabase.instance.client.auth.signUp(
                phone: identifier,
                password: password,
                data: {'displayName': _nameCtrl.text.trim()},
              )
            : await Supabase.instance.client.auth.signUp(
                email: identifier,
                password: password,
                data: {'displayName': _nameCtrl.text.trim()},
              );
        if (result.user != null && result.session != null) {
          await _saveProfile(result.user!, fallbackName: _nameCtrl.text.trim());
        }
        if (result.user == null) {
          throw const AuthException('Registration failed');
        }

        if (result.session == null) {
          if (!mounted) return;
          setState(() {
            isRegister = false;
            info = AppStrings.of(context).isKurdish
                ? 'ئیمەیڵەکەت بپشکنە و لینکەکەی پشتڕاستکردنەوە بکەرەوە، پاشان بچۆ ژوورەوە.'
                : 'Check your email and confirm your account, then sign in again.';
            error = null;
          });
          return;
        }
      } else {
        final result = await Supabase.instance.client.auth.signInWithPassword(
          email: usePhone ? null : identifier,
          phone: usePhone ? identifier : null,
          password: password,
        );
        if (result.session == null) {
          throw const AuthException('Login did not create a session.');
        }
      }

      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      setState(() => error = _authError(e));
    } catch (e) {
      final msg = e.toString();
      setState(() {
        error = msg.contains('Invalid API key') || msg.contains('401')
            ? 'Supabase API key ـەکە هەڵەیە؛ Publishable key ـی نوێ لە Supabase Dashboard دابنێ.'
            : msg;
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    final isKu = AppStrings.of(context).isKurdish;
    if (usePhone || !email.contains('@')) {
      setState(() {
        error = isKu ? 'سەرەتا ئیمەیڵەکەت بنووسە.' : 'Enter your email first.';
        info = null;
      });
      return;
    }
    setState(() {
      busy = true;
      error = null;
      info = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      setState(() {
        info = isKu
            ? 'لینکی نوێکردنەوەی وشەی نهێنی بۆ ئیمەیڵەکەت نێردرا. inbox و spam بپشکنە.'
            : 'A password reset link was sent. Check your inbox and spam folder.';
      });
    } on AuthException catch (e) {
      if (mounted) setState(() => error = _authError(e));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      busy = true;
      error = null;
      info = null;
    });
    try {
      final google = GoogleSignIn(
        serverClientId: _webClientId,
        clientId: _webClientId,
        scopes: const ['email', 'profile'],
      );

      final account = await google.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      if (auth.idToken == null) {
        throw const AuthException(
          'Google did not return an ID token. Check the Android OAuth client configuration.',
        );
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: auth.idToken!,
        accessToken: auth.accessToken,
      );
      final googleUser = Supabase.instance.client.auth.currentUser;
      if (googleUser != null) {
        await _saveProfile(
          googleUser,
          fallbackName: account.displayName ?? account.email.split('@').first,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => error = _authError(e));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _authError(AuthException e) {
    final isKu = AppStrings.of(context).isKurdish;
    switch (e.code) {
      case 'invalid_credentials':
      case 'user_not_found':
        return isKu
            ? 'ئیمەیڵ یان وشەی نهێنی هەڵەیە.'
            : 'Email or password is incorrect.';
      case 'email_not_confirmed':
        return isKu
            ? 'سەرەتا ئیمەیڵەکەت پشتڕاست بکەرەوە، پاشان بچۆ ژوورەوە.'
            : 'Confirm your email first, then sign in again.';
      case 'user_already_exists':
      case 'email_exists':
        return isKu
            ? 'ئەم ئیمەیڵە پێشتر هەژماری هەیە؛ بچۆ ژوورەوە.'
            : 'This email already has an account. Sign in instead.';
      case 'weak_password':
        return isKu
            ? 'وشەی نهێنی دەبێت لانیکەم ٦ پیت بێت.'
            : 'Password must be at least 6 characters.';
      case 'over_email_send_rate_limit':
        return isKu
            ? 'ژمارەی ناردنی ئیمەیڵ زۆر بوو؛ کەمێک چاوەڕێ بکە.'
            : 'Too many email requests. Try again later.';
      default:
        return e.message.isNotEmpty
            ? e.message
            : (isKu
                  ? 'چوونەژوورەوە سەرکەوتوو نەبوو.'
                  : 'Authentication failed.');
    }
  }

  InputDecoration _decor({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF34D399), size: 20),
      filled: true,
      fillColor: const Color(0xFF0C271E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF071D16),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ZankoSwap',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.isKurdish
                        ? 'بچۆ ژوورەوە یان هەژمارێک دروست بکە'
                        : 'Sign in or create an account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  if (isRegister) ...[
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                      ),
                      decoration: _decor(
                        label: s.fullName,
                        icon: Icons.person_rounded,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? s.invalidCredentials
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C271E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: busy
                                ? null
                                : () => setState(() => usePhone = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: !usePhone
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.alternate_email_rounded,
                                    size: 16,
                                    color: !usePhone
                                        ? Colors.white
                                        : Colors.white54,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.email,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: !usePhone
                                          ? Colors.white
                                          : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: busy
                                ? null
                                : () => setState(() => usePhone = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: usePhone
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: usePhone
                                        ? Colors.white
                                        : Colors.white54,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.phone,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: usePhone
                                          ? Colors.white
                                          : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _emailCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: _decor(
                      label: usePhone ? s.phone : s.email,
                      icon: usePhone
                          ? Icons.phone_android_rounded
                          : Icons.alternate_email_rounded,
                    ),
                    keyboardType: usePhone
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null ||
                            v.trim().isEmpty ||
                            (!usePhone && !v.contains('@')))
                        ? s.invalidCredentials
                        : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _passCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: _decor(
                      label: s.password,
                      icon: Icons.key_rounded,
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) => (v == null || v.length < 6)
                        ? s.invalidCredentials
                        : null,
                  ),
                  const SizedBox(height: 12),

                  if (info != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        info!,
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 12.5,
                        ),
                      ),
                    ),

                  if (error != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF87171).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 12.5,
                        ),
                      ),
                    ),

                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.35),
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
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isRegister ? s.createAccount : s.signIn,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C271E),
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: busy ? null : _google,
                    icon: const Icon(
                      Icons.account_circle_outlined,
                      color: Color(0xFF34D399),
                      size: 20,
                    ),
                    label: Text(
                      s.isKurdish
                          ? 'چوونەژوورەوە بە Gmail'
                          : 'Continue with Google',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  if (!isRegister) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: busy ? null : _resetPassword,
                      child: Text(
                        s.isKurdish
                            ? 'وشەی نهێنیت لەبیرچووە؟'
                            : 'Forgot password?',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],

                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            isRegister = !isRegister;
                            error = null;
                          }),
                    child: Text(
                      isRegister ? s.haveAccountSignIn : s.noAccountRegister,
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
