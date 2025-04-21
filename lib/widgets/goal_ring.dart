import 'package:flutter/material.dart';


class GoalRingWidget extends StatelessWidget {
  final String title;
  final String centreLabel;
  final double progress; // Value between 0 and 1
  final List<Map<String, String>> metrics;
  final Map<String, Color>? metricColors;
  final VoidCallback onTap;



  const GoalRingWidget({
    super.key,
    required this.title,
    required this.centreLabel,
    required this.progress,
    required this.metrics,
    required this.metricColors,
    required this.onTap,
  });

  Color _getColorForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'calories':
        return Colors.indigo.shade600;
      case 'water':
        return Colors.blue.shade400;
      case 'sleep':
        return Colors.purple.shade300;
      default:
        return Colors.blueAccent;
    }
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'calories':
        return Icons.local_fire_department;
      case 'water':
        return Icons.water_drop;
      case 'sleep':
        return Icons.bedtime;
      default:
        return Icons.insights;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForTitle(title);
    final icon = _getIconForTitle(title);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade300,
                      color: color,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    centreLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: metrics.map((metric) {
                final label = metric.keys.first;
                final value = metric.values.first;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: metricColors?[label] ?? Colors.black87,                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
