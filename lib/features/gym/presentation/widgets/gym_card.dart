import 'package:flutter/material.dart';

import '../../data/models/gym_model.dart';

class GymCard extends StatelessWidget {
  final GymModel gym;
  final VoidCallback onTap;
  final String? distance;
  final bool isOpen;

  const GymCard({
    super.key,
    required this.gym,
    required this.onTap,
    required this.isOpen,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOpen ? 'متاح الآن' : 'مغلق الآن',
                              style: TextStyle(
                                fontSize: 10,
                                color: isOpen
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (distance != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'يبعد $distance',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF0369A1),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        gym.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildGymSectionsText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gym.description,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            gym.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.favorite_rounded,
                            size: 12,
                            color: Color(0xFFE11D48),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${gym.totalLikes}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Color(0xFF0B8293),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              gym.address,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF0F172A),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildGymImage(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildGymSectionsText() {
    if (gym.hasMaleSection && gym.hasFemaleSection) {
      return ' رجالي ونسائي';
    }
    if (gym.hasMaleSection) {
      return 'قسم رجالي';
    }
    if (gym.hasFemaleSection) {
      return 'قسم نسائي';
    }
    return 'جيم';
  }

  Widget _buildGymImage() {
    final imageUrl = gym.logoUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildGymImagePlaceholder();
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return _buildGymImagePlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildGymImagePlaceholder();
      },
    );
  }

  Widget _buildGymImagePlaceholder() {
    return Container(
      color: const Color(0xFF0B8293),
      child: const Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
