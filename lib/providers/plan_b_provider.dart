import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/plan_b_result.dart';
import '../models/user_profile.dart';
import '../models/workout_routine.dart';
import '../core/services/ai_service.dart';

enum PlanBStatus { idle, loading, success, error }

/// State machine for the Plan B AI feature.
///
/// Flow:
///   1. [setTargetExercise] — user selects which exercise is busy
///   2. [toggleEquipment]  — user checks what's available
///   3. [triggerPlanB]     — sends request to AI → loading → success/error
///   4. Provider consumers can check [result] and render the result card
class PlanBProvider extends ChangeNotifier {
  PlanBStatus  _status        = PlanBStatus.idle;
  PlanBResult? _result;
  String       _errorMessage  = '';
  Exercise?    _targetExercise;
  Uint8List?   _machineImage; // optional photo of the busy machine

  final List<String> _selectedEquipment = [];

  // ── Available equipment options ────────────────────────────────────────────
  static const List<String> equipmentOptions = [
    'Dumbbells',
    'Cables',
    'Barbell',
    'Resistance Bands',
    'Bodyweight',
    'Smith Machine',
    'Kettlebell',
    'Pull-up Bar',
    'TRX / Suspension',
    'Dip Bar',
  ];

  // ── Public state ──────────────────────────────────────────────────────────
  PlanBStatus      get status           => _status;
  PlanBResult?     get result           => _result;
  String           get errorMessage     => _errorMessage;
  Exercise?        get targetExercise   => _targetExercise;
  Uint8List?       get machineImage     => _machineImage;
  List<String>     get selectedEquipment => List.unmodifiable(_selectedEquipment);
  bool             get hasEquipment     => _selectedEquipment.isNotEmpty;

  bool isEquipmentSelected(String e) => _selectedEquipment.contains(e);

  // ── Mutations ─────────────────────────────────────────────────────────────
  void setTargetExercise(Exercise exercise) {
    _targetExercise = exercise;
    _status         = PlanBStatus.idle;
    _result         = null;
    _errorMessage   = '';
    _machineImage   = null;
    _selectedEquipment.clear();
    notifyListeners();
  }

  void setMachineImage(Uint8List? bytes) {
    _machineImage = bytes;
    notifyListeners();
  }

  void toggleEquipment(String equipment) {
    if (_selectedEquipment.contains(equipment)) {
      _selectedEquipment.remove(equipment);
    } else {
      _selectedEquipment.add(equipment);
    }
    notifyListeners();
  }

  void reset() {
    _status         = PlanBStatus.idle;
    _result         = null;
    _errorMessage   = '';
    _targetExercise = null;
    _machineImage   = null;
    _selectedEquipment.clear();
    notifyListeners();
  }

  // ── AI call ───────────────────────────────────────────────────────────────
  Future<void> triggerPlanB({required UserProfile userProfile}) async {
    if (_targetExercise == null) return;

    _status       = PlanBStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _result = await AIService.instance.getPlanBAlternative(
        busyExercise       : _targetExercise!,
        availableEquipment : List.from(_selectedEquipment),
        userProfile        : userProfile,
        machineImageBytes  : _machineImage,
      );
      _status = PlanBStatus.success;
    } on AIException catch (e) {
      _errorMessage = e.message;
      _status       = PlanBStatus.error;
    } catch (e) {
      _errorMessage = e.toString();
      _status       = PlanBStatus.error;
    }
    notifyListeners();
  }
}