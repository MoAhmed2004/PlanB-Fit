import 'dart:math';
import '../../models/gym_equipment.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// Fake Gym Data Service
///
/// Generates realistic, time-aware gym occupancy data for demo purposes.
/// Simulates IoT sensor data without requiring any backend or real hardware.
///
/// Usage:
///   final occupancy = FakeGymDataService.generateOccupancy();
///   final predictions = FakeGymDataService.generateWeekPredictions();
/// ═══════════════════════════════════════════════════════════════════════════════
class FakeGymDataService {
  static final Random _random = Random();

  // ── Equipment Database ──────────────────────────────────────────────────────
  static const List<Map<String, String>> _equipmentDb = [
    // Chest
    {'id': 'eq_01', 'name': 'Flat Bench Press', 'category': 'chest', 'zone': 'Zone A - Free Weights', 'icon': 'fitness_center'},
    {'id': 'eq_02', 'name': 'Incline Bench Press', 'category': 'chest', 'zone': 'Zone A - Free Weights', 'icon': 'fitness_center'},
    {'id': 'eq_03', 'name': 'Cable Crossover', 'category': 'chest', 'zone': 'Zone B - Cables', 'icon': 'cable'},
    {'id': 'eq_04', 'name': 'Chest Press Machine', 'category': 'chest', 'zone': 'Zone C - Machines', 'icon': 'fitness_center'},
    {'id': 'eq_05', 'name': 'Pec Deck Fly', 'category': 'chest', 'zone': 'Zone C - Machines', 'icon': 'fitness_center'},
    // Back
    {'id': 'eq_06', 'name': 'Lat Pulldown', 'category': 'back', 'zone': 'Zone B - Cables', 'icon': 'fitness_center'},
    {'id': 'eq_07', 'name': 'Seated Row Machine', 'category': 'back', 'zone': 'Zone C - Machines', 'icon': 'fitness_center'},
    {'id': 'eq_08', 'name': 'T-Bar Row', 'category': 'back', 'zone': 'Zone A - Free Weights', 'icon': 'fitness_center'},
    {'id': 'eq_09', 'name': 'Pull-Up Station', 'category': 'back', 'zone': 'Zone D - Bodyweight', 'icon': 'fitness_center'},
    // Legs
    {'id': 'eq_10', 'name': 'Squat Rack #1', 'category': 'legs', 'zone': 'Zone A - Free Weights', 'icon': 'fitness_center'},
    {'id': 'eq_11', 'name': 'Squat Rack #2', 'category': 'legs', 'zone': 'Zone A - Free Weights', 'icon': 'fitness_center'},
    {'id': 'eq_12', 'name': 'Leg Press', 'category': 'legs', 'zone': 'Zone C - Machines', 'icon': 'fitness_center'},
    {'id': 'eq_13', 'name': 'Leg Extension', 'category': 'legs', 'zone': 'Zone C - Machines', 'icon': 'fitness_center'},
    {'id': 'eq_14', 'name': 'Leg Curl', 'category': 'legs', 'zone': 'Zone C - Machines', 'icon': 'fitness_center'},
    {'id': 'eq_15', 'name': 'Hack Squat', 'category': 'legs', 'zone': 'Zone C - Machines', 'icon': 'fitness_center'},
    {'id': 'eq_16', 'name': 'Calf Raise Machine', 'category': 'legs', 'zone': 'Zone C - Machines', 'icon': 'fitness_center'},
    // Shoulders
    {'id': 'eq_17', 'name': 'Shoulder Press Machine', 'category': 'shoulders', 'zone': 'Zone C - Machines', 'icon': 'fitness_center'},
    {'id': 'eq_18', 'name': 'Lateral Raise Machine', 'category': 'shoulders', 'zone': 'Zone C - Machines', 'icon': 'fitness_center'},
    // Arms
    {'id': 'eq_19', 'name': 'Preacher Curl Bench', 'category': 'arms', 'zone': 'Zone A - Free Weights', 'icon': 'fitness_center'},
    {'id': 'eq_20', 'name': 'Tricep Pushdown Cable', 'category': 'arms', 'zone': 'Zone B - Cables', 'icon': 'fitness_center'},
    // Compound
    {'id': 'eq_21', 'name': 'Smith Machine', 'category': 'compound', 'zone': 'Zone A - Free Weights', 'icon': 'fitness_center'},
    {'id': 'eq_22', 'name': 'Deadlift Platform', 'category': 'compound', 'zone': 'Zone A - Free Weights', 'icon': 'fitness_center'},
    // Cardio
    {'id': 'eq_23', 'name': 'Treadmill #1', 'category': 'cardio', 'zone': 'Zone E - Cardio', 'icon': 'directions_run'},
    {'id': 'eq_24', 'name': 'Treadmill #2', 'category': 'cardio', 'zone': 'Zone E - Cardio', 'icon': 'directions_run'},
    {'id': 'eq_25', 'name': 'Treadmill #3', 'category': 'cardio', 'zone': 'Zone E - Cardio', 'icon': 'directions_run'},
    {'id': 'eq_26', 'name': 'Elliptical #1', 'category': 'cardio', 'zone': 'Zone E - Cardio', 'icon': 'directions_run'},
    {'id': 'eq_27', 'name': 'Stationary Bike #1', 'category': 'cardio', 'zone': 'Zone E - Cardio', 'icon': 'pedal_bike'},
    {'id': 'eq_28', 'name': 'Stationary Bike #2', 'category': 'cardio', 'zone': 'Zone E - Cardio', 'icon': 'pedal_bike'},
    {'id': 'eq_29', 'name': 'Rowing Machine', 'category': 'cardio', 'zone': 'Zone E - Cardio', 'icon': 'rowing'},
    {'id': 'eq_30', 'name': 'Stair Climber', 'category': 'cardio', 'zone': 'Zone E - Cardio', 'icon': 'stairs'},
  ];

