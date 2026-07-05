import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/gym_equipment.dart';
import '../providers/gym_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// Equipment Availability List
///
/// Shows all gym equipment with real-time status indicators.
/// Features:
///   • Search bar for finding specific machines
///   • Category filter chips (All, Chest, Back, Legs, etc.)
///   • Color-coded status badges (green/orange/grey)
///   • Estimated wait time for occupied equipment
///   • Tap on busy machine → suggest Plan B
/// ═══════════════════════════════════════════════════════════════════════════════
class EquipmentList extends StatelessWidget {
  const EquipmentList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GymProvider>(
      builder: (context, gym, _) {
        if (gym.isLoading || gym.occupancy == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentGreen),
          );
        }

        final equipment = gym.filteredEquipment;
        final categories = gym.categories;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fitness_center_rounded,
                        color: AppTheme.accentPurple, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'EQUIPMENT STATUS',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${equipment.length} items',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Search Bar ──
            _SearchBar(
              query: gym.searchQuery,
              onChanged: (q) => gym.setSearchQuery(q),
              onClear: () => gym.clearSearch(),
            ),

            const SizedBox(height: 14),

            // ── Category Filter Chips ──
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: gym.selectedCategory == null,
                    onTap: () => gym.setCategory(null),
                  ),
                  ...categories.map((cat) => _FilterChip(
                        label: _capitalize(cat),
                        isSelected: gym.selectedCategory == cat,
                        onTap: () => gym.setCategory(cat),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Equipment List ──
            if (equipment.isEmpty)
              _EmptySearchState(query: gym.searchQuery)
            else
              ...equipment.asMap().entries.map((entry) {
                final index = entry.key;
                final eq = entry.value;
                return _EquipmentTile(equipment: eq)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 40 * index))
                    .slideX(begin: 0.02);
              }),
          ],
        );
      },
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _SearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _controller.text.isNotEmpty
              ? AppTheme.accentGreen.withOpacity(0.3)
              : AppTheme.divider,
        ),
        boxShadow: _controller.text.isNotEmpty
            ? [
                BoxShadow(
                  color: AppTheme.accentGreen.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: GoogleFonts.poppins(
          color: AppTheme.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search machines... (e.g., "squat", "bench")',
          hintStyle: GoogleFonts.poppins(
            color: AppTheme.textMuted,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _controller.text.isNotEmpty
                ? AppTheme.accentGreen
                : AppTheme.textMuted,
            size: 20,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _controller.clear();
                    widget.onClear();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppTheme.textSecondary, size: 14),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ── Empty Search State ───────────────────────────────────────────────────────
class _EmptySearchState extends StatelessWidget {
  final String query;
  const _EmptySearchState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                color: AppTheme.accentOrange, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'No machines found',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No results for "$query". Try a different search term.',
            style: GoogleFonts.poppins(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [
                  AppTheme.accentPurple.withOpacity(0.2),
                  AppTheme.accentPurple.withOpacity(0.08),
                ])
              : null,
          color: isSelected ? null : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentPurple.withOpacity(0.5)
                : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? AppTheme.accentPurple : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Equipment Tile ────────────────────────────────────────────────────────────
class _EquipmentTile extends StatelessWidget {
  final GymEquipment equipment;

  const _EquipmentTile({required this.equipment});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(equipment.status);
    final statusLabel = _getStatusLabel(equipment.status);
    final statusIcon = _getStatusIcon(equipment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: equipment.isFree
              ? AppTheme.accentGreen.withOpacity(0.15)
              : AppTheme.divider,
        ),
      ),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Equipment name + zone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.name,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  equipment.zone,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Wait time (only if occupied)
          if (equipment.isBusy && equipment.avgWaitMinutes > 0) ...[
            const SizedBox(width: 8),
            Text(
              '~${equipment.avgWaitMinutes}m',
              style: GoogleFonts.orbitron(
                color: AppTheme.accentOrange,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.available:
        return AppTheme.accentGreen;
      case EquipmentStatus.occupied:
        return AppTheme.accentOrange;
      case EquipmentStatus.maintenance:
        return AppTheme.textMuted;
    }
  }

  String _getStatusLabel(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.available:
        return 'FREE';
      case EquipmentStatus.occupied:
        return 'BUSY';
      case EquipmentStatus.maintenance:
        return 'DOWN';
    }
  }

  IconData _getStatusIcon(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.available:
        return Icons.check_circle_outline;
      case EquipmentStatus.occupied:
        return Icons.hourglass_top_rounded;
      case EquipmentStatus.maintenance:
        return Icons.build_circle_outlined;
    }
  }
}
