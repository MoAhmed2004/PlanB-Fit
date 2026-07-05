import 'package:uuid/uuid.dart';

// ── Exercise ──────────────────────────────────────────────────────────────────
class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final int    sets;
  final int    reps;
  final bool   isCompleted;
  final bool   usedPlanB;      // true if this was swapped via Plan B today

  Exercise({
    String? id,
    required this.name,
    required this.muscleGroup,
    this.sets        = 3,
    this.reps        = 10,
    this.isCompleted = false,
    this.usedPlanB   = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id'          : id,
    'name'        : name,
    'muscleGroup' : muscleGroup,
    'sets'        : sets,
    'reps'        : reps,
    'isCompleted' : isCompleted,
    'usedPlanB'   : usedPlanB,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id          : json['id']          as String? ?? const Uuid().v4(),
    name        : json['name']        as String? ?? 'Unknown Exercise',
    muscleGroup : json['muscleGroup'] as String? ?? 'Full Body',
    sets        : json['sets']        as int?    ?? 3,
    reps        : json['reps']        as int?    ?? 10,
    isCompleted : json['isCompleted'] as bool?   ?? false,
    usedPlanB   : json['usedPlanB']   as bool?   ?? false,
  );

  Exercise copyWith({
    String? name,
    String? muscleGroup,
    int?    sets,
    int?    reps,
    bool?   isCompleted,
    bool?   usedPlanB,
  }) =>
      Exercise(
        id          : id,
        name        : name        ?? this.name,
        muscleGroup : muscleGroup ?? this.muscleGroup,
        sets        : sets        ?? this.sets,
        reps        : reps        ?? this.reps,
        isCompleted : isCompleted ?? this.isCompleted,
        usedPlanB   : usedPlanB   ?? this.usedPlanB,
      );
}

// ── WorkoutDay ────────────────────────────────────────────────────────────────
class WorkoutDay {
  final String         id;
  final String         dayName;    // e.g. 'Push 💪'
  final List<Exercise> exercises;
  final bool           isRestDay;

  WorkoutDay({
    String?        id,
    required this.dayName,
    List<Exercise>? exercises,
    this.isRestDay = false,
  })  : id        = id ?? const Uuid().v4(),
        exercises = exercises ?? [];

  int    get completedCount => exercises.where((e) => e.isCompleted).length;
  int    get totalCount     => exercises.length;
  bool   get isCompleted    => totalCount > 0 && completedCount == totalCount;
  double get progress       => totalCount == 0 ? 0 : completedCount / totalCount;

  Map<String, dynamic> toJson() => {
    'id'        : id,
    'dayName'   : dayName,
    'exercises' : exercises.map((e) => e.toJson()).toList(),
    'isRestDay' : isRestDay,
  };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => WorkoutDay(
    id        : json['id']      as String?,
    dayName   : json['dayName'] as String? ?? 'Workout',
    exercises : (json['exercises'] as List? ?? [])
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList(),
    isRestDay : json['isRestDay'] as bool? ?? false,
  );

  WorkoutDay copyWith({String? dayName, List<Exercise>? exercises}) =>
      WorkoutDay(
        id        : id,
        dayName   : dayName    ?? this.dayName,
        exercises : exercises  ?? this.exercises,
        isRestDay : isRestDay,
      );
}

// ── WorkoutRoutine ────────────────────────────────────────────────────────────
class WorkoutRoutine {
  final String         routineName;
  final List<WorkoutDay> days;
  final int            currentDayIndex;

  const WorkoutRoutine({
    this.routineName     = 'My Routine',
    this.days            = const [],
    this.currentDayIndex = 0,
  });

  WorkoutDay? get todaysWorkout =>
      days.isEmpty ? null : days[currentDayIndex % days.length];

  Map<String, dynamic> toJson() => {
    'routineName'     : routineName,
    'days'            : days.map((d) => d.toJson()).toList(),
    'currentDayIndex' : currentDayIndex,
  };

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) => WorkoutRoutine(
    routineName     : json['routineName']     as String? ?? 'My Routine',
    days            : (json['days'] as List? ?? [])
        .map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
        .toList(),
    currentDayIndex : json['currentDayIndex'] as int? ?? 0,
  );

  // ── Pre-built PPL default (instant demo value) ────────────────────────────
  factory WorkoutRoutine.pplDefault() => WorkoutRoutine(
    routineName: 'PPL Routine',
    days: [
      WorkoutDay(dayName: 'Push ', exercises: [
        Exercise(name: 'Barbell Bench Press',  muscleGroup: 'Chest',         sets: 4, reps: 8),
        Exercise(name: 'Overhead Press',       muscleGroup: 'Shoulders',     sets: 3, reps: 10),
        Exercise(name: 'Incline DB Press',     muscleGroup: 'Upper Chest',   sets: 3, reps: 12),
        Exercise(name: 'Lateral Raises',       muscleGroup: 'Side Delts',    sets: 4, reps: 15),
        Exercise(name: 'Tricep Pushdowns',     muscleGroup: 'Triceps',       sets: 3, reps: 12),
      ]),
      WorkoutDay(dayName: 'Pull ️', exercises: [
        Exercise(name: 'Deadlift',             muscleGroup: 'Back',          sets: 4, reps: 6),
        Exercise(name: 'Barbell Rows',         muscleGroup: 'Back',          sets: 4, reps: 8),
        Exercise(name: 'Pull-ups',             muscleGroup: 'Back/Biceps',   sets: 3, reps: 10),
        Exercise(name: 'Face Pulls',           muscleGroup: 'Rear Delts',    sets: 3, reps: 15),
        Exercise(name: 'Bicep Curls',          muscleGroup: 'Biceps',        sets: 3, reps: 12),
      ]),
      WorkoutDay(dayName: 'Legs ', exercises: [
        Exercise(name: 'Barbell Squat',        muscleGroup: 'Quads/Glutes',  sets: 4, reps: 8),
        Exercise(name: 'Romanian Deadlift',    muscleGroup: 'Hamstrings',    sets: 3, reps: 10),
        Exercise(name: 'Leg Press',            muscleGroup: 'Quads',         sets: 3, reps: 12),
        Exercise(name: 'Leg Curls',            muscleGroup: 'Hamstrings',    sets: 3, reps: 12),
        Exercise(name: 'Calf Raises',          muscleGroup: 'Calves',        sets: 4, reps: 20),
      ]),
    ],
  );

  WorkoutRoutine copyWith({
    String?           routineName,
    List<WorkoutDay>? days,
    int?              currentDayIndex,
  }) =>
      WorkoutRoutine(
        routineName     : routineName     ?? this.routineName,
        days            : days            ?? this.days,
        currentDayIndex : currentDayIndex ?? this.currentDayIndex,
      );
}