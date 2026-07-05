import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/storage_service.dart';
import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';
import '../../providers/routine_provider.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  int _currentPage = 0;

  // Step 1
  final _nameCtrl = TextEditingController();
  String _fitnessLevel = 'Intermediate';

  // Step 2
  final Set<String> _selectedInjuries = {};

  // Step 3
  bool _loadDefaultPPL = true;
  bool _isSaving = false;

  static const int _totalPages = 3;

  @override
  void dispose() {
    _pages.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && _nameCtrl.text.trim().isEmpty) {
      _showError('Please enter your name.');
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _prevPage() {
    if (_currentPage == 0) return;
    _pages.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    try {
      final profile = UserProfile(
        name: _nameCtrl.text.trim(),
        fitnessLevel: _fitnessLevel,
        injuries: _selectedInjuries.toList(),
      );
      await context.read<UserProvider>().saveProfile(profile);

      if (_loadDefaultPPL) {
        await context.read<RoutineProvider>().loadDefaultPPL();
      }

      await StorageService.instance.saveBool(StorageKeys.onboardingDone, true);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      _showError('Something went wrong. Please try again.');
      setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header row: back arrow + step indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
              child: Row(
                children: [
                  AnimatedOpacity(
                    opacity: _currentPage > 0 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: IconButton(
                        onPressed: _currentPage > 0 ? _prevPage : null,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                        tooltip: 'Back',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StepIndicator(
                      current: _currentPage,
                      total: _totalPages,
                    ),
                  ),
                ],
              ),
            ),

            // ── Pages
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _PageOne(
                    nameCtrl: _nameCtrl,
                    selectedLevel: _fitnessLevel,
                    onLevelChanged: (l) => setState(() => _fitnessLevel = l),
                    onNext: _nextPage,
                  ),
                  _PageTwo(
                    selectedInjuries: _selectedInjuries,
                    onToggle: (inj) => setState(() {
                      _selectedInjuries.contains(inj)
                          ? _selectedInjuries.remove(inj)
                          : _selectedInjuries.add(inj);
                    }),
                    onNext: _nextPage,
                    onSkip: _nextPage,
                  ),
                  _PageThree(
                    loadDefaultPPL: _loadDefaultPPL,
                    onTogglePPL: (v) => setState(() => _loadDefaultPPL = v),
                    onFinish: _finish,
                    isSaving: _isSaving,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Logo + Name + Fitness Level ──────────────────────────────────────
class _PageOne extends StatelessWidget {
  final TextEditingController nameCtrl;
  final String selectedLevel;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback onNext;

  const _PageOne({
    required this.nameCtrl,
    required this.selectedLevel,
    required this.onLevelChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── App logo
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.planBGradient,
                boxShadow: AppTheme.neonGreenGlow(intensity: 0.25),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.bolt, color: Colors.white, size: 48),
              ),
            ),
          ).animate().scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'Never let a busy gym\nstop your gains.',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 40),

          _FieldLabel("What's your name?"),
          const SizedBox(height: 10),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g.  Alex',
              prefixIcon:
                  Icon(Icons.person_outline, color: AppTheme.textSecondary),
            ),
            style: GoogleFonts.poppins(
                color: AppTheme.textPrimary, fontSize: 16),
            textCapitalization: TextCapitalization.words,
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 32),

          _FieldLabel('Fitness Level'),
          const SizedBox(height: 12),
          ...UserProfile.fitnessLevels.map(
            (level) => _LevelCard(
              label: level,
              isSelected: selectedLevel == level,
              onTap: () => onLevelChanged(level),
            ),
          ),

          const SizedBox(height: 36),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.neonGreenGlow(intensity: 0.2),
            ),
            child: ElevatedButton(
              onPressed: onNext,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CONTINUE',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }
}

