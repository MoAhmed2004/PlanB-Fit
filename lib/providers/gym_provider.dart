import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/services/fake_gym_data_service.dart';
import '../models/gym_equipment.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// Gym Provider
///
/// Manages real-time gym occupancy state with automatic refresh.
/// Uses FakeGymDataService for demo data — swap for real API in production.
///
/// Features:
///   • Auto-refreshes occupancy every 20 seconds (simulates live IoT data)
///   • Small incremental changes between refreshes (realistic feel)
///   • Week predictions cached on first load
///   • Equipment filtering by category/zone
///   • Machine search by name
///   • Exercise-to-equipment mapping for routine occupancy badges
/// ═══════════════════════════════════════════════════════════════════════════════
class GymProvider extends ChangeNotifier {
  GymOccupancy? _occupancy;
  List<DayPrediction>? _weekPredictions;
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _selectedCategory; // null = all
  String _searchQuery = '';

  // ── Getters ─────────────────────────────────────────────────────────────────
  GymOccupancy? get occupancy => _occupancy;
  List<DayPrediction>? get weekPredictions => _weekPredictions;
  bool get isLoading => _isLoading;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  /// Today's prediction from the week data.
  DayPrediction? get todayPrediction =>
      _weekPredictions?.firstWhere((d) => d.isToday, orElse: () => _weekPredictions!.first);

  /// Best time to go today.
  String get bestTimeToday {
    final today = todayPrediction;
    if (today == null) return 'Loading...';
    return today.bestTimeLabel;
  }

