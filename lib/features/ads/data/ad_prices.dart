import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/digits.dart';

/// Weekly ad prices per placement, stored in the ad_prices table so the admin
/// can change them without a new app version.
class AdPrices {
  static const defaults = {'home': 15000, 'course': 5000};
  static const labels = {'home': 'شاشەی سەرەکی', 'course': 'بەشی کۆرسەکان'};

  static SupabaseClient get _db => Supabase.instance.client;

  static Future<Map<String, int>> load() async {
    final prices = Map<String, int>.from(defaults);
    try {
      final rows = await _db
          .from('ad_prices')
          .select('placement, price_per_week_iqd');
      for (final row in rows) {
        final price = (row['price_per_week_iqd'] as num?)?.toInt();
        if (price != null && price > 0) prices['${row['placement']}'] = price;
      }
    } catch (_) {}
    return prices;
  }

  /// Same rule as the database: whole weeks, at least one.
  static int total(int weeklyPrice, int days) =>
      weeklyPrice * (days ~/ 7 < 1 ? 1 : days ~/ 7);

  static Future<void> save(Map<String, int> prices) async {
    await _db.from('ad_prices').upsert([
      for (final e in prices.entries)
        {
          'placement': e.key,
          'price_per_week_iqd': e.value,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
    ]);
  }

  /// Admin dialog to change the weekly prices.
  static Future<void> showEditor(BuildContext context) async {
    final current = await load();
    if (!context.mounted) return;
    final controllers = {
      for (final key in defaults.keys)
        key: TextEditingController(text: '${current[key]}'),
    };
    String? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('نرخی ڕیکلام (بۆ هەر ٧ ڕۆژ)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final key in defaults.keys) ...[
                TextField(
                  controller: controllers[key],
                  keyboardType: TextInputType.number,
                  inputFormatters: [Digits.onlyDigits],
                  decoration: InputDecoration(
                    labelText: labels[key],
                    suffixText: 'IQD',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                '١٤ ڕۆژ = ٢ هەفتە، ٣٠ ڕۆژ = ٤ هەفتە. نرخی نوێ تەنها بۆ ڕیکلامە نوێکان دەبێت.',
                style: TextStyle(fontSize: 12),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('پاشگەزبوونەوە'),
            ),
            FilledButton(
              onPressed: () async {
                final prices = <String, int>{};
                for (final e in controllers.entries) {
                  final v = Digits.parse(e.value.text);
                  if (v == null || v < 250 || v > 100000000) {
                    setState(() => error = 'نرخێکی دروست بنووسە (لانیکەم 250)');
                    return;
                  }
                  prices[e.key] = v;
                }
                try {
                  await save(prices);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('نرخەکان نوێکرانەوە ✓')),
                    );
                  }
                } catch (_) {
                  setState(
                    () => error =
                        'پاشەکەوت نەکرا. دڵنیابە فایلی SQL ـی 20 ڕان کراوە.',
                  );
                }
              },
              child: const Text('پاشەکەوتکردن'),
            ),
          ],
        ),
      ),
    );
    for (final c in controllers.values) {
      c.dispose();
    }
  }
}
