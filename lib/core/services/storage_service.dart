import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin singleton wrapper around SharedPreferences.
///
/// Strategy: everything goes in as JSON-encoded strings.
/// No Hive TypeAdapters, no build_runner — critical for a 4-hour build.
class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── JSON helpers
  Future<bool> saveJson(String key, Map<String, dynamic> data) =>
      _prefs.setString(key, jsonEncode(data));

  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Primitives
  Future<bool> saveString(String key, String value) =>
      _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);

  Future<bool> saveInt(String key, int value) => _prefs.setInt(key, value);
  int getInt(String key, {int defaultValue = 0}) =>
      _prefs.getInt(key) ?? defaultValue;

  Future<bool> saveBool(String key, bool value) => _prefs.setBool(key, value);
  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  // ── Key management
  Future<bool> remove(String key) => _prefs.remove(key);
  bool hasKey(String key) => _prefs.containsKey(key);
  Future<bool> clearAll() => _prefs.clear();
}

/// Centralised storage key registry — one place to update if keys ever change.
abstract class StorageKeys {
  static const String userProfile   = 'user_profile';
  static const String workoutRoutine = 'workout_routine';
  static const String apiKey         = 'anthropic_api_key';
  static const String onboardingDone = 'onboarding_done';
}