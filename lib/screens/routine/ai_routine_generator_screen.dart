import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/ai_service.dart';
import '../../models/workout_routine.dart';
import '../../models/user_profile.dart';
import '../../providers/routine_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loading/ai_loading_widget.dart';

/// AI Routine Generator Screen
///
/// A multi-step wizard that collects user preferences and generates
/// a personalized workout routine using Manus AI.
class AIRoutineGeneratorScreen extends StatefulWidget {
  const AIRoutineGeneratorScreen({super.key});

  @override
  State<AIRoutineGeneratorScreen> createState() =>
      _AIRoutineGeneratorScreenState();
}

class _AIRoutineGeneratorScreenState extends State<AIRoutineGeneratorScreen> {
  // ── Step tracking ─────────────────────────────────────────────────────────
  int _currentStep = 0;
  bool _isGenerating = false;
  bool _isSuccess = false;
  String _errorMessage = '';
  WorkoutRoutine? _generatedRoutine;

  // ── User inputs ───────────────────────────────────────────────────────────
  String _goal = '';
  String _fitnessLevel = 'Intermediate';
  int _daysPerWeek = 4;
  List<String> _availableEquipment = [];
  List<String> _injuries = [];
  String _additionalNotes = '';
  String _routineType = 'PPL'; // PPL, Upper/Lower, Full Body, Bro Split

  // ── Controllers ───────────────────────────────────────────────────────────
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final PageController _pageController = PageController();

  // ── Equipment options ─────────────────────────────────────────────────────
  static const List<String> _equipmentOptions = [
    'Barbell',
    'Dumbbells',
    'Cable Machine',
    'Pull-up Bar',
    'Leg Press',
    'Smith Machine',
    'Resistance Bands',
    'Kettlebells',
    'EZ Curl Bar',
    'Bench (Flat/Incline)',
    'Squat Rack',
    'Lat Pulldown',
    'Rowing Machine',
    'Bodyweight Only',
  ];

  // ── Routine type options ──────────────────────────────────────────────────
  static const List<Map<String, String>> _routineTypes = [
    {'id': 'PPL', 'name': 'Push/Pull/Legs', 'desc': 'Best for 5-6 days/week'},
    {'id': 'UL', 'name': 'Upper/Lower', 'desc': 'Best for 4 days/week'},
    {'id': 'FB', 'name': 'Full Body', 'desc': 'Best for 2-3 days/week'},
    {'id': 'BS', 'name': 'Bro Split', 'desc': 'One muscle group per day'},
    {'id': 'AI', 'name': 'Let AI Decide', 'desc': 'AI picks the best split'},
  ];

  // ── Goal options ──────────────────────────────────────────────────────────
  static const List<Map<String, String>> _goalOptions = [
    {'id': 'muscle', 'name': 'Build Muscle', 'icon': '💪'},
    {'id': 'strength', 'name': 'Get Stronger', 'icon': '🏋️'},
    {'id': 'lose_fat', 'name': 'Lose Fat', 'icon': '🔥'},
    {'id': 'endurance', 'name': 'Endurance', 'icon': '🏃'},
    {'id': 'general', 'name': 'General Fitness', 'icon': '⚡'},
  ];

