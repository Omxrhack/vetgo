import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstrae [SharedPreferences] y, si el canal nativo no está disponible
/// ([MissingPluginException]) — p. ej. hot reload tras añadir plugins o un run
/// incorrecto — usa un mapa en memoria para que la app no crashee (la
/// persistencia entre sesiones requiere un `flutter run` completo con plugins).
abstract final class VetgoPrefs {
  static VetgoPrefsBackend? _backend;

  static Future<VetgoPrefsBackend> get backend async {
    if (_backend != null) return _backend!;
    try {
      final sp = await SharedPreferences.getInstance();
      _backend = _SharedPrefsBackend(sp);
      return _backend!;
    } on MissingPluginException {
      _backend = _MemoryPrefsBackend();
      return _backend!;
    }
  }

  /// Solo para tests: fuerza backend en memoria.
  static void debugUseMemoryOnly() {
    _backend = _MemoryPrefsBackend();
  }

  static void debugReset() {
    _backend = null;
  }
}

abstract class VetgoPrefsBackend {
  String? getString(String key);
  Future<void> setString(String key, String? value);

  int? getInt(String key);
  Future<void> setInt(String key, int? value);

  bool? getBool(String key);
  Future<void> setBool(String key, bool? value);

  Future<void> remove(String key);
}

final class _SharedPrefsBackend implements VetgoPrefsBackend {
  _SharedPrefsBackend(this._p);

  final SharedPreferences _p;

  @override
  String? getString(String key) => _p.getString(key);

  @override
  Future<void> setString(String key, String? value) async {
    if (value == null) {
      await _p.remove(key);
    } else {
      await _p.setString(key, value);
    }
  }

  @override
  int? getInt(String key) => _p.getInt(key);

  @override
  Future<void> setInt(String key, int? value) async {
    if (value == null) {
      await _p.remove(key);
    } else {
      await _p.setInt(key, value);
    }
  }

  @override
  bool? getBool(String key) => _p.getBool(key);

  @override
  Future<void> setBool(String key, bool? value) async {
    if (value == null) {
      await _p.remove(key);
    } else {
      await _p.setBool(key, value);
    }
  }

  @override
  Future<void> remove(String key) => _p.remove(key);
}

final class _MemoryPrefsBackend implements VetgoPrefsBackend {
  final Map<String, Object?> _data = {};

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  Future<void> setString(String key, String? value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  Future<void> setInt(String key, int? value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  Future<void> setBool(String key, bool? value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }
}
