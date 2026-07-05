import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../models/workout_routine.dart';
import '../../providers/user_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/plan_b_provider.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/xp_streak_bar.dart';
import '../plan_b/plan_b_screen.dart';
import '../routine/routine_input_screen.dart';
import '../routine/routine_edit_screen.dart';
import '../gym/gym_dashboard_screen.dart';
import '../routine/ai_routine_generator_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final routineProvider = context.watch<RoutineProvider>();

    final profile = userProvider.profile;
    final routine = routineProvider.routine;
    final todaysWorkout = routine.todaysWorkout;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: _PremiumLogo(),
        actions: [
          _GlassIconButton(
            icon: Icons.sensors_rounded,
            color: AppTheme.accentGreen,
            tooltip: 'Gym Status',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GymDashboardScreen()),
            ),
          ),
          _GlassIconButton(
            icon: Icons.fitness_center_outlined,
            tooltip: 'Edit Routine',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoutineEditScreen()),
            ),
          ),
          _GlassIconButton(
            icon: Icons.add_chart_outlined,
            tooltip: 'Add Routine',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoutineInputScreen()),
            ),
          ),
          _GlassIconButton(
            icon: Icons.emoji_events_outlined,
            color: AppTheme.accentOrange,
            tooltip: 'Profile',
            onPressed: () => _showProfileSheet(context, userProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: _PremiumFAB(
        onPressed: () => _showQuickPlanBDialog(context),
      ),

      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: XpStreakBar(profile: profile),
          ),

          if (!routineProvider.hasRoutine)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _QuickStartSection(),
            ),

          if (todaysWorkout != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WorkoutDayHeader(day: todaysWorkout, routine: routine),
                      const SizedBox(height: 24),

                      ...todaysWorkout.exercises.asMap().entries.map((entry) {
                        int i = entry.key;
                        Exercise exercise = entry.value;
                        return _ExerciseCard(
                          key: ValueKey(exercise.id),
                          exercise: exercise,
                          dayId: todaysWorkout.id,
                          index: i,
                        )
                            .animate()
                            .fadeIn(
                          delay: Duration(milliseconds: 60 * i),
                          duration: 350.ms,
                        )
                            .slideY(begin: 0.08);
                      }),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      bottomNavigationBar: todaysWorkout != null
          ? _BottomCompleteBar(day: todaysWorkout)
          : null,
    );
  }

  void _showProfileSheet(BuildContext context, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _ProfileSheet(profile: userProvider.profile),
    );
  }
}

