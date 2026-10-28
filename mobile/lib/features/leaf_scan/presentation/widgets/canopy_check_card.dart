import 'package:flutter/material.dart';
import 'package:digisaka/core/theme/app_colors.dart';

class CanopyCheckCard extends StatelessWidget {
  final int leaves;
  final int critical;
  final int target;
  const CanopyCheckCard({
    super.key,
    required this.leaves,
    required this.critical,
    required this.target,
  });

  static const _red = Color(0xFFB3261E);
  static const _green = Color(0xFF1E7D3A);
  static const _gold = Color(0xFF8A6A00);

  @override
  Widget build(BuildContext context) {
    final Color fill = leaves < critical ? _red : (leaves >= target ? _green : _gold);
    final String verdict = leaves < critical
        ? 'Below the critical level (R3: act).'
        : (leaves >= target
            ? 'At or above the target.'
            : 'Below the target, above the critical level (R3: watch).');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Canopy check',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE9C6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Provisional',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7A5200))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, cons) {
            final double w = cons.maxWidth;
            final double maxScale = target * 1.15;
            double pos(num v) => (v / maxScale).clamp(0.0, 1.0) * w;
            const double labelW = 70;
            double labelLeft(double p) => (p - labelW / 2).clamp(0.0, w - labelW);

            return SizedBox(
              width: w,
              height: 52,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track + fill (rounded, fill clipped by the track).
                  Positioned(
                    left: 0, right: 0, top: 8, height: 14,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Stack(children: [
                        Container(color: const Color(0xFFE3E6E1)),
                        Positioned(left: 0, top: 0, bottom: 0, width: pos(leaves),
                            child: Container(color: fill)),
                      ]),
                    ),
                  ),
                  // Markers (taller than the bar).
                  Positioned(left: pos(critical) - 1, top: 3,
                      child: Container(width: 2, height: 24, color: _red)),
                  Positioned(left: pos(target) - 1, top: 3,
                      child: Container(width: 2, height: 24, color: _green)),
                  // Labels under the markers.
                  Positioned(left: labelLeft(pos(critical)), top: 32, width: labelW,
                      child: Text('$critical critical', textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _red))),
                  Positioned(left: labelLeft(pos(target)), top: 32, width: labelW,
                      child: Text('$target target', textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _green))),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.35),
              children: [
                TextSpan(text: '$leaves leaves.', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' $verdict'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
