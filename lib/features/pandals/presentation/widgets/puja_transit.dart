import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/puja_detail_model.dart';

import 'package:url_launcher/url_launcher.dart';

class PujaTransit extends StatelessWidget {
  final PujaDetailModel puja;

  const PujaTransit({super.key, required this.puja});

  Future<void> _openMaps(BuildContext context) async {
    if (puja.latitude == 0.0 && puja.longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not available')));
      return;
    }
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${puja.latitude},${puja.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW TO REACH',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.grey,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTransitRow(context, Icons.train, 'Nearest Metro', puja.nearestMetro),
          const SizedBox(height: 12),
          _buildTransitRow(context, Icons.directions_bus, 'Nearest Bus Stop', puja.nearestBusStop),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openMaps(context),
              icon: const Icon(Icons.map),
              label: const Text('Open in Google Maps'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.pujaRed,
                side: const BorderSide(color: AppColors.pujaRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitRow(BuildContext context, IconData icon, String title, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.grey[800], size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
