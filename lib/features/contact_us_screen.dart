import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/localization/app_strings.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نەتوانرا بەستەرەکە بکرێتەوە.')),
        );
      }
    } catch (e) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('هەڵە لە کردنەوەی بەستەر: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ku = AppStrings.of(context).isKurdish;
    return Scaffold(
      appBar: AppBar(title: Text(ku ? 'پەیوەندیمان پێوە بکە' : 'Contact us')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.tertiary,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              ku ? 'یارمەتی و پشتیوانی ZankoSwap' : 'ZankoSwap support',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
              title: const Text('WhatsApp'),
              subtitle: const Text('+964 750 435 9605'),
              onTap: () =>
                  _open(context, Uri.parse('https://wa.me/9647504359605')),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(ku ? 'ژمارەی یەکەم' : 'Phone 1'),
              subtitle: const Text('+964 750 435 9605'),
              onTap: () => _open(context, Uri.parse('tel:+9647504359605')),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(ku ? 'ژمارەی دووەم' : 'Phone 2'),
              subtitle: const Text('+964 773 405 9605'),
              onTap: () => _open(context, Uri.parse('tel:+9647734059605')),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: const Text('tahasulaiman135@gmail.com'),
              onTap: () => _open(
                context,
                Uri(scheme: 'mailto', path: 'tahasulaiman135@gmail.com'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