  @override
  void dispose() {
    _goalController.dispose();
    _notesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'AI ROUTINE GENERATOR',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (_currentStep > 0 && !_isGenerating) {
              _goToPreviousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          if (!_isGenerating && !_isSuccess)
            _StepProgressBar(
              currentStep: _currentStep,
              totalSteps: 5,
            ),

          // Main content
          Expanded(
            child: _isGenerating
                ? _buildGeneratingState()
                : _isSuccess
                    ? _buildSuccessState()
                    : _buildStepContent(),
          ),
        ],
      ),
    );
  }

  // ── Step content builder ──────────────────────────────────────────────────
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildGoalStep();
      case 1:
        return _buildFitnessLevelStep();
      case 2:
        return _buildRoutineTypeStep();
      case 3:
        return _buildEquipmentStep();
      case 4:
        return _buildFinalStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 0: Goal Selection
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGoalStep() {
    return _StepContainer(
      title: 'What\'s your goal?',
      subtitle: 'This helps AI design the perfect routine for you.',
      child: Column(
        children: [
          ..._goalOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _goal == option['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SelectionCard(
                icon: option['icon']!,
                title: option['name']!,
                isSelected: isSelected,
                onTap: () => setState(() => _goal = option['id']!),
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 80 * index))
                .slideX(begin: 0.05);
          }),
          const SizedBox(height: 24),
          _NextButton(
            enabled: _goal.isNotEmpty,
            onPressed: _goToNextStep,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1: Fitness Level & Days
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFitnessLevelStep() {
    return _StepContainer(
      title: 'About you',
      subtitle: 'Your fitness level and schedule.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FITNESS LEVEL',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: UserProfile.fitnessLevels.map((level) {
              final isSelected = _fitnessLevel == level;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _fitnessLevel = level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentGreen.withOpacity(0.12)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentGreen
                              : AppTheme.divider,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          level,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.accentGreen
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text(
            'DAYS PER WEEK',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (i) {
              final days = i + 2; // 2 to 7
              final isSelected = _daysPerWeek == days;
              return GestureDetector(
                onTap: () => setState(() => _daysPerWeek = days),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppTheme.accentGreen.withOpacity(0.15)
                        : AppTheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentGreen
                          : AppTheme.divider,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.accentGreen.withOpacity(0.2),
                              blurRadius: 12,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$days',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppTheme.accentGreen
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '$_daysPerWeek days per week',
              style: GoogleFonts.poppins(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Injuries section
          Text(
            'ANY INJURIES? (Optional)',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserProfile.commonInjuries.map((injury) {
              final isSelected = _injuries.contains(injury);
              return FilterChip(
                label: Text(injury),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _injuries.add(injury);
                    } else {
                      _injuries.remove(injury);
                    }
                  });
                },
                selectedColor: AppTheme.errorColor.withOpacity(0.15),
                checkmarkColor: AppTheme.errorColor,
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.errorColor.withOpacity(0.5)
                      : AppTheme.divider,
                ),
                labelStyle: GoogleFonts.poppins(
                  color: isSelected
                      ? AppTheme.errorColor
                      : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _NextButton(
            enabled: true,
            onPressed: _goToNextStep,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2: Routine Type
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRoutineTypeStep() {
    return _StepContainer(
      title: 'Routine style',
      subtitle: 'Choose your preferred workout split.',
      child: Column(
        children: [
          ..._routineTypes.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final isSelected = _routineType == type['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _routineType = type['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentPurple.withOpacity(0.1)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentPurple
                          : AppTheme.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.accentPurple.withOpacity(0.1),
                              blurRadius: 16,
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.accentPurple
                                : AppTheme.textMuted,
                            width: 2,
                          ),
                          color: isSelected
                              ? AppTheme.accentPurple
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type['name']!,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              type['desc']!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 60 * index))
                .slideX(begin: 0.03);
          }),
          const SizedBox(height: 24),
          _NextButton(
            enabled: _routineType.isNotEmpty,
            onPressed: _goToNextStep,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 3: Equipment
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEquipmentStep() {
    return _StepContainer(
      title: 'Available equipment',
      subtitle: 'Select what you have access to at your gym.',
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _equipmentOptions.map((equip) {
              final isSelected = _availableEquipment.contains(equip);
              return FilterChip(
                label: Text(equip),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _availableEquipment.add(equip);
                    } else {
                      _availableEquipment.remove(equip);
                    }
                  });
                },
                selectedColor: AppTheme.accentGreen.withOpacity(0.15),
                checkmarkColor: AppTheme.accentGreen,
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.accentGreen.withOpacity(0.5)
                      : AppTheme.divider,
                ),
                labelStyle: GoogleFonts.poppins(
                  color: isSelected
                      ? AppTheme.accentGreen
                      : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Select all / clear
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => setState(
                    () => _availableEquipment = List.from(_equipmentOptions)),
                child: Text(
                  'Select All',
                  style: GoogleFonts.poppins(
                    color: AppTheme.accentGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => setState(() => _availableEquipment.clear()),
                child: Text(
                  'Clear',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _NextButton(
            enabled: _availableEquipment.isNotEmpty,
            onPressed: _goToNextStep,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 4: Additional Notes + Summary
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFinalStep() {
    final goalName = _goalOptions
        .firstWhere((g) => g['id'] == _goal,
            orElse: () => {'name': 'General'})['name']!;
    final routineTypeName = _routineTypes
        .firstWhere((r) => r['id'] == _routineType,
            orElse: () => {'name': 'PPL'})['name']!;

    return _StepContainer(
      title: 'Almost there!',
      subtitle: 'Add any extra details and review your preferences.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentPurple.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: AppTheme.accentPurple, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'YOUR PREFERENCES',
                      style: GoogleFonts.orbitron(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentPurple,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SummaryRow('Goal', goalName),
                _SummaryRow('Level', _fitnessLevel),
                _SummaryRow('Split', routineTypeName),
                _SummaryRow('Days/Week', '$_daysPerWeek'),
                _SummaryRow(
                    'Equipment', '${_availableEquipment.length} selected'),
                if (_injuries.isNotEmpty)
                  _SummaryRow('Injuries', _injuries.join(', ')),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

          const SizedBox(height: 24),

          // Additional notes
          Text(
            'ANYTHING ELSE? (Optional)',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'e.g., "I want to focus more on arms" or "I only have 45 min per session"',
              hintStyle: GoogleFonts.poppins(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
            onChanged: (val) => _additionalNotes = val,
          ),

          const SizedBox(height: 32),

          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: AppTheme.errorColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.poppins(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Generate button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.neonPurpleGlow(intensity: 0.3),
            ),
            child: ElevatedButton.icon(
              onPressed: _generateRoutine,
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
                'GENERATE MY ROUTINE',
                style: GoogleFonts.orbitron(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).scale(
                begin: const Offset(0.95, 0.95),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GENERATING STATE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGeneratingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI Loading animation
            const AILoadingWidget(),
            const SizedBox(height: 32),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.planBGradient.createShader(bounds),
              child: Text(
                'GENERATING ROUTINE',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Manus AI is crafting your personalized\nworkout plan...',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Animated tips
            _AnimatedTip(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUCCESS STATE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSuccessState() {
    if (_generatedRoutine == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Success header
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentGreen.withOpacity(0.2),
                  AppTheme.accentGreen.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: AppTheme.accentGreen.withOpacity(0.5),
              ),
              boxShadow: AppTheme.neonGreenGlow(intensity: 0.3),
            ),
            child: const Icon(Icons.check_rounded,
                color: AppTheme.accentGreen, size: 36),
          ).animate().scale(
                begin: const Offset(0.5, 0.5),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 20),
          Text(
            'Routine Generated!',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_generatedRoutine!.days.length} workout days created',
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Routine preview
          ..._generatedRoutine!.days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RoutineDayPreviewCard(day: day),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 * index))
                .slideY(begin: 0.05);
          }),

          const SizedBox(height: 24),

          // Accept button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.neonGreenGlow(intensity: 0.25),
            ),
            child: ElevatedButton.icon(
              onPressed: _acceptRoutine,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                'USE THIS ROUTINE',
                style: GoogleFonts.orbitron(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Regenerate button
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isSuccess = false;
                _generatedRoutine = null;
                _errorMessage = '';
              });
              _generateRoutine();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentPurple,
              side: const BorderSide(color: AppTheme.accentPurple, width: 1.5),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Regenerate'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _goToNextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // ── Generate routine via AI ───────────────────────────────────────────────
  Future<void> _generateRoutine() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = '';
    });

    try {
      final userProvider = context.read<UserProvider>();
      final profile = userProvider.profile;

      final routine = await AIService.instance.generateRoutine(
        goal: _goal,
        fitnessLevel: _fitnessLevel,
        daysPerWeek: _daysPerWeek,
        routineType: _routineType,
        availableEquipment: _availableEquipment,
        injuries: _injuries,
        additionalNotes: _additionalNotes,
        userName: profile.name,
      );

      setState(() {
        _generatedRoutine = routine;
        _isGenerating = false;
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = e.toString().replaceAll('AIException: ', '');
      });
    }
  }

  // ── Accept and save routine ───────────────────────────────────────────────
  void _acceptRoutine() {
    if (_generatedRoutine == null) return;

    final routineProvider = context.read<RoutineProvider>();
    routineProvider.setFullRoutine(_generatedRoutine!);

    // Show success snackbar and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 20),
            const SizedBox(width: 10),
            Text(
              'Routine saved! Let\'s get to work 💪',
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgressBar({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isCompleted = i < currentStep;
          final isCurrent = i == currentStep;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isCompleted
                      ? AppTheme.accentGreen
                      : isCurrent
                          ? AppTheme.accentPurple
                          : AppTheme.divider,
                  boxShadow: (isCompleted || isCurrent)
                      ? [
                          BoxShadow(
                            color: (isCompleted
                                    ? AppTheme.accentGreen
                                    : AppTheme.accentPurple)
                                .withOpacity(0.4),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StepContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepContainer({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.orbitron(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.03),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentGreen.withOpacity(0.08)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.accentGreen : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentGreen.withOpacity(0.1),
                    blurRadius: 16,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppTheme.accentGreen : AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentGreen.withOpacity(0.15),
                  border: Border.all(color: AppTheme.accentGreen),
                ),
                child: const Icon(Icons.check,
                    size: 14, color: AppTheme.accentGreen),
              ),
          ],
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _NextButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled ? AppTheme.neonGreenGlow(intensity: 0.2) : null,
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CONTINUE',
              style: GoogleFonts.orbitron(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineDayPreviewCard extends StatelessWidget {
  final WorkoutDay day;

  const _RoutineDayPreviewCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentGreen.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  day.dayName,
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${day.exercises.length} exercises',
                style: GoogleFonts.poppins(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...day.exercises.map((ex) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentPurple,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ex.name,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${ex.sets}x${ex.reps}',
                      style: GoogleFonts.orbitron(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _AnimatedTip extends StatefulWidget {
  @override
  State<_AnimatedTip> createState() => _AnimatedTipState();
}

class _AnimatedTipState extends State<_AnimatedTip> {
  int _tipIndex = 0;
  static const List<String> _tips = [
    'Analyzing your fitness goals...',
    'Selecting optimal exercises...',
    'Balancing muscle groups...',
    'Calculating sets and reps...',
    'Applying injury constraints...',
    'Finalizing your routine...',
  ];

  @override
  void initState() {
    super.initState();
    _cycleTips();
  }

  void _cycleTips() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
        _cycleTips();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(_tipIndex),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                color: AppTheme.accentPurple, size: 14),
            const SizedBox(width: 8),
            Text(
              _tips[_tipIndex],
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
