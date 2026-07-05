import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/gym_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// Best Time to Go Chart
///
/// Displays hourly occupancy predictions using fl_chart bar chart.
/// Features:
///   • Day-of-week selector (Mon-Sun)
///   • Color-coded bars (green=light, orange=moderate, red=packed)
///   • Current hour highlighted
///   • Best/worst time callouts
/// ═══════════════════════════════════════════════════════════════════════════════
class BestTimeChart extends StatefulWidget {
  const BestTimeChart({super.key});

  @override
  State<BestTimeChart> createState() => _BestTimeChartState();
}

class _BestTimeChartState extends State<BestTimeChart> {
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0 = Monday

  @override
  Widget build(BuildContext context) {
    return Consumer<GymProvider>(
      builder: (context, gym, _) {
        if (gym.weekPredictions == null) {
          return const SizedBox.shrink();
        }

        final predictions = gym.weekPredictions!;
        final selectedDay = predictions[_selectedDayIndex];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.schedule_rounded,
                        color: AppTheme.accentGreen, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'BEST TIME TO GO',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Day Selector ──
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = predictions[index];
                    final isSelected = index == _selectedDayIndex;
                    final label = day.dayName.substring(0, 3); // Mon, Tue, etc.

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDayIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? AppTheme.planBGradient
                              : null,
                          color: isSelected ? null : AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppTheme.divider,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ── Bar Chart ──
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 1.0,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppTheme.cardColor,
                        tooltipBorder: const BorderSide(color: AppTheme.divider),
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final hour = selectedDay.hourly[group.x.toInt()];
                          return BarTooltipItem(
                            '${hour.label}\n${(hour.occupancy * 100).round()}%',
                            GoogleFonts.poppins(
                              color: AppTheme.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value == 0.5 || value == 1.0) {
                              return Text(
                                '${(value * 100).round()}%',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.textMuted,
                                  fontSize: 9,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= selectedDay.hourly.length) {
                              return const SizedBox.shrink();
                            }
                            // Show every 3rd label to avoid crowding
                            if (idx % 3 != 0) return const SizedBox.shrink();
                            final hour = selectedDay.hourly[idx];
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                hour.label.replaceAll(' ', '\n'),
                                style: GoogleFonts.poppins(
                                  color: hour.isNow
                                      ? AppTheme.accentGreen
                                      : AppTheme.textMuted,
                                  fontSize: 8,
                                  fontWeight: hour.isNow
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 0.25,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppTheme.divider.withOpacity(0.3),
                        strokeWidth: 0.5,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: selectedDay.hourly.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final hour = entry.value;
                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: hour.occupancy,
                            width: 8,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                            gradient: LinearGradient(
                              colors: [
                                _getBarColor(hour.occupancy).withOpacity(0.6),
                                _getBarColor(hour.occupancy),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 1.0,
                              color: AppTheme.surface,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 300),
                  swapAnimationCurve: Curves.easeOutCubic,
                ),
              ),

              const SizedBox(height: 16),

              // ── Best/Worst Time Callouts ──
              Row(
                children: [
                  Expanded(
                    child: _TimeCallout(
                      icon: Icons.thumb_up_alt_rounded,
                      color: AppTheme.accentGreen,
                      label: 'Best',
                      time: selectedDay.bestTimeLabel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeCallout(
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.errorColor,
                      label: 'Avoid',
                      time: _formatHour(selectedDay.worstHour),
                    ),
                  ),
                ],
              ),

              // ── Prediction accuracy badge ──
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: AppTheme.accentGold.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 12, color: AppTheme.accentGold),
                      const SizedBox(width: 4),
                      Text(
                        '92% prediction accuracy',
                        style: GoogleFonts.poppins(
                          color: AppTheme.accentGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.03);
      },
    );
  }

  Color _getBarColor(double occupancy) {
    if (occupancy < 0.35) return AppTheme.accentGreen;
    if (occupancy < 0.65) return AppTheme.accentOrange;
    return AppTheme.errorColor;
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

// ── Time Callout Widget ───────────────────────────────────────────────────────
class _TimeCallout extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String time;

  const _TimeCallout({
    required this.icon,
    required this.color,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                time,
                style: GoogleFonts.orbitron(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
