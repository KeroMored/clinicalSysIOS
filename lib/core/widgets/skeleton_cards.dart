import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonShimmer extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const SkeletonShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE5E7EB),
    this.highlightColor = const Color(0xFFF8FAFC),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1300),
      child: child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
      ),
    );
  }
}

class SkeletonPharmacyCard extends StatelessWidget {
  const SkeletonPharmacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.merge(
          const Border(right: BorderSide(color: Color(0xFFCCFBF1), width: 1)),
          const Border(
            bottom: BorderSide(color: Color(0xFF99F6E4), width: 1.6),
          ),
        ),
      ),
      child: const SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 66, height: 22),
                SkeletonBox(width: 82, height: 22),
              ],
            ),
            SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 36, height: 36),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 160, height: 14),
                      SizedBox(height: 6),
                      SkeletonBox(width: double.infinity, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            SkeletonBox(width: 130, height: 12),
            SizedBox(height: 7),
            SkeletonBox(width: 180, height: 12),
            SizedBox(height: 12),
            SkeletonBox(
              width: double.infinity,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(22)),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonClinicCard extends StatelessWidget {
  const SkeletonClinicCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const SkeletonShimmer(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonBox(width: 74, height: 20),
                      SizedBox(width: 6),
                      SkeletonBox(width: 70, height: 20),
                    ],
                  ),
                  SizedBox(height: 8),
                  SkeletonBox(width: 150, height: 14),
                  SizedBox(height: 5),
                  SkeletonBox(width: 95, height: 12),
                  SizedBox(height: 4),
                  SkeletonBox(width: 190, height: 11),
                  SizedBox(height: 8),
                  SkeletonBox(width: 120, height: 11),
                  SizedBox(height: 8),
                  SkeletonBox(width: 170, height: 11),
                ],
              ),
            ),
            SizedBox(width: 10),
            SkeletonBox(width: 76, height: 76),
          ],
        ),
      ),
    );
  }
}

class SkeletonOfferCard extends StatelessWidget {
  const SkeletonOfferCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              width: double.infinity,
              height: 165,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 60, height: 10),
                  SizedBox(height: 8),
                  SkeletonBox(width: 180, height: 14),
                  SizedBox(height: 6),
                  SkeletonBox(width: double.infinity, height: 11),
                  SizedBox(height: 4),
                  SkeletonBox(width: 160, height: 11),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      SkeletonBox(width: 80, height: 14),
                      Spacer(),
                      SkeletonBox(width: 72, height: 30),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonHorizontalOfferCard extends StatelessWidget {
  const SkeletonHorizontalOfferCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonOfferCard();
  }
}
