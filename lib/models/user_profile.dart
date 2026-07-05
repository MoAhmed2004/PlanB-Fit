/// User profile stored locally in SharedPreferences as JSON.
///
/// Gamification contract:
///   • Every 200 XP = 1 level
///   • Consecutive daily workouts increment [streak]
///   • [rank] is a cosmetic label derived from [level]
class UserProfile {
  final String       name;
  final String       fitnessLevel;   // 'Beginner' | 'Intermediate' | 'Advanced'
  final List<String> injuries;       // passed to AI as hard constraints
  final int          xp;
  final int          streak;
  final DateTime?    lastWorkoutDate;

  const UserProfile({
    required this.name,
    this.fitnessLevel       = 'Intermediate',
    this.injuries           = const [],
    this.xp                 = 0,
    this.streak             = 0,
    this.lastWorkoutDate,
  });

  // ── Level & rank ──────────────────────────────────────────────────────────
  static const int _xpPerLevel = 200;

  int    get level             => (xp / _xpPerLevel).floor() + 1;
  int    get xpIntoThisLevel   => xp % _xpPerLevel;
  int    get xpToNextLevel     => _xpPerLevel;
  double get levelProgress     => xpIntoThisLevel / _xpPerLevel;

  String get rank {
    if (level >= 20) return 'LEGEND ⚡';
    if (level >= 15) return 'ELITE 💎';
    if (level >= 10) return 'VETERAN 🔥';
    if (level >=  5) return 'WARRIOR ⚔️';
    return 'ROOKIE 🌱';
  }

  // XP reward values — single source of truth
  static const int xpWorkoutComplete = 50;
  static const int xpPlanBUsed       = 30;
  static const int xpExerciseDone    = 10;

  // ── Serialization ─────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'name'            : name,
    'fitnessLevel'    : fitnessLevel,
    'injuries'        : injuries,
    'xp'              : xp,
    'streak'          : streak,
    'lastWorkoutDate' : lastWorkoutDate?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name             : json['name']         as String? ?? 'Athlete',
    fitnessLevel     : json['fitnessLevel'] as String? ?? 'Intermediate',
    injuries         : List<String>.from(json['injuries'] as List? ?? []),
    xp               : json['xp']           as int?    ?? 0,
    streak           : json['streak']       as int?    ?? 0,
    lastWorkoutDate  : json['lastWorkoutDate'] != null
        ? DateTime.parse(json['lastWorkoutDate'] as String)
        : null,
  );

  factory UserProfile.empty() => const UserProfile(name: '');

  UserProfile copyWith({
    String?       name,
    String?       fitnessLevel,
    List<String>? injuries,
    int?          xp,
    int?          streak,
    DateTime?     lastWorkoutDate,
    bool          clearLastWorkoutDate = false,
  }) {
    return UserProfile(
      name             : name            ?? this.name,
      fitnessLevel     : fitnessLevel    ?? this.fitnessLevel,
      injuries         : injuries        ?? this.injuries,
      xp               : xp              ?? this.xp,
      streak           : streak          ?? this.streak,
      lastWorkoutDate  : clearLastWorkoutDate
          ? null
          : (lastWorkoutDate ?? this.lastWorkoutDate),
    );
  }

  static const List<String> commonInjuries = [
    'Lower Back', 'Knee', 'Shoulder', 'Wrist',
    'Hip', 'Ankle', 'Elbow', 'Neck',
  ];

  static const List<String> fitnessLevels = [
    'Beginner', 'Intermediate', 'Advanced',
  ];
}