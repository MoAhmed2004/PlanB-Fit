/// ═══════════════════════════════════════════════════════════════════════════════
/// Gym Equipment & Occupancy Models
/// Used for real-time gym status display and equipment availability tracking.
/// ═══════════════════════════════════════════════════════════════════════════════

/// Status of a single piece of gym equipment.
enum EquipmentStatus { available, occupied, maintenance }

/// Represents a single piece of gym equipment with its current status.
class GymEquipment {
  final String id;
  final String name;
  final String category; // 'chest', 'back', 'legs', 'shoulders', 'arms', 'cardio', 'compound'
  final String zone; // 'Zone A - Free Weights', 'Zone B - Machines', etc.
  final EquipmentStatus status;
  final DateTime? occupiedSince;
  final int avgWaitMinutes; // estimated wait time if occupied
  final String icon; // Material icon name hint for UI

  const GymEquipment({
    required this.id,
    required this.name,
    required this.category,
    required this.zone,
    required this.status,
    this.occupiedSince,
    this.avgWaitMinutes = 0,
    this.icon = 'fitness_center',
  });

  /// Whether this equipment is currently free to use.
  bool get isFree => status == EquipmentStatus.available;

  /// Whether this equipment is currently in use.
  bool get isBusy => status == EquipmentStatus.occupied;

  /// How long this equipment has been occupied (null if not occupied).
  Duration? get occupiedDuration =>
      occupiedSince != null ? DateTime.now().difference(occupiedSince!) : null;

  /// Create a copy with updated status (used by fake data refresh).
  GymEquipment copyWith({
    EquipmentStatus? status,
    DateTime? occupiedSince,
    int? avgWaitMinutes,
  }) {
    return GymEquipment(
      id: id,
      name: name,
      category: category,
      zone: zone,
      status: status ?? this.status,
      occupiedSince: occupiedSince ?? this.occupiedSince,
      avgWaitMinutes: avgWaitMinutes ?? this.avgWaitMinutes,
      icon: icon,
    );
  }
}

/// Overall gym occupancy snapshot.
class GymOccupancy {
  final String gymId;
  final String gymName;
  final int totalCapacity;
  final int currentCount;
  final double occupancyPercent; // 0.0 - 1.0
  final String crowdLevel; // 'empty', 'light', 'moderate', 'busy', 'packed'
  final List<GymEquipment> equipment;
  final DateTime lastUpdated;

  const GymOccupancy({
    required this.gymId,
    required this.gymName,
    required this.totalCapacity,
    required this.currentCount,
    required this.occupancyPercent,
    required this.crowdLevel,
    required this.equipment,
    required this.lastUpdated,
  });

  /// Count of available equipment.
  int get availableCount =>
      equipment.where((e) => e.status == EquipmentStatus.available).length;

  /// Count of occupied equipment.
  int get occupiedCount =>
      equipment.where((e) => e.status == EquipmentStatus.occupied).length;

  /// Count of equipment under maintenance.
  int get maintenanceCount =>
      equipment.where((e) => e.status == EquipmentStatus.maintenance).length;

  /// Equipment filtered by category.
  List<GymEquipment> byCategory(String category) =>
      equipment.where((e) => e.category == category).toList();
}

/// Hourly occupancy prediction for the "Best Time to Go" chart.
class HourlyPrediction {
  final int hour; // 0-23
  final double occupancy; // 0.0 - 1.0
  final String label; // "5 AM", "6 PM"
  final bool isNow; // highlight current hour

  const HourlyPrediction({
    required this.hour,
    required this.occupancy,
    required this.label,
    this.isNow = false,
  });

  /// Crowd level string for this hour.
  String get crowdLevel {
    if (occupancy < 0.2) return 'empty';
    if (occupancy < 0.4) return 'light';
    if (occupancy < 0.6) return 'moderate';
    if (occupancy < 0.8) return 'busy';
    return 'packed';
  }
}

/// Full day prediction containing hourly data.
class DayPrediction {
  final String dayName; // 'Monday', 'Tuesday', etc.
  final int dayIndex; // 0 = Monday, 6 = Sunday
  final List<HourlyPrediction> hourly;
  final int bestHour; // lowest occupancy hour
  final int worstHour; // highest occupancy hour
  final bool isToday;

  const DayPrediction({
    required this.dayName,
    required this.dayIndex,
    required this.hourly,
    required this.bestHour,
    required this.worstHour,
    this.isToday = false,
  });

  /// The best time formatted as a readable string.
  String get bestTimeLabel {
    final h = bestHour;
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }
}
