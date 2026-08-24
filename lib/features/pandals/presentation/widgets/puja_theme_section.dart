import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PujaThemeSection extends StatelessWidget {
  const PujaThemeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2026 PUJA',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.grey,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Theme', 'Heritage of Bengal'),
          const SizedBox(height: 12),
          Text(
            'This year, Ekdalia Evergreen explores the rich cultural heritage of Bengal, highlighting the lost art forms and traditional practices from the 18th century...',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Idol Artist', 'Sanatan Rudra Pal'),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Pandal Designer', 'Theme Makers Inc.'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
