import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/workout_routine.dart';
import '../../providers/routine_provider.dart';

/// Full routine editor.
///
/// Shows every workout day as a card.
/// Each exercise row has: Edit (pencil) + Delete (trash) icons.
/// Each day card header has: Rename + Delete day buttons.
/// Floating action button adds a new day.
class RoutineEditScreen extends StatelessWidget {
  const RoutineEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.planBGradient.createShader(bounds),
                child: const Icon(Icons.bolt, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'EDIT ROUTINE',
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<RoutineProvider>(
        builder: (context, provider, _) {
          if (!provider.hasRoutine) {
            return _EmptyState(
              onLoadPPL: () => provider.loadDefaultPPL(),
            );
          }

          final routine = provider.routine;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: routine.days.length,
            itemBuilder: (ctx, i) => _DayCard(
              key: ValueKey(routine.days[i].id),
              day: routine.days[i],
              canDelete: routine.days.length > 1,
            ).animate().fadeIn(
                  delay: Duration(milliseconds: 50 * i),
                  duration: 300.ms,
                ),
          );
        },
      ),

      // ── FAB: add new day
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.neonGreenGlow(intensity: 0.3),
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDayDialog(context),
          backgroundColor: AppTheme.accentGreen,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: Text(
            'ADD DAY',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDayDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('New Workout Day',
            style: GoogleFonts.orbitron(
                fontSize: 16, color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Push Day'),
          style: GoogleFonts.poppins(color: AppTheme.textPrimary),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                context
                    .read<RoutineProvider>()
                    .addWorkoutDay(ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text('Add', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}

// ── Day card ──────────────────────────────────────────────────────────────────
class _DayCard extends StatelessWidget {
  final WorkoutDay day;
  final bool canDelete;

  const _DayCard({super.key, required this.day, required this.canDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Day header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.planBGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Text(
                    day.dayName,
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                // Rename day
                _HeaderIconButton(
                  icon: Icons.edit_outlined,
                  color: AppTheme.textSecondary,
                  tooltip: 'Rename day',
                  onPressed: () => _showRenameDayDialog(context),
                ),
                // Delete day
                if (canDelete)
                  _HeaderIconButton(
                    icon: Icons.delete_outline,
                    color: AppTheme.errorColor,
                    tooltip: 'Delete day',
                    onPressed: () => _confirmDeleteDay(context),
                  ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.divider,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ── Exercise rows
          if (day.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'No exercises yet — tap + to add one.',
                style: GoogleFonts.poppins(
                    color: AppTheme.textMuted, fontSize: 13),
              ),
            )
          else
            ...day.exercises.asMap().entries.map((entry) {
              final ex = entry.value;
              final isLast = entry.key == day.exercises.length - 1;
              return _ExerciseRow(
                exercise: ex,
                dayId: day.id,
                showDivider: !isLast,
              );
            }),

          // ── Add exercise row
          InkWell(
            onTap: () => _showAddExerciseSheet(context),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(18)),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentGreen.withOpacity(0.2),
                          AppTheme.accentGreen.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.accentGreen.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(Icons.add,
                        size: 16, color: AppTheme.accentGreen),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add exercise',
                    style: GoogleFonts.poppins(
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDayDialog(BuildContext context) {
    final ctrl = TextEditingController(text: day.dayName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Day',
            style: GoogleFonts.orbitron(
                fontSize: 16, color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Day name'),
          style: GoogleFonts.poppins(color: AppTheme.textPrimary),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              context
                  .read<RoutineProvider>()
                  .updateDayName(day.id, ctrl.text);
              Navigator.pop(context);
            },
            child: Text('Save', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDay(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete "${day.dayName}"?',
            style: GoogleFonts.poppins(
                color: AppTheme.textPrimary, fontSize: 16)),
        content: Text(
          'This removes the day and all its exercises.',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              context.read<RoutineProvider>().removeDay(day.id);
              Navigator.pop(context);
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ExerciseEditSheet(
        dayId: day.id,
        exercise: null,
      ),
    );
  }
}

// ── Header icon button ───────────────────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 17, color: color),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      ),
    );
  }
}

// ── Single exercise row ───────────────────────────────────────────────────────
class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  final String dayId;
  final bool showDivider;

  const _ExerciseRow({
    required this.exercise,
    required this.dayId,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              // Neon bullet dot
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 12, top: 1),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGreen.withOpacity(0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _Chip(exercise.muscleGroup, AppTheme.accentGreen),
                        const SizedBox(width: 8),
                        Text(
                          '${exercise.sets} sets × ${exercise.reps} reps',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit icon
              _HeaderIconButton(
                icon: Icons.edit_outlined,
                color: AppTheme.textSecondary,
                tooltip: 'Edit exercise',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.cardColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => _ExerciseEditSheet(
                    dayId: dayId,
                    exercise: exercise,
                  ),
                ),
              ),

              // Delete icon
              _HeaderIconButton(
                icon: Icons.delete_outline,
                color: AppTheme.errorColor,
                tooltip: 'Remove exercise',
                onPressed: () {
                  context
                      .read<RoutineProvider>()
                      .removeExercise(dayId, exercise.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      'Removed "${exercise.name}"',
                      style: GoogleFonts.poppins(),
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    action: SnackBarAction(
                      label: 'OK',
                      onPressed: () {},
                    ),
                  ));
                },
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 38, right: 16),
            color: AppTheme.divider.withOpacity(0.5),
          ),
      ],
    );
  }
}

// ── Exercise edit / add bottom sheet ─────────────────────────────────────────
class _ExerciseEditSheet extends StatefulWidget {
  final String dayId;
  final Exercise? exercise;

  const _ExerciseEditSheet({required this.dayId, required this.exercise});

  @override
  State<_ExerciseEditSheet> createState() => _ExerciseEditSheetState();
}

class _ExerciseEditSheetState extends State<_ExerciseEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _muscleCtrl;
  late int _sets;
  late int _reps;

  bool get _isEdit => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.exercise?.name ?? '');
    _muscleCtrl =
        TextEditingController(text: widget.exercise?.muscleGroup ?? '');
    _sets = widget.exercise?.sets ?? 3;
    _reps = widget.exercise?.reps ?? 10;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _muscleCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final provider = context.read<RoutineProvider>();

    if (_isEdit) {
      provider.updateExercise(
        widget.dayId,
        widget.exercise!.copyWith(
          name: _nameCtrl.text.trim(),
          muscleGroup: _muscleCtrl.text.trim().isEmpty
              ? 'General'
              : _muscleCtrl.text.trim(),
          sets: _sets,
          reps: _reps,
        ),
      );
    } else {
      provider.addExerciseToDay(
        widget.dayId,
        Exercise(
          name: _nameCtrl.text.trim(),
          muscleGroup: _muscleCtrl.text.trim().isEmpty
              ? 'General'
              : _muscleCtrl.text.trim(),
          sets: _sets,
          reps: _reps,
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 28 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            _isEdit ? 'Edit Exercise' : 'Add Exercise',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 20),

          // Exercise name
          _SheetLabel('Exercise Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            autofocus: !_isEdit,
            decoration:
                const InputDecoration(hintText: 'e.g. Barbell Squat'),
            style: GoogleFonts.poppins(color: AppTheme.textPrimary),
            textCapitalization: TextCapitalization.words,
          ),

          const SizedBox(height: 16),

          // Muscle group
          _SheetLabel('Muscle Group'),
          const SizedBox(height: 8),
          TextField(
            controller: _muscleCtrl,
            decoration:
                const InputDecoration(hintText: 'e.g. Quads / Glutes'),
            style: GoogleFonts.poppins(color: AppTheme.textPrimary),
            textCapitalization: TextCapitalization.words,
          ),

          const SizedBox(height: 20),

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
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.neonGreenGlow(intensity: 0.2),
            ),
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(_isEdit ? Icons.check : Icons.add),
              label: Text(
                _isEdit ? 'Save Changes' : 'Add Exercise',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onLoadPPL;
  const _EmptyState({required this.onLoadPPL});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple.withOpacity(0.15),
                    AppTheme.accentGreen.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.accentGreen.withOpacity(0.2),
                ),
              ),
              child: const Icon(Icons.fitness_center,
                  color: AppTheme.accentGreen, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'No routine yet',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Load the default PPL or add a day.',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.neonGreenGlow(intensity: 0.25),
              ),
              child: ElevatedButton.icon(
                onPressed: onLoadPPL,
                icon: const Icon(Icons.bolt, size: 18),
                label: Text(
                  'LOAD DEFAULT PPL',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.12),
              color.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Text(text,
            style: GoogleFonts.poppins(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(
          color: AppTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      );
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min, max;

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
