import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/water_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/daily_progress.dart';
import '../widgets/quick_add_row.dart';
import '../widgets/log_history.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(waterProvider);
    final notifier = ref.read(waterProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Soft Gradients
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xffe1f5fe), // Soft ice blue
                  Color(0xffe8eaf6), // Lavender mist
                  Color(0xffffffff), // Pure white
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // 2. Translucent floating blobs (for backdrop blur contrast)
          Positioned(
            top: -40,
            left: -30,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff80deea).withOpacity(0.35),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff90caf9).withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            top: 280,
            right: 20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xffe0f7fa).withOpacity(0.55),
              ),
            ),
          ),
          // 3. Scrollable Foreground Contents
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Bar Title & Subtitle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Water Tracker',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xff0d47a1),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Keep your hydration on track',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xff1565c0).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      // Reset Button
                      IconButton(
                        tooltip: 'Reset Progress',
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xff0d47a1),
                            size: 20,
                          ),
                        ),
                        onPressed: () => _confirmReset(context, notifier),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Center Radial Progress
                  Center(
                    child: DailyProgress(
                      currentIntake: state.currentIntake,
                      dailyGoal: state.dailyGoal,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Quick Add Container
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: Text(
                            'Quick Log',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xff0d47a1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const QuickAddRow(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Target Goal Adjuster
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Goal',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff1565c0).withOpacity(0.7),
                              ),
                            ),
                            Text(
                              '${state.dailyGoal} ml',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xff0d47a1),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _buildGoalAdjustButton(
                              icon: Icons.remove_rounded,
                              onPressed: () {
                                if (state.dailyGoal > 500) {
                                  notifier.setDailyGoal(state.dailyGoal - 250);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildGoalAdjustButton(
                              icon: Icons.add_rounded,
                              onPressed: () {
                                if (state.dailyGoal < 5000) {
                                  notifier.setDailyGoal(state.dailyGoal + 250);
                                }
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Today's History Log
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Intake logs",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xff0d47a1),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const LogHistory(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalAdjustButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
        ),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: const Color(0xff0d47a1),
        iconSize: 20,
        constraints: const BoxConstraints(
          minHeight: 38,
          minWidth: 38,
        ),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  void _confirmReset(BuildContext context, WaterNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          contentPadding: EdgeInsets.zero,
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reset Progress',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xffd32f2f),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to clear today\'s water log history? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.outfit(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffd32f2f),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          notifier.resetToday();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Reset',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
