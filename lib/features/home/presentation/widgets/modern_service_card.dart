import 'package:flutter/material.dart';

class ModernServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const ModernServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // أحجام responsive حسب عرض الشاشة
    final iconSize = screenWidth < 360 ? 40.0 : (screenWidth > 600 ? 72.0 : 48.0);
    final padding = screenWidth < 360 ? 16.0 : (screenWidth > 600 ? 28.0 : 20.0);
    final fontSize = screenWidth < 360 ? 15.0 : (screenWidth > 600 ? 22.0 : 17.0);
    final iconInnerSize = iconSize * 0.5;
    
    return AspectRatio(
      aspectRatio: 1.05,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with gradient background
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF06B6D4),
                          Color(0xFF0891B2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(screenWidth > 600 ? 16 : 12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withOpacity(0.3),
                          blurRadius: screenWidth > 600 ? 12 : 8,
                          offset: Offset(0, screenWidth > 600 ? 6 : 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: iconInnerSize,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenWidth > 600 ? 12 : 8),
                  // Arrow with subtle background
                  Row(
                    children: [
                      Text(
                        'استكشف',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 16 : 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF06B6D4),
                        ),
                      ),
                      SizedBox(width: screenWidth > 600 ? 6 : 4),
                      Icon(
                        Icons.arrow_forward,
                        size: screenWidth > 600 ? 20 : 16,
                        color: const Color(0xFF06B6D4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
