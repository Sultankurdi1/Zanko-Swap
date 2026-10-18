import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesStore extends ChangeNotifier {
  FavoritesStore._() {
    _ready = _loadFromDisk();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _loadFromDisk();
    });
  }
  static final FavoritesStore instance = FavoritesStore._();

  final Set<String> _keys = <String>{};
  late Future<void> _ready;
  bool _loaded = false;

  String get _currentKey {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return uid != null
        ? 'zankoswap_favorites_$uid'
        : 'zankoswap_favorites_guest';
  }

  bool get loaded => _loaded;
  bool containsListing(String id) => _keys.contains('listing:$id');
  bool containsExam(String id) => _keys.contains('exam:$id');
  bool containsResearch(String id) => _keys.contains('research:$id');
  bool contains(String id) => containsListing(id);

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    _keys
      ..clear()
      ..addAll(prefs.getStringList(_currentKey) ?? const <String>[]);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _toggle(String key) async {
    await _ready;
    if (!_keys.add(key)) _keys.remove(key);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_currentKey, _keys.toList());
  }

  Future<void> toggleListing(String id) => _toggle('listing:$id');
  Future<void> toggleExam(String id) => _toggle('exam:$id');
  Future<void> toggleResearch(String id) => _toggle('research:$id');

  Future<void> reload() => _loadFromDisk();
}