// ── Page 2: Injuries ──────────────────────────────────────────────────────────
class _PageTwo extends StatelessWidget {
  final Set<String> selectedInjuries;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _PageTwo({
    required this.selectedInjuries,
    required this.onToggle,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Any injuries?',
            style: GoogleFonts.orbitron(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 10),
          Text(
            'PlanB AI uses these as hard constraints — it will never suggest '
            'an exercise that puts your injuries at risk.',
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 28),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: UserProfile.commonInjuries.map((inj) {
              final selected = selectedInjuries.contains(inj);
              return GestureDetector(
                onTap: () => onToggle(inj),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              AppTheme.errorColor.withOpacity(0.15),
                              AppTheme.errorColor.withOpacity(0.05),
                            ],
                          )
                        : null,
                    color: selected ? null : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppTheme.errorColor.withOpacity(0.6)
                          : Colors.white.withOpacity(0.08),
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppTheme.errorColor.withOpacity(0.08),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: AppTheme.errorColor),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        inj,
                        style: GoogleFonts.poppins(
                          color: selected
                              ? AppTheme.errorColor
                              : AppTheme.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 40),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.neonGreenGlow(intensity: 0.2),
            ),
            child: ElevatedButton(
              onPressed: onNext,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CONTINUE',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: onSkip,
              child: Text(
                'No injuries — skip this step',
                style: GoogleFonts.poppins(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: PPL quick-start + finish ─────────────────────────────────────────
class _PageThree extends StatelessWidget {
  final bool loadDefaultPPL;
  final ValueChanged<bool> onTogglePPL;
  final VoidCallback onFinish;
  final bool isSaving;

  const _PageThree({
    required this.loadDefaultPPL,
    required this.onTogglePPL,
    required this.onFinish,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.planBGradient,
                boxShadow: AppTheme.neonGreenGlow(intensity: 0.3),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.bolt, color: Colors.white, size: 40),
              ),
            ),
          ).animate().scale(
                begin: const Offset(0.8, 0.8),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              "You're all set!",
              style: GoogleFonts.orbitron(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 10),
          Center(
            child: Text(
              'PlanB AI is ready to find your perfect\nalternative whenever equipment is busy.',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 40),

          // Quick-start PPL toggle
          GestureDetector(
            onTap: () => onTogglePPL(!loadDefaultPPL),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: loadDefaultPPL
                    ? LinearGradient(
                        colors: [
                          AppTheme.accentGreen.withOpacity(0.12),
                          AppTheme.accentGreen.withOpacity(0.04),
                        ],
                      )
                    : null,
                color: loadDefaultPPL ? null : AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: loadDefaultPPL
                      ? AppTheme.accentGreen.withOpacity(0.5)
                      : Colors.white.withOpacity(0.08),
                  width: loadDefaultPPL ? 1.5 : 1,
                ),
                boxShadow: loadDefaultPPL
                    ? [
                        BoxShadow(
                          color: AppTheme.accentGreen.withOpacity(0.08),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: loadDefaultPPL
                          ? AppTheme.accentGreen
                          : Colors.transparent,
                      border: Border.all(
                        color: loadDefaultPPL
                            ? AppTheme.accentGreen
                            : AppTheme.divider,
                        width: 2,
                      ),
                    ),
                    child: loadDefaultPPL
                        ? const Icon(Icons.check,
                            size: 16, color: Colors.black)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Load default PPL routine',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Push / Pull / Legs — 15 exercises ready to go',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 40),

          isSaving
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.neonGreenGlow(intensity: 0.3),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.bolt, size: 20),
                    label: Text(
                      "LET'S GO!",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 58),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).scale(
                      begin: const Offset(0.95, 0.95),
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      );
}

class _LevelCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _LevelCard(
      {required this.label, required this.isSelected, required this.onTap});

  static const _descriptions = {
    'Beginner': 'Under 1 year training',
    'Intermediate': '1–3 years consistent lifting',
    'Advanced': '3+ years, follows structured programs',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.accentGreen.withOpacity(0.12),
                    AppTheme.accentGreen.withOpacity(0.04),
                  ],
                )
              : null,
          color: isSelected ? null : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentGreen.withOpacity(0.6)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentGreen.withOpacity(0.06),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppTheme.accentGreen.withOpacity(0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accentGreen
                      : AppTheme.divider,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check,
                          size: 13, color: AppTheme.accentGreen))
                  : null,
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: isSelected
                        ? AppTheme.accentGreen
                        : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _descriptions[label] ?? '',
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
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i == current;
        final done = i < current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: done
                  ? AppTheme.planBGradient
                  : null,
              color: done
                  ? null
                  : active
                      ? AppTheme.accentPurple
                      : AppTheme.divider,
              boxShadow: (done || active)
                  ? [
                      BoxShadow(
                        color: (done
                                ? AppTheme.accentGreen
                                : AppTheme.accentPurple)
                            .withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