  /// Filtered equipment list based on selected category AND search query.
  List<GymEquipment> get filteredEquipment {
    if (_occupancy == null) return [];
    var list = _occupancy!.equipment;

    // Apply category filter
    if (_selectedCategory != null) {
      list = list.where((e) => e.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((e) =>
          e.name.toLowerCase().contains(query) ||
          e.category.toLowerCase().contains(query) ||
          e.zone.toLowerCase().contains(query)).toList();
    }

    return list;
  }

  /// All unique categories from equipment.
  List<String> get categories {
    if (_occupancy == null) return [];
    return _occupancy!.equipment
        .map((e) => e.category)
        .toSet()
        .toList()
      ..sort();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  /// Initialize the provider — call once on app start or when gym tab is opened.
  void initialize() {
    if (_occupancy != null) return; // Already initialized
    _loadInitialData();
    _startAutoRefresh();
  }

  /// Set category filter for equipment list.
  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Set search query for equipment list.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search query.
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Force a full refresh of occupancy data.
  void forceRefresh() {
    _occupancy = FakeGymDataService.generateOccupancy();
    _isLoading = false;
    notifyListeners();
  }

  // ── Exercise-to-Equipment Mapping ──────────────────────────────────────────

  /// Maps common exercise names from routines to equipment names in the gym.
  /// This allows showing occupancy status next to exercises in the user's routine.
  static const Map<String, List<String>> _exerciseToEquipmentMap = {
    // Chest exercises
    'barbell bench press': ['Flat Bench Press'],
    'bench press': ['Flat Bench Press'],
    'flat bench press': ['Flat Bench Press'],
    'incline bench press': ['Incline Bench Press'],
    'incline db press': ['Incline Bench Press'],
    'incline dumbbell press': ['Incline Bench Press'],
    'cable crossover': ['Cable Crossover'],
    'cable fly': ['Cable Crossover'],
    'chest press': ['Chest Press Machine'],
    'machine chest press': ['Chest Press Machine'],
    'pec deck': ['Pec Deck Fly'],
    'pec fly': ['Pec Deck Fly'],
    'chest fly machine': ['Pec Deck Fly'],
    // Back exercises
    'lat pulldown': ['Lat Pulldown'],
    'lat pull down': ['Lat Pulldown'],
    'seated row': ['Seated Row Machine'],
    'cable row': ['Seated Row Machine'],
    'seated cable row': ['Seated Row Machine'],
    't-bar row': ['T-Bar Row'],
    'pull-ups': ['Pull-Up Station'],
    'pull ups': ['Pull-Up Station'],
    'chin-ups': ['Pull-Up Station'],
    'chin ups': ['Pull-Up Station'],
    // Legs exercises
    'barbell squat': ['Squat Rack #1', 'Squat Rack #2'],
    'squat': ['Squat Rack #1', 'Squat Rack #2'],
    'back squat': ['Squat Rack #1', 'Squat Rack #2'],
    'front squat': ['Squat Rack #1', 'Squat Rack #2'],
    'leg press': ['Leg Press'],
    'leg extension': ['Leg Extension'],
    'leg curls': ['Leg Curl'],
    'leg curl': ['Leg Curl'],
    'hamstring curl': ['Leg Curl'],
    'hack squat': ['Hack Squat'],
    'calf raise': ['Calf Raise Machine'],
    'calf raises': ['Calf Raise Machine'],
    // Shoulders
    'overhead press': ['Shoulder Press Machine', 'Squat Rack #1', 'Squat Rack #2'],
    'shoulder press': ['Shoulder Press Machine'],
    'machine shoulder press': ['Shoulder Press Machine'],
    'lateral raise machine': ['Lateral Raise Machine'],
    'lateral raises': ['Lateral Raise Machine'],
    // Arms
    'preacher curl': ['Preacher Curl Bench'],
    'bicep curl': ['Preacher Curl Bench'],
    'tricep pushdown': ['Tricep Pushdown Cable'],
    'tricep extension': ['Tricep Pushdown Cable'],
    'cable tricep': ['Tricep Pushdown Cable'],
    // Compound
    'smith machine': ['Smith Machine'],
    'deadlift': ['Deadlift Platform'],
    'romanian deadlift': ['Deadlift Platform'],
    'rdl': ['Deadlift Platform'],
    // Cardio
    'treadmill': ['Treadmill #1', 'Treadmill #2', 'Treadmill #3'],
    'elliptical': ['Elliptical #1'],
    'stationary bike': ['Stationary Bike #1', 'Stationary Bike #2'],
    'cycling': ['Stationary Bike #1', 'Stationary Bike #2'],
    'rowing': ['Rowing Machine'],
    'stair climber': ['Stair Climber'],
  };

  /// Find equipment status for a given exercise name from the user's routine.
  /// Returns null if no matching equipment found or gym data not loaded.
  /// Returns the "best" equipment (prefers available ones if multiple match).
  GymEquipment? findEquipmentForExercise(String exerciseName) {
    if (_occupancy == null) return null;

    final normalizedName = exerciseName.toLowerCase().trim();

    // Try exact mapping first
    List<String>? equipmentNames = _exerciseToEquipmentMap[normalizedName];

    // Try partial match if exact fails
    if (equipmentNames == null) {
      for (final entry in _exerciseToEquipmentMap.entries) {
        if (normalizedName.contains(entry.key) || entry.key.contains(normalizedName)) {
          equipmentNames = entry.value;
          break;
        }
      }
    }

    if (equipmentNames == null || equipmentNames.isEmpty) return null;

    // Find the actual equipment objects
    final matchingEquipment = _occupancy!.equipment
        .where((eq) => equipmentNames!.contains(eq.name))
        .toList();

    if (matchingEquipment.isEmpty) return null;

    // Prefer available equipment
    final available = matchingEquipment.where((eq) => eq.isFree).toList();
    if (available.isNotEmpty) return available.first;

    // Return first match (busy)
    return matchingEquipment.first;
  }

  /// Check if any equipment for a given exercise is available.
  /// Returns: true = at least one free, false = all busy, null = no mapping found
  bool? isEquipmentAvailable(String exerciseName) {
    if (_occupancy == null) return null;

    final normalizedName = exerciseName.toLowerCase().trim();
    List<String>? equipmentNames = _exerciseToEquipmentMap[normalizedName];

    if (equipmentNames == null) {
      for (final entry in _exerciseToEquipmentMap.entries) {
        if (normalizedName.contains(entry.key) || entry.key.contains(normalizedName)) {
          equipmentNames = entry.value;
          break;
        }
      }
    }

    if (equipmentNames == null || equipmentNames.isEmpty) return null;

    final matchingEquipment = _occupancy!.equipment
        .where((eq) => equipmentNames!.contains(eq.name))
        .toList();

    if (matchingEquipment.isEmpty) return null;

    return matchingEquipment.any((eq) => eq.isFree);
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  void _loadInitialData() {
    _occupancy = FakeGymDataService.generateOccupancy();
    _weekPredictions = FakeGymDataService.generateWeekPredictions();
    _isLoading = false;
    notifyListeners();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    // Simulate live updates every 20 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_occupancy != null) {
        _occupancy = FakeGymDataService.applySmallChange(_occupancy!);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
