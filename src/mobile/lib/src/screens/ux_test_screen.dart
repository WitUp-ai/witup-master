import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart';

class UxTestScreen extends StatelessWidget {
  const UxTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero Box with Mix styling
            Box(
              style: Style(
                $box.width(300),
                $box.height(200),
                $box.padding(24),
                $box.color.black(),
                $box.borderRadius(24),
                $box.shadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rocket_launch,
                    size: 48,
                    color: const Color(0xFF6366F1),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.5, 0.5)),
                  const Gap(16),
                  Text(
                    'Mobile Engine Ready',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.3, end: 0),
                  const Gap(8),
                  Text(
                    'Mix + Animate + Rive',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6366F1),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.3, end: 0),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const Gap(40),
            
            // Status indicators
            _StatusChip(
              label: 'Mix Engine',
              icon: Icons.layers,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 600.ms)
                .slideX(begin: -0.2, end: 0),
            const Gap(12),
            _StatusChip(
              label: 'Flutter Animate',
              icon: Icons.animation,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 700.ms)
                .slideX(begin: -0.2, end: 0),
            const Gap(12),
            _StatusChip(
              label: 'Google Fonts',
              icon: Icons.text_fields,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 800.ms)
                .slideX(begin: -0.2, end: 0),
            const Gap(12),
            _StatusChip(
              label: 'Rive Graphics',
              icon: Icons.auto_awesome,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 900.ms)
                .slideX(begin: -0.2, end: 0),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Box(
      style: Style(
        $box.padding.horizontal(20),
        $box.padding.vertical(12),
        $box.color.white(),
        $box.borderRadius(12),
        $box.shadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF10B981), // Green success
          ),
          const Gap(8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Gap(8),
          Icon(
            Icons.check_circle,
            size: 18,
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}
