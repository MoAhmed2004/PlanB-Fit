/// The exact JSON schema ManusAI returns.
///
/// This is the "contract" between the AI prompt and the Flutter UI.
/// The AI service strips markdown fences before parsing.
class PlanBResult {
  final String alternativeExercise;
  final String targetMuscle;
  final int    sets;
  final int    reps;
  final String instructions;
  final String videoSearchQuery;   // used to construct a YouTube search URL

  const PlanBResult({
    required this.alternativeExercise,
    required this.targetMuscle,
    required this.sets,
    required this.reps,
    required this.instructions,
    required this.videoSearchQuery,
  });

  factory PlanBResult.fromJson(Map<String, dynamic> json) => PlanBResult(
    alternativeExercise : json['alternative_exercise'] as String? ?? 'Alternative Exercise',
    targetMuscle        : json['target_muscle']        as String? ?? 'Primary Muscles',
    sets                : json['sets']                 as int?    ?? 3,
    reps                : json['reps']                 as int?    ?? 12,
    instructions        : json['instructions']         as String? ?? 'Perform with proper form.',
    videoSearchQuery    : json['video_search_query']   as String? ?? 'exercise tutorial',
  );

  Map<String, dynamic> toJson() => {
    'alternative_exercise' : alternativeExercise,
    'target_muscle'        : targetMuscle,
    'sets'                 : sets,
    'reps'                 : reps,
    'instructions'         : instructions,
    'video_search_query'   : videoSearchQuery,
  };

  /// Constructs a YouTube search URL from [videoSearchQuery].
  String get youtubeUrl =>
      'https://www.youtube.com/results?search_query=${Uri.encodeComponent(videoSearchQuery)}';

  String get setsRepsLabel => '$sets sets × $reps reps';
}