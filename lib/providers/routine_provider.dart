import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/workout_routine.dart';
import '../core/services/storage_service.dart';
import '../core/services/ai_service.dart';

enum RoutineImportStatus { idle, loading, success, error }

/// Manages the full workout routine lifecycle.
class RoutineProvider extends ChangeNotifier {
  WorkoutRoutine      _routine      = const WorkoutRoutine(routineName: '', days: []);
  RoutineImportStatus _importStatus = RoutineImportStatus.idle;
  String              _importError  = '';

  WorkoutRoutine      get routine      => _routine;
  RoutineImportStatus get importStatus => _importStatus;
  String              get importError  => _importError;
  bool                get hasRoutine   => _routine.days.isNotEmpty;

  // ── Bootstrap ─────────────────────────────────────────────────────────────
  Future<void> loadRoutine() async {
    final json = StorageService.instance.getJson(StorageKeys.workoutRoutine);
    if (json != null) _routine = WorkoutRoutine.fromJson(json);
    notifyListeners();
  }

  Future<void> _persist() async {
    await StorageService.instance.saveJson(
        StorageKeys.workoutRoutine, _routine.toJson());
  }

  // ── Quick-start ────────────────────────────────────────────────────────────
  Future<void> loadDefaultPPL() async {
    _routine = WorkoutRoutine.pplDefault();
    await _persist();
    notifyListeners();
  }

  // ── Set full routine (from AI generator) ──────────────────────────────────
  Future<void> setFullRoutine(WorkoutRoutine routine) async {
    _routine = routine.copyWith(currentDayIndex: 0);
    await _persist();
    notifyListeners();
  }

  // ── Exercise completion ────────────────────────────────────────────────────
  Future<void> markExerciseComplete(String dayId, String exerciseId) async {
    _routine = _routine.copyWith(
      days: _routine.days.map((day) {
        if (day.id != dayId) return day;
        return day.copyWith(
          exercises: day.exercises
              .map((ex) =>
          ex.id == exerciseId ? ex.copyWith(isCompleted: true) : ex)
              .toList(),
        );
      }).toList(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> markExercisePlanBComplete(
      String dayId, String exerciseId) async {
    _routine = _routine.copyWith(
      days: _routine.days.map((day) {
        if (day.id != dayId) return day;
        return day.copyWith(
          exercises: day.exercises
              .map((ex) => ex.id == exerciseId
              ? ex.copyWith(isCompleted: true, usedPlanB: true)
              : ex)
              .toList(),
        );
      }).toList(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> advanceDay() async {
    final nextIndex = (_routine.currentDayIndex + 1) % _routine.days.length;
    final resetDays = _routine.days
        .map((day) => day.copyWith(
      exercises: day.exercises
          .map((e) => e.copyWith(isCompleted: false, usedPlanB: false))
          .toList(),
    ))
        .toList();
    _routine = _routine.copyWith(days: resetDays, currentDayIndex: nextIndex);
    await _persist();
    notifyListeners();
  }

  // ── Day management ────────────────────────────────────────────────────────
  void addWorkoutDay(String dayName) {
    _routine = _routine.copyWith(
      days: [..._routine.days, WorkoutDay(dayName: dayName)],
    );
    _persist();
    notifyListeners();
  }

  /// Fully deletes a workout day and clamps the day index if needed.
  void removeDay(String dayId) {
    final newDays = _routine.days.where((d) => d.id != dayId).toList();
    if (newDays.isEmpty) return; // always keep at least one day
    final newIndex = (_routine.currentDayIndex >= newDays.length)
        ? newDays.length - 1
        : _routine.currentDayIndex;
    _routine = _routine.copyWith(days: newDays, currentDayIndex: newIndex);
    _persist();
    notifyListeners();
  }

  void updateDayName(String dayId, String newName) {
    if (newName.trim().isEmpty) return;
    _routine = _routine.copyWith(
      days: _routine.days.map((day) =>
      day.id == dayId ? day.copyWith(dayName: newName.trim()) : day)
          .toList(),
    );
    _persist();
    notifyListeners();
  }

  // ── Exercise management ───────────────────────────────────────────────────
  void addExerciseToDay(String dayId, Exercise exercise) {
    _routine = _routine.copyWith(
      days: _routine.days.map((day) {
        if (day.id != dayId) return day;
        return day.copyWith(exercises: [...day.exercises, exercise]);
      }).toList(),
    );
    _persist();
    notifyListeners();
  }

  /// Removes a single exercise from a day and immediately persists + notifies.
  void removeExercise(String dayId, String exerciseId) {
    _routine = _routine.copyWith(
      days: _routine.days.map((day) {
        if (day.id != dayId) return day;
        return day.copyWith(
          exercises: day.exercises
              .where((e) => e.id != exerciseId)
              .toList(),
        );
      }).toList(),
    );
    _persist();
    notifyListeners(); // ← was missing in original stub
  }

  /// Replaces an existing exercise in-place (used by the edit screen).
  void updateExercise(String dayId, Exercise updated) {
    _routine = _routine.copyWith(
      days: _routine.days.map((day) {
        if (day.id != dayId) return day;
        return day.copyWith(
          exercises: day.exercises
              .map((ex) => ex.id == updated.id ? updated : ex)
              .toList(),
        );
      }).toList(),
    );
    _persist();
    notifyListeners();
  }

  // ── Vision import ─────────────────────────────────────────────────────────
  Future<void> importRoutineFromImage({
    required Uint8List imageBytes,
    required String    dayName,
  }) async {
    _importStatus = RoutineImportStatus.loading;
    _importError  = '';
    notifyListeners();

    try {
      final exercises = await AIService.instance.extractRoutineFromImage(imageBytes);
      final newDay    = WorkoutDay(dayName: dayName, exercises: exercises);
      _routine = _routine.copyWith(
        routineName: _routine.routineName.isEmpty ? 'My Routine' : _routine.routineName,
        days       : [..._routine.days, newDay],
      );
      await _persist();
      _importStatus = RoutineImportStatus.success;
    } catch (e) {
      _importError  = e.toString();
      _importStatus = RoutineImportStatus.error;
    }
    notifyListeners();
  }

  void resetImportStatus() {
    _importStatus = RoutineImportStatus.idle;
    _importError  = '';
    notifyListeners();
  }
}