// ── Premium Logo ─────────────────────────────────────────────────────────────
class _PremiumLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: 36,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.planBGradient.createShader(bounds),
            child: Text(
              'PLAN',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Text(
            'B',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.accentGreen,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            ' FIT',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass Icon Button ────────────────────────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String tooltip;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color ?? AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Premium FAB ──────────────────────────────────────────────────────────────
class _PremiumFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _PremiumFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.neonPurpleGlow(intensity: 0.35),
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: AppTheme.accentPurple,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.bolt, color: Colors.white, size: 20),
        label: Text(
          'Quick Plan B',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Quick Plan B Dialog ──────────────────────────────────────────────────────
Future<void> _showQuickPlanBDialog(BuildContext context) async {
  final TextEditingController controller = TextEditingController();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentPurple.withOpacity(0.2),
                          AppTheme.accentPurple.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentPurple.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(Icons.bolt,
                        color: AppTheme.accentPurple, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Plan B',
                        style: GoogleFonts.orbitron(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Machine busy? Get an alternative!',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextField(
                controller: controller,
                style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Which machine is occupied? (e.g. Lat Pulldown)',
                  prefixIcon: const Icon(Icons.search,
                      color: AppTheme.textMuted, size: 20),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.neonPurpleGlow(intensity: 0.25),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter an exercise name')),
                      );
                      return;
                    }

                    final targetExercise = Exercise(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: controller.text.trim(),
                      muscleGroup: 'Target Muscle',
                      sets: 3,
                      reps: 10,
                    );

                    Navigator.pop(context);

                    context
                        .read<PlanBProvider>()
                        .setTargetExercise(targetExercise);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlanBScreen(
                          exercise: targetExercise,
                          dayId: 'quick_plan_b_day',
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'ACTIVATE AI',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    },
  );
}

// ── Today's workout header ──────────────────────────────────────────────────
class _WorkoutDayHeader extends StatelessWidget {
  final WorkoutDay day;
  final WorkoutRoutine routine;
  const _WorkoutDayHeader({required this.day, required this.routine});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TODAY',
                      style: GoogleFonts.poppins(
                        color: AppTheme.accentPurple,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day.dayName,
                    style: GoogleFonts.orbitron(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple.withOpacity(0.15),
                    AppTheme.accentPurple.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.accentPurple.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Day ${routine.currentDayIndex + 1} / ${routine.days.length}',
                style: GoogleFonts.poppins(
                  color: AppTheme.accentPurple,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${day.completedCount} / ${day.totalCount} exercises',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${(day.progress * 100).round()}%',
                style: GoogleFonts.orbitron(
                  color: AppTheme.accentGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Gradient progress bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.divider,
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * day.progress,
                      decoration: BoxDecoration(
                        gradient: AppTheme.planBGradient,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGreen.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Exercise card ─────────────────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final String dayId;
  final int index;

  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.dayId,
    required this.index,
  });

  Color _borderColor() {
    if (exercise.usedPlanB) return AppTheme.accentPurple.withOpacity(0.5);
    if (exercise.isCompleted) return AppTheme.accentGreen.withOpacity(0.5);
    return Colors.white.withOpacity(0.06);
  }

  Color? _glowColor() {
    if (exercise.usedPlanB) return AppTheme.accentPurple;
    if (exercise.isCompleted) return AppTheme.accentGreen;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final routineProvider = context.read<RoutineProvider>();
    final userProvider = context.read<UserProvider>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(), width: 1.5),
        boxShadow: _glowColor() != null
            ? [
                BoxShadow(
                  color: _glowColor()!.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 12),
                  child: _StatusIcon(exercise: exercise),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: GoogleFonts.poppins(
                          color: exercise.isCompleted
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration: exercise.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _MuscleTag(exercise.muscleGroup),
                          const SizedBox(width: 10),
                          Text(
                            '${exercise.sets} sets × ${exercise.reps} reps',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // ── Live Occupancy Badge ──
                      if (!exercise.isCompleted)
                        Builder(
                          builder: (context) {
                            final gymProvider = context.watch<GymProvider>();
                            final availability = gymProvider.isEquipmentAvailable(exercise.name);
                            if (availability == null) return const SizedBox.shrink();
                            final isFree = availability;
                            final equipment = gymProvider.findEquipmentForExercise(exercise.name);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isFree
                                      ? AppTheme.accentGreen.withOpacity(0.08)
                                      : AppTheme.accentOrange.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isFree
                                        ? AppTheme.accentGreen.withOpacity(0.3)
                                        : AppTheme.accentOrange.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: isFree ? AppTheme.accentGreen : AppTheme.accentOrange,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isFree ? AppTheme.accentGreen : AppTheme.accentOrange).withOpacity(0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isFree ? 'MACHINE FREE' : 'MACHINE BUSY',
                                      style: GoogleFonts.orbitron(
                                        color: isFree ? AppTheme.accentGreen : AppTheme.accentOrange,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (!isFree && equipment != null && equipment.avgWaitMinutes > 0) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '~${equipment.avgWaitMinutes}m wait',
                                        style: GoogleFonts.poppins(
                                          color: AppTheme.accentOrange,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      if (exercise.usedPlanB)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    AppTheme.accentPurple.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt,
                                    size: 12,
                                    color: AppTheme.accentPurple),
                                const SizedBox(width: 4),
                                Text(
                                  'Plan B alternative',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.accentPurple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (!exercise.isCompleted) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.accentGreen.withOpacity(0.4),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await routineProvider.markExerciseComplete(
                                dayId, exercise.id);
                            await userProvider.awardExerciseXP();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.black87, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+10 XP',
                                        style: GoogleFonts.orbitron(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: AppTheme.accentGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check,
                                    size: 15,
                                    color: AppTheme.accentGreen),
                                const SizedBox(width: 6),
                                Text(
                                  'Done  +10 XP',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.accentGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentPurple.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<PlanBProvider>()
                            .setTargetExercise(exercise);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlanBScreen(
                              exercise: exercise,
                              dayId: dayId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bolt, size: 16),
                      label: Text(
                        'Plan B',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Bottom complete workout bar ───────────────────────────────────────────────
class _BottomCompleteBar extends StatelessWidget {
  final WorkoutDay day;
  const _BottomCompleteBar({required this.day});

  @override
  Widget build(BuildContext context) {
    final allDone = day.isCompleted;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.background.withOpacity(0.9),
            AppTheme.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allDone)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'All exercises complete!',
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
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: allDone
                  ? AppTheme.neonOrangeGlow(intensity: 0.3)
                  : null,
            ),
            child: ElevatedButton.icon(
              onPressed: allDone
                  ? () async {
                      final userProvider = context.read<UserProvider>();
                      final routineProvider =
                          context.read<RoutineProvider>();
                      await userProvider.awardWorkoutCompleteXP();
                      await routineProvider.advanceDay();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Text('🔥',
                                    style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  'Workout complete! +50 XP | Streak updated!',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppTheme.accentOrange,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    }
                  : null,
              icon: Icon(Icons.emoji_events,
                  size: 20,
                  color: allDone ? Colors.black87 : AppTheme.textMuted),
              label: Text(
                allDone ? 'COMPLETE WORKOUT  +50 XP' : 'COMPLETE WORKOUT',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    allDone ? AppTheme.accentOrange : AppTheme.divider,
                foregroundColor:
                    allDone ? Colors.black87 : AppTheme.textMuted,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick-start section (no routine yet) ─────────────────────────────────────
class _QuickStartSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple.withOpacity(0.15),
                    AppTheme.accentGreen.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.accentPurple.withOpacity(0.3),
                ),
              ),
              child: const Center(
                child: Text('🏋️', style: TextStyle(fontSize: 36)),
              ),
            ).animate().scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 20),
            Text(
              'No routine yet',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Let AI build your perfect routine, load a default,\nor create your own.',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ── AI Routine Generator CTA (Primary) ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.neonPurpleGlow(intensity: 0.3),
              ),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AIRoutineGeneratorScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: Text(
                  'ASK AI FOR A ROUTINE',
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Load Default PPL ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.neonGreenGlow(intensity: 0.2),
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await context.read<RoutineProvider>().loadDefaultPPL();
                },
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text('LOAD DEFAULT PPL'),
              ),
            ),
            const SizedBox(height: 14),

            // ── Build Custom Routine ──
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RoutineInputScreen()),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Build Custom Routine'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile bottom sheet ──────────────────────────────────────────────────────
class _ProfileSheet extends StatelessWidget {
  final UserProfile profile;
  const _ProfileSheet({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.planBGradient,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.rank,
                        style: GoogleFonts.poppins(
                          color: AppTheme.accentPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            _InfoRow('Level', '${profile.level}'),
            _InfoRow('Total XP', '${profile.xp}'),
            _InfoRow('Streak', '${profile.streak} days 🔥'),
            _InfoRow('Fitness Level', profile.fitnessLevel),
            if (profile.injuries.isNotEmpty)
              _InfoRow('Injuries', profile.injuries.join(', ')),
            const SizedBox(height: 20),
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
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RoutineEditScreen()),
                );
              },
              icon: const Icon(Icons.edit_note_outlined, size: 18),
              label: const Text('View & Edit My Routines'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final Exercise exercise;
  const _StatusIcon({required this.exercise});

  @override
  Widget build(BuildContext context) {
    if (exercise.usedPlanB) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.accentPurple.withOpacity(0.15),
          border: Border.all(
            color: AppTheme.accentPurple.withOpacity(0.5),
          ),
        ),
        child: const Icon(Icons.bolt, color: AppTheme.accentPurple, size: 14),
      );
    }
    if (exercise.isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.accentGreen.withOpacity(0.15),
          border: Border.all(
            color: AppTheme.accentGreen.withOpacity(0.5),
          ),
        ),
        child:
            const Icon(Icons.check, color: AppTheme.accentGreen, size: 14),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(color: AppTheme.divider, width: 1.5),
      ),
    );
  }
}

class _MuscleTag extends StatelessWidget {
  final String muscle;
  const _MuscleTag(this.muscle);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGreen.withOpacity(0.12),
            AppTheme.accentGreen.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.accentGreen.withOpacity(0.25),
        ),
      ),
      child: Text(
        muscle,
        style: GoogleFonts.poppins(
          color: AppTheme.accentGreen,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
