import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/water_provider.dart';
import 'glass_card.dart';
import 'wave_empty_state.dart';

class LogHistory extends ConsumerWidget {
  const LogHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(waterProvider);
    final notifier = ref.read(waterProvider.notifier);
    final reversedLogs = state.logs.reversed.toList();

    if (reversedLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const WaveEmptyState(size: 130),
              const SizedBox(height: 24),
              Text(
                'A fresh start!',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff331A1A).withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap a quick add button to log your first\nglass of water today.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff331A1A).withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(1),
      borderRadius: 24,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reversedLogs.length,
          padding: EdgeInsets.zero,
          separatorBuilder: (context, index) => Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          itemBuilder: (context, index) {
            final log = reversedLogs[index];
            
            // Calculate time ago
            final diff = DateTime.now().difference(log.timestamp);
            String timeAgo = '';
            if (diff.inMinutes < 60) {
              timeAgo = '${diff.inMinutes} mins ago';
            } else if (diff.inHours < 24) {
              timeAgo = '${diff.inHours} hours ago';
            } else {
              timeAgo = DateFormat.jm().format(log.timestamp);
            }
            if (diff.inMinutes == 0) {
              timeAgo = 'just now';
            }

            return Container(
              color: Colors.white.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: Color(0xFFFF6B6B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Water Intake',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff331A1A),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${log.amount}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xff331A1A),
                                letterSpacing: 0.5,
                              ),
                            ),
                            TextSpan(
                              text: ' ml',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff331A1A).withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: Text(
                          timeAgo,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff331A1A).withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          notifier.removeLog(log.id);
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: const Color(0xff331A1A).withValues(alpha: 0.3),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
