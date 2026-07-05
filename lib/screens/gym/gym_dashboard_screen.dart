import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/gym_occupancy_card.dart';
import '../../widgets/best_time_chart.dart';
import '../../widgets/equipment_list.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// Gym Dashboard Screen
///
/// The main gym status screen combining:
///   • Real-time occupancy card (LIVE status)
///   • Best Time to Go hourly chart
///   • Equipment availability list with filters
///
/// Auto-initializes GymProvider on first build.
/// ═══════════════════════════════════════════════════════════════════════════════
class GymDashboardScreen extends StatefulWidget {
  const GymDashboardScreen({super.key});

  @override
  State<GymDashboardScreen> createState() => _GymDashboardScreenState();
}

class _GymDashboardScreenState extends State<GymDashboardScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      context.read<GymProvider>().initialize();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.accentGreen,
        backgroundColor: AppTheme.cardColor,
        onRefresh: () async {
          context.read<GymProvider>().forceRefresh();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── Premium AppBar ──
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppTheme.background,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 60,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.planBGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGreen.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.sensors_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GYM STATUS',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Real-time equipment tracking',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                // Refresh button
                IconButton(
                  onPressed: () {
                    context.read<GymProvider>().forceRefresh();
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: AppTheme.textSecondary, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ── Content ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Live Occupancy Card ──
                  const GymOccupancyCard(),

                  const SizedBox(height: 20),

                  // ── Quick Insight Banner ──
                  _QuickInsightBanner(),

                  const SizedBox(height: 20),

                  // ── Best Time to Go Chart ──
                  const BestTimeChart(),

                  const SizedBox(height: 24),

                  // ── Equipment Availability ──
                  const EquipmentList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Insight Banner ──────────────────────────────────────────────────────
class _QuickInsightBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GymProvider>(
      builder: (context, gym, _) {
        if (gym.occupancy == null) return const SizedBox.shrink();

        final occ = gym.occupancy!;
        final isBusy = occ.occupancyPercent > 0.6;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isBusy
                  ? [
                      AppTheme.accentOrange.withOpacity(0.1),
                      AppTheme.errorColor.withOpacity(0.05),
                    ]
                  : [
                      AppTheme.accentGreen.withOpacity(0.08),
                      AppTheme.accentPurple.withOpacity(0.04),
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isBusy
                  ? AppTheme.accentOrange.withOpacity(0.2)
                  : AppTheme.accentGreen.withOpacity(0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isBusy ? AppTheme.accentOrange : AppTheme.accentGreen)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isBusy
                      ? Icons.people_alt_rounded
                      : Icons.directions_run_rounded,
                  color:
                      isBusy ? AppTheme.accentOrange : AppTheme.accentGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBusy ? 'Gym is busy right now' : 'Great time to train!',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBusy
                          ? 'Use Plan B to find alternative exercises for busy machines.'
                          : '${occ.availableCount} machines available. Minimal wait times expected.',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBusy)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.planBGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Plan B',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
      },
    );
  }
}
