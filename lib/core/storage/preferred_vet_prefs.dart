import 'package:shared_preferences/shared_preferences.dart';

/// Veterinario preferido para emergencias y citas (cliente).
abstract final class PreferredVetPrefs {
  static const _kId = 'vetgo_preferred_vet_id';

  static const _kName = 'vetgo_preferred_vet_name';

  static Future<String?> readId() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kId);
    if (s == null || s.isEmpty) return null;
    return s;
  }

  static Future<String?> readDisplayName() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kName);
    if (s == null || s.isEmpty) return null;
    return s;
  }

  static Future<void> save({required String id, required String displayName}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kId, id);
    await p.setString(_kName, displayName.trim());
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kId);
    await p.remove(_kName);
  }
}