  // ── Realistic Occupancy Pattern (by hour) ─────────────────────────────────
  // Based on real gym data: peaks at 7 AM and 5-7 PM
  static const Map<int, double> _weekdayPattern = {
    0: 0.02, 1: 0.02, 2: 0.02, 3: 0.02, 4: 0.05,
    5: 0.18, 6: 0.42, 7: 0.65, 8: 0.52, 9: 0.38,
    10: 0.32, 11: 0.28, 12: 0.45, 13: 0.40, 14: 0.30,
    15: 0.38, 16: 0.58, 17: 0.82, 18: 0.90, 19: 0.78,
    20: 0.60, 21: 0.42, 22: 0.22, 23: 0.08,
  };

  static const Map<int, double> _weekendPattern = {
    0: 0.02, 1: 0.02, 2: 0.02, 3: 0.02, 4: 0.03,
    5: 0.05, 6: 0.10, 7: 0.20, 8: 0.35, 9: 0.52,
    10: 0.62, 11: 0.58, 12: 0.50, 13: 0.45, 14: 0.40,
    15: 0.38, 16: 0.42, 17: 0.48, 18: 0.40, 19: 0.30,
    20: 0.22, 21: 0.15, 22: 0.08, 23: 0.04,
  };

  /// Get base occupancy for a given hour and day.
  static double _getBaseOccupancy(int hour, {bool isWeekend = false}) {
    final pattern = isWeekend ? _weekendPattern : _weekdayPattern;
    return pattern[hour] ?? 0.05;
  }

