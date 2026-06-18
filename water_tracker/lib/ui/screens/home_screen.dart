import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../providers/water_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/gemma_service.dart';
import '../../providers/auth_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/daily_progress.dart';
import '../widgets/log_history.dart';
import '../widgets/quick_add_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  Timer? _reminderTimer;
  late ConfettiController _confettiController;
  bool _hasCelebrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // Initial check in case state was initialized on a different day
    Future.microtask(() {
      ref.read(waterProvider.notifier).checkDailyReset();
    });
    _startReminderTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reminderTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(waterProvider.notifier).checkDailyReset();
      _checkScheduleAndRemind(); // Check schedule immediately on app resume
    }
  }

  void _startReminderTimer() {
    bool isTesting = false;
    if (!kIsWeb) {
      try {
        isTesting = Platform.environment.containsKey('FLUTTER_TEST');
      } catch (e) {
        // Ignored
      }
    }
    if (isTesting) return;

    // Run an immediate check on startup
    Future.delayed(const Duration(seconds: 3), () {
      _checkScheduleAndRemind();
    });
    // Check progress periodically (every 2 hours)
    _reminderTimer = Timer.periodic(const Duration(hours: 2), (timer) {
      _checkScheduleAndRemind();
    });
  }

  void _checkScheduleAndRemind() async {
    final state = ref.read(waterProvider);
    if (!state.remindersEnabled) return;

    final now = DateTime.now();
    // Schedule check: Active between 8 AM and 10 PM
    if (now.hour >= 8 && now.hour <= 22) {
      final int activeHoursPassed = now.hour - 8;
      final double hourlyRate = state.dailyGoal / 14.0;
      final int expectedIntake = (activeHoursPassed * hourlyRate).round();

      if (state.currentIntake < expectedIntake) {
        final reminderBody = await GemmaService().generateReminderMessage(
          currentIntake: state.currentIntake,
          dailyGoal: state.dailyGoal,
        );
        
        await NotificationService().showNotification(
          title: "Hydration Check 💧",
          body: reminderBody,
        );
      }
    }
  }

  void _triggerTestReminder() async {
    final state = ref.read(waterProvider);
    final reminderBody = await GemmaService().generateReminderMessage(
      currentIntake: state.currentIntake,
      dailyGoal: state.dailyGoal,
    );
    
    await NotificationService().showNotification(
      title: "Hydration Check 💧",
      body: reminderBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(waterProvider);
    final notifier = ref.read(waterProvider.notifier);

    // Confetti logic: check if goal reached
    final isGoalReached = state.currentIntake >= state.dailyGoal && state.dailyGoal > 0;
    if (isGoalReached && !_hasCelebrated) {
      _hasCelebrated = true;
      _confettiController.play();
    } else if (!isGoalReached) {
      _hasCelebrated = false;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Confetti widget on top of background but behind contents
          Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.yellow,
                  Colors.lightBlueAccent,
                ],
              ),
            ),
          ),
          // Background Soft Gradients
          RepaintBoundary(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFF5F5),
                    Color(0xFFFFE4E1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Scrollable Foreground
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Bar Title & Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Hydration\n',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xff331A1A),
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Dashboard',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFF6B6B),
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Settings Button
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Sign Out',
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9696).withValues(alpha: 0.1),
                                    blurRadius: 12,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Color(0xff331A1A),
                                size: 22,
                              ),
                            ),
                            onPressed: () {
                              ref.read(authProvider.notifier).signOut();
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Settings',
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9696).withValues(alpha: 0.1),
                                    blurRadius: 12,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.settings_rounded,
                                color: Color(0xff331A1A),
                                size: 22,
                              ),
                            ),
                            onPressed: () => _showSettingsDialog(context, state.dailyGoal, state.remindersEnabled, notifier),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Center Radial Progress
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Center(
                      child: RepaintBoundary(
                        child: DailyProgress(
                          currentIntake: state.currentIntake,
                          dailyGoal: state.dailyGoal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quick Add Section
                  Text(
                    "Quick Add",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff331A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const QuickAddRow(),
                  const SizedBox(height: 32),

                  // History Section
                  Text(
                    "Recent Activity",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff331A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const LogHistory(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(icon: Icons.dashboard_rounded, label: 'DASHBOARD', isActive: true),
                    _buildNavItem(icon: Icons.history_rounded, label: 'HISTORY', isActive: false),
                    _buildNavItem(icon: Icons.person_outline_rounded, label: 'PROFILE', isActive: false),
                    _buildNavItem(icon: Icons.settings_outlined, label: 'SETTINGS', isActive: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isActive}) {
    final color = isActive ? const Color(0xFFFF6B6B) : const Color(0xff331A1A).withValues(alpha: 0.6);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context, int currentGoal, bool currentReminders, WaterNotifier notifier) {
    final TextEditingController controller = TextEditingController(text: currentGoal.toString());
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool remindersEnabled = currentReminders;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              contentPadding: EdgeInsets.zero,
              content: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Hydration Goal',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xff331A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set your target daily water intake (in ml).',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff331A1A).withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.4),
                              suffixText: 'ml',
                              suffixStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff331A1A),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF6B6B),
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.redAccent,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xff331A1A),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a goal';
                                }
                                final int? parsed = int.tryParse(value);
                                if (parsed == null || parsed <= 0) {
                                  return 'Enter a valid positive number';
                                }
                                if (parsed > 10000) {
                                  return 'Goal is too high (max 10L)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            // Reminders Toggle Switch
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hydration Reminders',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xff331A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Check schedule every 2 hours',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xff331A1A).withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: remindersEnabled,
                                  activeThumbColor: const Color(0xFFFF6B6B),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      remindersEnabled = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Privacy Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    color: Color(0xFFFF6B6B),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Reminders powered locally',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xff331A1A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Trigger Test Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFF6B6B)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _triggerTestReminder();
                                },
                                icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFF6B6B), size: 18),
                                label: Text(
                                  'Trigger Test Reminder',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFFF6B6B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
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
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFFF6B6B),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6B6B),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        final int newGoal = int.parse(controller.text);
                                        notifier.setDailyGoal(newGoal);
                                        notifier.setRemindersEnabled(remindersEnabled);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Settings updated successfully!',
                                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                            ),
                                            backgroundColor: const Color(0xFFFF6B6B),
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(
                                      'Save',
                                      style: GoogleFonts.inter(
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
                    ),
                  ),
                ),
            );
          },
        );
      },
    );
  }

}
