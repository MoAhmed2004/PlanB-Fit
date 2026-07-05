import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/plan_b_result.dart';
import '../../models/workout_routine.dart';
import '../../providers/plan_b_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loading/ai_loading_widget.dart';
import '../../widgets/plan_b_result_card.dart';

class PlanBScreen extends StatefulWidget {
  final Exercise exercise;
  final String dayId;
  final Uint8List? imageBytes;

  const PlanBScreen({
    super.key,
    required this.exercise,
    required this.dayId,
    this.imageBytes,
  });

  @override
  State<PlanBScreen> createState() => _PlanBScreenState();
}

class _PlanBScreenState extends State<PlanBScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final planB = context.read<PlanBProvider>();
        planB.setTargetExercise(widget.exercise);

        if (widget.imageBytes != null) {
          planB.setMachineImage(widget.imageBytes);
        }
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1024,
      );
      if (file != null && mounted) {
        final bytes = await file.readAsBytes();
        context.read<PlanBProvider>().setMachineImage(bytes);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access camera/gallery.')),
        );
      }
    }
  }

  Future<void> _triggerAI(PlanBProvider planB) async {
    final userProfile = context.read<UserProvider>().profile;
    await planB.triggerPlanB(userProfile: userProfile);
  }

  Future<void> _markDone(PlanBProvider planB) async {
    await context
        .read<RoutineProvider>()
        .markExercisePlanBComplete(widget.dayId, widget.exercise.id);
    await context.read<UserProvider>().awardPlanBXP();
    planB.reset();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bolt, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Plan B complete!  +30 XP',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.accentPurple,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlanBProvider>(
      builder: (context, planB, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.planBGradient.createShader(bounds),
                  child: Text(
                    'PLAN ',
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  'B',
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
            automaticallyImplyLeading: planB.status != PlanBStatus.loading,
            leading: planB.status != PlanBStatus.loading
                ? null
                : const SizedBox.shrink(),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: planB.status == PlanBStatus.loading
                  ? _LoadingView()
                  : planB.status == PlanBStatus.success && planB.result != null
                      ? _ResultView(
                          result: planB.result!,
                          originalExercise: widget.exercise,
                          onMarkDone: () => _markDone(planB),
                        )
                      : _InputView(
                          planB: planB,
                          exercise: widget.exercise,
                          onPickImage: _pickImage,
                          onTriggerAI: () => _triggerAI(planB),
                        ),
            ),
          ),
        );
      },
    );
  }
}

// ── Input view ────────────────────────────────────────────────────────────────
class _InputView extends StatelessWidget {
  final PlanBProvider planB;
  final Exercise exercise;
  final ValueChanged<ImageSource> onPickImage;
  final VoidCallback onTriggerAI;

  const _InputView({
    required this.planB,
    required this.exercise,
    required this.onPickImage,
    required this.onTriggerAI,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TargetExerciseCard(exercise: exercise)
            .animate()
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.05),

        const SizedBox(height: 28),

        _SectionLabel('BUSY MACHINE PHOTO  (optional)'),
        const SizedBox(height: 12),

        if (planB.machineImage != null) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentPurple.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentPurple.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    planB.machineImage!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () =>
                        context.read<PlanBProvider>().setMachineImage(null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97)),
          const SizedBox(height: 12),
        ],

        Row(
          children: [
            Expanded(
              child: _PhotoButton(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () => onPickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PhotoButton(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () => onPickImage(ImageSource.gallery),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 32),

        _SectionLabel("WHAT'S AVAILABLE RIGHT NOW?"),
        const SizedBox(height: 6),
        Text(
          'Select all that you can reach from here.',
          style: GoogleFonts.poppins(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),

        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: PlanBProvider.equipmentOptions.map((eq) {
            final selected = planB.isEquipmentSelected(eq);
            return GestureDetector(
              onTap: () =>
                  context.read<PlanBProvider>().toggleEquipment(eq),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          colors: [
                            AppTheme.accentGreen.withOpacity(0.15),
                            AppTheme.accentGreen.withOpacity(0.05),
                          ],
                        )
                      : null,
                  color: selected ? null : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppTheme.accentGreen.withOpacity(0.6)
                        : Colors.white.withOpacity(0.08),
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppTheme.accentGreen.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      const Icon(Icons.check_circle,
                          size: 14, color: AppTheme.accentGreen),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      eq,
                      style: GoogleFonts.poppins(
                        color: selected
                            ? AppTheme.accentGreen
                            : AppTheme.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ).animate().fadeIn(delay: 150.ms),

        const SizedBox(height: 36),

        if (planB.status == PlanBStatus.error)
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.errorColor.withOpacity(0.12),
                  AppTheme.errorColor.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppTheme.errorColor.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline,
                      color: AppTheme.errorColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    planB.errorMessage,
                    style: GoogleFonts.poppins(
                      color: AppTheme.errorColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().shake(hz: 3, offset: const Offset(3, 0)),

        _ActivateButton(
          enabled: planB.hasEquipment,
          onTap: onTriggerAI,
        ).animate().fadeIn(delay: 200.ms),

        if (!planB.hasEquipment)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: Text(
                'Select at least one equipment type to continue.',
                style: GoogleFonts.poppins(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Loading view ──────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            AILoadingWidget(),
          ],
        ),
      ),
    );
  }
}

// ── Result view ───────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final PlanBResult result;
  final Exercise originalExercise;
  final VoidCallback onMarkDone;

  const _ResultView({
    required this.result,
    required this.originalExercise,
    required this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Original exercise (crossed out)
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.errorColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.not_interested,
                    color: AppTheme.errorColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${originalExercise.name}  —  occupied',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),

        PlanBResultCard(
          result: result,
          onMarkDone: onMarkDone,
        ),

        const SizedBox(height: 18),

        Center(
          child: TextButton.icon(
            onPressed: () => context
                .read<PlanBProvider>()
                .setTargetExercise(originalExercise),
            icon: const Icon(Icons.refresh,
                size: 15, color: AppTheme.textSecondary),
            label: Text(
              'Try a different suggestion',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Target Exercise Card ─────────────────────────────────────────────────────
class _TargetExerciseCard extends StatelessWidget {
  final Exercise exercise;
  const _TargetExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E38), Color(0xFF14141F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.errorColor.withOpacity(0.25),
              ),
            ),
            child:
                const Icon(Icons.block, color: AppTheme.errorColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUSY EQUIPMENT',
                  style: GoogleFonts.poppins(
                    color: AppTheme.errorColor.withOpacity(0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exercise.name,
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
                        exercise.muscleGroup,
                        style: GoogleFonts.poppins(
                          color: AppTheme.accentGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${exercise.sets} × ${exercise.reps}',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo Button ─────────────────────────────────────────────────────────────
class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.textSecondary, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activate Button ──────────────────────────────────────────────────────────
class _ActivateButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ActivateButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? AppTheme.neonPurpleGlow(intensity: 0.4)
            : [],
      ),
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.bolt, size: 20),
        label: Text(
          'ACTIVATE MANUS AI',
          style: GoogleFonts.orbitron(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? AppTheme.accentPurple : AppTheme.divider,
          foregroundColor:
              enabled ? Colors.white : AppTheme.textMuted,
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}
