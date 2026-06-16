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
import '../widgets/glass_card.dart';
import '../widgets/daily_progress.dart';
import '../widgets/log_history.dart';

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

    // Calculate glasses (assuming 1 glass = 250ml)
    final int glasses = (state.currentIntake / 250).floor();

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
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xffe1f5fe),
                        Color(0xffe8eaf6),
                        Color(0xffffffff),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Translucent floating blobs
                Positioned(
                  top: -40,
                  left: -30,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xff80deea).withValues(alpha: 0.35),
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
                      color: const Color(0xff90caf9).withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Water Tracker',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xff0d47a1),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Daily Goal: ${state.dailyGoal} ml',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff1565c0).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Settings Button
                          IconButton(
                            tooltip: 'Settings',
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Icon(
                                Icons.settings_rounded,
                                color: Color(0xff0d47a1),
                                size: 22,
                              ),
                            ),
                            onPressed: () => _showSettingsDialog(context, state.dailyGoal, state.remindersEnabled, notifier),
                          ),
                          const SizedBox(width: 8),
                          // Reset Button
                          IconButton(
                            tooltip: 'Reset Progress',
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xff0d47a1),
                                size: 22,
                              ),
                            ),
                            onPressed: () => _confirmReset(context, notifier),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Center Radial Progress
                  Center(
                    child: RepaintBoundary(
                      child: DailyProgress(
                        currentIntake: state.currentIntake,
                        dailyGoal: state.dailyGoal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Summary Glass Card
                  Center(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      borderRadius: 30,
                      child: Text(
                        '$glasses glasses · ${state.currentIntake} ml of ${state.dailyGoal} ml',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff0d47a1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // History Section
                  Text(
                    "Today's Logs",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff0d47a1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const LogHistory(),
                  const SizedBox(height: 100), // padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildGlassFAB(context, notifier),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildGlassFAB(BuildContext context, WaterNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xff4fc3f7).withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.white.withValues(alpha: 0.2),
            shape: CircleBorder(
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: () {
                notifier.addWater(250);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added 250 ml of water!',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: const Color(0xff1976d2).withValues(alpha: 0.85),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              },
              splashColor: Colors.white.withValues(alpha: 0.3),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Icon(
                  Icons.add_rounded,
                  size: 36,
                  color: Color(0xff0d47a1),
                ),
              ),
            ),
          ),
        ),
      ),
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
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xff0d47a1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set your target daily water intake (in ml).',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff1565c0).withValues(alpha: 0.8),
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
                              suffixStyle: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff1565c0),
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
                                  color: Color(0xff1e88e5),
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
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xff0d47a1),
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
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xff0d47a1),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Check schedule every 2 hours',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xff1565c0).withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: remindersEnabled,
                                  activeThumbColor: const Color(0xff1e88e5),
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
                                color: Colors.blue.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    color: Color(0xff1e88e5),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Reminders powered locally',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xff0d47a1),
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
                                  side: const BorderSide(color: Color(0xff1e88e5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _triggerTestReminder();
                                },
                                icon: const Icon(Icons.notifications_active_rounded, color: Color(0xff1e88e5), size: 18),
                                label: Text(
                                  'Trigger Test Reminder',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xff1e88e5),
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
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xff1e88e5),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff1e88e5),
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
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                            ),
                                            backgroundColor: const Color(0xff1e88e5),
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(
                                      'Save',
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
                    ),
                  ),
                ),
            );
          },
        );
      },
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
                      'Clear today\'s history?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff1565c0).withValues(alpha: 0.8),
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
                                color: const Color(0xff1e88e5),
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
            ),
          ),
        );
      },
    );
  }
}
