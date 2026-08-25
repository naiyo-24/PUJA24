import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/puja_detail_model.dart';

class PujaFacilities extends StatelessWidget {
  final PujaDetailModel puja;

  const PujaFacilities({super.key, required this.puja});

  IconData _getIconForAmenity(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wheelchair':
        return Icons.accessible;
      case 'parking':
        return Icons.local_parking;
      case 'first aid':
        return Icons.medical_services;
      case 'washroom':
        return Icons.wc;
      case 'vip entry':
        return Icons.star;
      case 'drinking water':
        return Icons.water_drop;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (puja.amenities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FACILITIES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.grey,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: puja.amenities.map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIconForAmenity(amenity),
                      size: 18,
                      color: AppColors.pujaRed,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      amenity,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
