import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/water_provider.dart';
import 'glass_button.dart';

class QuickAddRow extends ConsumerWidget {
  const QuickAddRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(waterProvider.notifier);

    final List<Map<String, dynamic>> options = [
      {'amount': 250, 'label': '250ml', 'icon': Icons.water_drop_rounded},
      {'amount': 500, 'label': '500ml', 'icon': Icons.water_drop_rounded},
      {'amount': 750, 'label': '750ml', 'icon': Icons.water_drop_rounded},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ...options.map((opt) {
          final int amt = opt['amount'] as int;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: GlassButton(
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
                onTap: () {
                  notifier.addWater(amt);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Added $amt ml of water!',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: const Color(0xFFFF6B6B).withValues(alpha: 0.85),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt['icon'] as IconData,
                      color: const Color(0xFFFF6B6B),
                      size: 20,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      opt['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff331A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

}
