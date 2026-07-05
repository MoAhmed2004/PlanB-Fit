import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../core/theme/app_theme.dart';
import '../providers/gym_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// Gym Occupancy Card
///
/// Premium widget showing real-time gym status with:
///   • Pulsing "LIVE" indicator
///   • Circular occupancy gauge
///   • Crowd level label with color coding
///   • Quick equipment summary (free/busy/down)
///   • "Best time" suggestion banner
/// ═══════════════════════════════════════════════════════════════════════════════
class GymOccupancyCard extends StatelessWidget {
  const GymOccupancyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GymProvider>(
      builder: (context, gym, _) {
        if (gym.isLoading || gym.occupancy == null) {
          return _LoadingState();
        }

        final occ = gym.occupancy!;
        final statusColor = _getStatusColor(occ.crowdLevel);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: statusColor.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: LIVE + Gym Name + Updated time ──
              Row(
                children: [
                  _PulsingDot(color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE',
                    style: GoogleFonts.orbitron(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      occ.gymName,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    timeago.format(occ.lastUpdated, allowFromNow: true),
                    style: GoogleFonts.poppins(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Main: Circular gauge + Crowd info ──
              Row(
                children: [
                  // Circular occupancy gauge
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: occ.occupancyPercent,
                            strokeWidth: 7,
                            strokeCap: StrokeCap.round,
                            backgroundColor: AppTheme.surface,
                            valueColor: AlwaysStoppedAnimation(statusColor),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(occ.occupancyPercent * 100).round()}',
                              style: GoogleFonts.orbitron(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '%',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Crowd level + people count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          occ.crowdLevel.toUpperCase(),
                          style: GoogleFonts.orbitron(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${occ.currentCount} / ${occ.totalCapacity} people',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getCrowdMessage(occ.crowdLevel),
                          style: GoogleFonts.poppins(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Equipment summary row ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    _MiniStat(
                      icon: Icons.check_circle_outline,
                      color: AppTheme.accentGreen,
                      value: '${occ.availableCount}',
                      label: 'Free',
                    ),
                    _Divider(),
                    _MiniStat(
                      icon: Icons.hourglass_top_rounded,
                      color: AppTheme.accentOrange,
                      value: '${occ.occupiedCount}',
                      label: 'Busy',
                    ),
                    _Divider(),
                    _MiniStat(
                      icon: Icons.build_circle_outlined,
                      color: AppTheme.textMuted,
                      value: '${occ.maintenanceCount}',
                      label: 'Down',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Best time suggestion ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGreen.withOpacity(0.08),
                      AppTheme.accentGreen.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.accentGreen.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        color: AppTheme.accentGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Best time today: ${gym.bestTimeToday}',
                        style: GoogleFonts.poppins(
                          color: AppTheme.accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: AppTheme.accentGreen.withOpacity(0.5), size: 12),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.03);
      },
    );
  }

  Color _getStatusColor(String level) {
    switch (level) {
      case 'empty':
        return AppTheme.accentGreen;
      case 'light':
        return AppTheme.accentGreen;
      case 'moderate':
        return AppTheme.accentOrange;
      case 'busy':
        return AppTheme.accentOrange;
      case 'packed':
        return AppTheme.errorColor;
      default:
        return AppTheme.textMuted;
    }
  }

  String _getCrowdMessage(String level) {
    switch (level) {
      case 'empty':
        return 'Perfect time to train! 💪';
      case 'light':
        return 'Great conditions, minimal wait.';
      case 'moderate':
        return 'Some equipment may be busy.';
      case 'busy':
        return 'Expect wait times on popular machines.';
      case 'packed':
        return 'Peak hour — Plan B recommended!';
      default:
        return '';
    }
  }
}

// ── Pulsing Live Dot ──────────────────────────────────────────────────────────
class _PulsingDot extends StatelessWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.6), blurRadius: 6),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(end: 1.4, duration: 800.ms)
        .then()
        .scaleXY(end: 1.0, duration: 800.ms);
  }
}

// ── Mini Stat Widget ──────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vertical Divider ──────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppTheme.divider,
    );
  }
}

// ── Loading State ─────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.accentGreen,
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Connecting to gym sensors...',
            style: GoogleFonts.poppins(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
