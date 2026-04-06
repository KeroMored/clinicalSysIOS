import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ModernPharmacyCard extends StatefulWidget {
  final String title;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const ModernPharmacyCard({
    super.key,
    required this.title,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<ModernPharmacyCard> createState() => _ModernPharmacyCardState();
}

class _ModernPharmacyCardState extends State<ModernPharmacyCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 360
        ? 40.0
        : (screenWidth > 600 ? 72.0 : 48.0);
    final padding = screenWidth < 360
        ? 16.0
        : (screenWidth > 600 ? 28.0 : 20.0);
    final fontSize = screenWidth < 360
        ? 15.0
        : (screenWidth > 600 ? 22.0 : 17.0);
    final iconInnerSize = iconSize * 0.5;

    return AspectRatio(
      aspectRatio: 0.85,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          scale: _isPressed ? 0.98 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color:
                      (_isHovered ? widget.gradient.colors.first : Colors.black)
                          .withValues(alpha: _isHovered ? 0.14 : 0.06),
                  blurRadius: _isHovered ? 22 : 14,
                  offset: Offset(0, _isHovered ? 10 : 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapCancel: () => setState(() => _isPressed = false),
                onTapUp: (_) => setState(() => _isPressed = false),
                splashColor: widget.gradient.colors.first.withValues(
                  alpha: 0.12,
                ),
                highlightColor: widget.gradient.colors.first.withValues(
                  alpha: 0.06,
                ),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          gradient: widget.gradient,
                          borderRadius: BorderRadius.circular(
                            screenWidth > 600 ? 16 : 12,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradient.colors.first.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: screenWidth > 600 ? 12 : 8,
                              offset: Offset(0, screenWidth > 600 ? 6 : 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/pharmacy.svg',
                            width: iconInnerSize,
                            height: iconInnerSize,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenWidth > 600 ? 12 : 8),
                      Row(
                        children: [
                          Text(
                            'استكشف',
                            style: TextStyle(
                              fontSize: screenWidth > 600 ? 16 : 13,
                              fontWeight: FontWeight.w600,
                              color: widget.gradient.colors.first,
                            ),
                          ),
                          SizedBox(width: screenWidth > 600 ? 6 : 4),
                          Icon(
                            Icons.arrow_forward,
                            size: screenWidth > 600 ? 20 : 16,
                            color: widget.gradient.colors.first,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