  /// Get crowd level label from occupancy percentage.
  static String _getCrowdLevel(double occupancy) {
    if (occupancy < 0.20) return 'empty';
    if (occupancy < 0.40) return 'light';
    if (occupancy < 0.60) return 'moderate';
    if (occupancy < 0.80) return 'busy';
    return 'packed';
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Generate a full gym occupancy snapshot based on current time.
  /// Equipment statuses are randomized weighted by the time-based occupancy.
  static GymOccupancy generateOccupancy({DateTime? overrideTime}) {
    final now = overrideTime ?? DateTime.now();
    final isWeekend = now.weekday >= 6;
    final baseOccupancy = _getBaseOccupancy(now.hour, isWeekend: isWeekend);

    // Add ±5% jitter for realism
    final jitter = (_random.nextDouble() * 0.10) - 0.05;
    final occupancy = (baseOccupancy + jitter).clamp(0.05, 0.95);

    // Generate equipment statuses weighted by occupancy
    final equipment = _equipmentDb.map((eq) {
      final roll = _random.nextDouble();
      EquipmentStatus status;
      DateTime? occupiedSince;
      int avgWait = 0;

      if (roll < occupancy * 0.75) {
        // Occupied — probability scales with gym busyness
        status = EquipmentStatus.occupied;
        occupiedSince = now.subtract(Duration(minutes: 1 + _random.nextInt(20)));
        avgWait = 3 + _random.nextInt(12);
      } else if (roll > 0.97) {
        // 3% chance of maintenance
        status = EquipmentStatus.maintenance;
      } else {
        status = EquipmentStatus.available;
      }

      return GymEquipment(
        id: eq['id']!,
        name: eq['name']!,
        category: eq['category']!,
        zone: eq['zone']!,
        status: status,
        occupiedSince: occupiedSince,
        avgWaitMinutes: avgWait,
        icon: eq['icon']!,
      );
    }).toList();

    final totalCapacity = 80;
    final currentCount = (totalCapacity * occupancy).round();

    return GymOccupancy(
      gymId: 'gym_planb_001',
      gymName: 'PlanB Fitness Hub',
      totalCapacity: totalCapacity,
      currentCount: currentCount,
      occupancyPercent: occupancy,
      crowdLevel: _getCrowdLevel(occupancy),
      equipment: equipment,
      lastUpdated: now,
    );
  }

  /// Simulate a small status change (1-3 machines flip status).
  /// Used for "live" demo updates every 15-30 seconds.
  static GymOccupancy applySmallChange(GymOccupancy current) {
    final updatedEquipment = List<GymEquipment>.from(current.equipment);
    final changesToMake = 1 + _random.nextInt(3); // 1-3 changes

    for (int i = 0; i < changesToMake; i++) {
      final idx = _random.nextInt(updatedEquipment.length);
      final eq = updatedEquipment[idx];

      if (eq.status == EquipmentStatus.maintenance) continue; // don't flip maintenance

      if (eq.status == EquipmentStatus.occupied) {
        // 40% chance to become available
        if (_random.nextDouble() < 0.4) {
          updatedEquipment[idx] = eq.copyWith(
            status: EquipmentStatus.available,
            avgWaitMinutes: 0,
          );
        }
      } else {
        // 30% chance to become occupied
        if (_random.nextDouble() < 0.3) {
          updatedEquipment[idx] = eq.copyWith(
            status: EquipmentStatus.occupied,
            occupiedSince: DateTime.now(),
            avgWaitMinutes: 3 + _random.nextInt(10),
          );
        }
      }
    }

    // Recalculate counts
    final occupiedCount =
        updatedEquipment.where((e) => e.status == EquipmentStatus.occupied).length;
    final newOccupancy = occupiedCount / updatedEquipment.length;
    final newCount = (current.totalCapacity * newOccupancy).round();

    return GymOccupancy(
      gymId: current.gymId,
      gymName: current.gymName,
      totalCapacity: current.totalCapacity,
      currentCount: newCount,
      occupancyPercent: newOccupancy,
      crowdLevel: _getCrowdLevel(newOccupancy),
      equipment: updatedEquipment,
      lastUpdated: DateTime.now(),
    );
  }

  /// Generate a full week of hourly predictions.
  static List<DayPrediction> generateWeekPredictions() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // 0 = Monday

    return List.generate(7, (dayIndex) {
      final isWeekend = dayIndex >= 5;
      final isToday = dayIndex == todayIndex;

      final hourly = List.generate(19, (i) {
        // 5 AM to 11 PM
        final hour = i + 5;
        final base = _getBaseOccupancy(hour, isWeekend: isWeekend);
        // Add slight daily variation
        final dayJitter = (_random.nextDouble() * 0.06) - 0.03;
        final occupancy = (base + dayJitter).clamp(0.02, 0.95);

        return HourlyPrediction(
          hour: hour,
          occupancy: occupancy,
          label: _formatHour(hour),
          isNow: isToday && hour == now.hour,
        );
      });

      // Find best and worst hours
      final bestHour = hourly.reduce((a, b) => a.occupancy < b.occupancy ? a : b).hour;
      final worstHour = hourly.reduce((a, b) => a.occupancy > b.occupancy ? a : b).hour;

      return DayPrediction(
        dayName: days[dayIndex],
        dayIndex: dayIndex,
        hourly: hourly,
        bestHour: bestHour,
        worstHour: worstHour,
        isToday: isToday,
      );
    });
  }

  /// Format hour as "5 AM", "12 PM", etc.
  static String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}
