import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../core/services/storage_service.dart';

/// Manages user profile state and all gamification logic.
///
/// Streak rule:
///   • Same day  → no change
///   • Next day  → streak + 1
///   • 2+ days   → streak resets to 1 (broken)
class UserProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile.empty();
  bool        _isLoaded = false;

  UserProfile get profile   => _profile;
  bool        get isLoaded  => _isLoaded;
  bool        get hasProfile => _profile.name.isNotEmpty;

  // ── Bootstrap ─────────────────────────────────────────────────────────────
  Future<void> loadProfile() async {
    final json = StorageService.instance.getJson(StorageKeys.userProfile);
    if (json != null) _profile = UserProfile.fromJson(json);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await StorageService.instance.saveJson(
      StorageKeys.userProfile,
      _profile.toJson(),
    );
  }

  // ── Profile updates ───────────────────────────────────────────────────────
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    await _persist();
    notifyListeners();
  }

  Future<void> updateProfile({
    String?       name,
    String?       fitnessLevel,
    List<String>? injuries,
  }) async {
    _profile = _profile.copyWith(
      name         : name,
      fitnessLevel : fitnessLevel,
      injuries     : injuries,
    );
    await _persist();
    notifyListeners();
  }

  // ── Gamification ──────────────────────────────────────────────────────────

  /// Award XP for completing a single exercise.
  Future<void> awardExerciseXP() async {
    await _addXP(UserProfile.xpExerciseDone);
  }

  /// Award XP for using Plan B (alternative) + flag workout as done today.
  Future<void> awardPlanBXP() async {
    await _addXP(UserProfile.xpPlanBUsed);
  }

  /// Award XP for finishing an entire workout, and update the streak.
  Future<void> awardWorkoutCompleteXP() async {
    final now     = DateTime.now();
    final newXP   = _profile.xp + UserProfile.xpWorkoutComplete;
    final newStreak = _computeNewStreak(now);

    _profile = _profile.copyWith(
      xp              : newXP,
      streak          : newStreak,
      lastWorkoutDate : now,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> _addXP(int amount) async {
    _profile = _profile.copyWith(xp: _profile.xp + amount);
    await _persist();
    notifyListeners();
  }

  int _computeNewStreak(DateTime now) {
    final last = _profile.lastWorkoutDate;
    if (last == null) return 1;

    final lastDay  = DateTime(last.year, last.month, last.day);
    final today    = DateTime(now.year, now.month, now.day);
    final daysDiff = today.difference(lastDay).inDays;

    if (daysDiff == 0) return _profile.streak;   // already logged today
    if (daysDiff == 1) return _profile.streak + 1; // consecutive — increment
    return 1;                                      // gap — reset
  }
}