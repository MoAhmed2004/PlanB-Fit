import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/workout_routine.dart';
import '../../providers/routine_provider.dart';

class RoutineInputScreen extends StatefulWidget {
  const RoutineInputScreen({super.key});

  @override
  State<RoutineInputScreen> createState() => _RoutineInputScreenState();
}

class _RoutineInputScreenState extends State<RoutineInputScreen> {
  final _dayNameCtrl = TextEditingController();
  final _exNameCtrl = TextEditingController();
  final _muscleCtrl = TextEditingController();
  int _sets = 3;
  int _reps = 10;

  final List<Exercise> _staged = [];

  @override
  void dispose() {
    _dayNameCtrl.dispose();
    _exNameCtrl.dispose();
    _muscleCtrl.dispose();
    super.dispose();
  }

  void _addToStaged() {
    if (_exNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter an exercise name.',
              style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() {
      _staged.add(Exercise(
        name: _exNameCtrl.text.trim(),
        muscleGroup: _muscleCtrl.text.trim().isEmpty
            ? 'General'
            : _muscleCtrl.text.trim(),
        sets: _sets,
        reps: _reps,
      ));
      _exNameCtrl.clear();
      _muscleCtrl.clear();
      _sets = 3;
      _reps = 10;
    });
  }

  Future<void> _saveDay() async {
    if (_dayNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a day name (e.g. Push Day).',
              style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_staged.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Add at least one exercise.',
              style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final routineProvider = context.read<RoutineProvider>();
    routineProvider.addWorkoutDay(_dayNameCtrl.text.trim());
    final dayId = routineProvider.routine.days.last.id;
    for (final ex in _staged) {
      routineProvider.addExerciseToDay(dayId, ex);
    }

    if (mounted) {
      setState(() {
        _staged.clear();
        _dayNameCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.black87, size: 18),
              const SizedBox(width: 8),
              Text(
                'Day saved!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGreen.withOpacity(0.15),
                    AppTheme.accentGreen.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentGreen.withOpacity(0.3),
                ),
              ),
              child: const Icon(Icons.add_chart,
                  color: AppTheme.accentGreen, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'MY ROUTINE',
              style: GoogleFonts.orbitron(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Day name section
            _SectionHeader(
              icon: Icons.calendar_today_outlined,
              title: 'DAY NAME',
              color: AppTheme.accentPurple,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dayNameCtrl,
              style: GoogleFonts.poppins(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Push Day, Legs, Upper Body...',
                prefixIcon: const Icon(Icons.calendar_today_outlined,
                    color: AppTheme.textMuted, size: 18),
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 28),

            // Gradient divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.divider,
                    AppTheme.divider,
                    Colors.transparent,
                  ],
                  stops: const [0, 0.2, 0.8, 1],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Add exercise form
            _SectionHeader(
              icon: Icons.fitness_center,
              title: 'ADD EXERCISE',
              color: AppTheme.accentGreen,
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _exNameCtrl,
              style: GoogleFonts.poppins(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Exercise name  (e.g. Bench Press)',
                prefixIcon: const Icon(Icons.fitness_center,
                    color: AppTheme.textMuted, size: 18),
              ),
            ).animate().fadeIn(delay: 50.ms),

            const SizedBox(height: 12),

            TextField(
              controller: _muscleCtrl,
              style: GoogleFonts.poppins(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Muscle group  (e.g. Chest)',
                prefixIcon: const Icon(Icons.accessibility_new,
                    color: AppTheme.textMuted, size: 18),
              ),
            ).animate().fadeIn(delay: 80.ms),

            const SizedBox(height: 16),

            // Sets / Reps steppers
            Row(
              children: [
                Expanded(
                  child: _Stepper(
                    label: 'Sets',
                    value: _sets,
                    onChanged: (v) => setState(() => _sets = v),
                    min: 1,
                    max: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stepper(
                    label: 'Reps',
                    value: _reps,
                    onChanged: (v) => setState(() => _reps = v),
                    min: 1,
                    max: 50,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: _addToStaged,
              icon: const Icon(Icons.add, size: 16),
              label: Text('Add to Day', style: GoogleFonts.poppins()),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ).animate().fadeIn(delay: 120.ms),

            // ── Staged exercises list
            if (_staged.isNotEmpty) ...[
              const SizedBox(height: 28),
              _SectionHeader(
                icon: Icons.list_alt,
                title: 'EXERCISES IN THIS DAY',
                color: AppTheme.accentOrange,
                trailing: Text(
                  '${_staged.length}',
                  style: GoogleFonts.orbitron(
                    color: AppTheme.accentOrange,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ..._staged.asMap().entries.map(
                    (entry) => _StagedExerciseTile(
                      exercise: entry.value,
                      index: entry.key,
                      onRemove: () =>
                          setState(() => _staged.removeAt(entry.key)),
                    ).animate().fadeIn(
                        delay: Duration(milliseconds: 30 * entry.key)),
                  ),
              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.neonGreenGlow(intensity: 0.2),
                ),
                child: ElevatedButton.icon(
                  onPressed: _saveDay,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    'SAVE "${_dayNameCtrl.text.isEmpty ? "DAY" : _dayNameCtrl.text.toUpperCase()}"',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ).animate().fadeIn(),
            ],

            // ── Existing routine preview
            const SizedBox(height: 36),
            const _ExistingRoutinePreview(),
          ],
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

// ── Existing routine summary ──────────────────────────────────────────────────
class _ExistingRoutinePreview extends StatelessWidget {
  const _ExistingRoutinePreview();

  @override
  Widget build(BuildContext context) {
    final routine = context.watch<RoutineProvider>().routine;
    if (!context.watch<RoutineProvider>().hasRoutine) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.divider,
                AppTheme.divider,
                Colors.transparent,
              ],
              stops: const [0, 0.2, 0.8, 1],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          icon: Icons.view_list_outlined,
          title: 'CURRENT ROUTINE — ${routine.routineName.toUpperCase()}',
          color: AppTheme.accentPurple,
        ),
        const SizedBox(height: 14),
        ...routine.days.map(
          (day) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.planBGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.dayName,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.exercises.length} exercises',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppTheme.cardColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: Text('Remove Day?',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textPrimary)),
                        content: Text(
                            'This will remove "${day.dayName}" and all its exercises.',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context
                                  .read<RoutineProvider>()
                                  .removeDay(day.id);
                            },
                            child: Text('Remove',
                                style: GoogleFonts.poppins(
                                    color: AppTheme.errorColor)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 16, color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stepper widget ───────────────────────────────────────────────────────────
class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: value > min ? () => onChanged(value - 1) : null,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.remove,
                      size: 12,
                      color: value > min
                          ? AppTheme.textPrimary
                          : AppTheme.textMuted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$value',
                    style: GoogleFonts.orbitron(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ),
              GestureDetector(
                onTap: value < max ? () => onChanged(value + 1) : null,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGreen.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child:
                      const Icon(Icons.add, size: 12, color: Colors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Staged exercise tile ─────────────────────────────────────────────────────
class _StagedExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final int index;
  final VoidCallback onRemove;

  const _StagedExerciseTile({
    required this.exercise,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          // Index number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.accentGreen.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.orbitron(
                  color: AppTheme.accentGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exercise.muscleGroup}  •  ${exercise.sets}×${exercise.reps}',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close,
                  size: 14, color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
