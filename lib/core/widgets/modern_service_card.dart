import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern card widget with gradient, shadows, and rounded corners
/// Consistent design across all service cards (clinics, pharmacy, etc.)
class ModernServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final LinearGradient gradient;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? badge;
  final EdgeInsetsGeometry? padding;

  const ModernServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.gradient,
    this.icon,
    this.onTap,
    this.trailing,
    this.badge,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with gradient background
            if (icon != null)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A5F),
                          ),
                        ),
                      ),
                      if (badge != null) badge!,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: const Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),

            // Trailing widget
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Color(0xFF7F8C8D),
              ),
          ],
        ),
      ),
    );
  }
}

/// Status badge for open/closed/approved/pending etc.
class StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.text,
    this.backgroundColor = const Color(0xFF10B981),
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Distance badge for location-based sorting
class DistanceBadge extends StatelessWidget {
  final String distance;

  const DistanceBadge({super.key, required this.distance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 14, color: Color(0xFF00BCD4)),
          const SizedBox(width: 4),
          Text(
            distance,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF00BCD4),
            ),
          ),
        ],
      ),
    );
  }
}
