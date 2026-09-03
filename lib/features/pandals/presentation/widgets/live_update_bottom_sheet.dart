import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/puja_detail_model.dart';
import '../../data/repositories/puja_repository.dart';

class LiveUpdateBottomSheet extends ConsumerStatefulWidget {
  final PujaDetailModel puja;
  final Function(String rainStatus, String crowdStatus)? onUpdate;

  const LiveUpdateBottomSheet({super.key, required this.puja, this.onUpdate});

  static void show(BuildContext context, PujaDetailModel puja, {Function(String rainStatus, String crowdStatus)? onUpdate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LiveUpdateBottomSheet(puja: puja, onUpdate: onUpdate),
    );
  }

  @override
  ConsumerState<LiveUpdateBottomSheet> createState() => _LiveUpdateBottomSheetState();
}

class _LiveUpdateBottomSheetState extends ConsumerState<LiveUpdateBottomSheet> {
  int _selectedRain = 0; // 0: No rain, 1: Drizzle, 2: Raining, 3: Heavy rain
  double _crowdLevel = 5.0;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _rainOptions = [
    {'title': 'Clear', 'icon': Icons.wb_sunny_outlined, 'activeColor': Colors.orange},
    {'title': 'Drizzle', 'icon': Icons.grain, 'activeColor': Colors.lightBlue},
    {'title': 'Raining', 'icon': Icons.water_drop_outlined, 'activeColor': Colors.blue},
    {'title': 'Heavy rain', 'icon': Icons.thunderstorm_outlined, 'activeColor': Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if available
    _selectedRain = _rainOptions.indexWhere((opt) => opt['title'] == widget.puja.rainStatus);
    if (_selectedRain == -1) _selectedRain = 0;

    if (widget.puja.crowdStatus == 'High') _crowdLevel = 9.0;
    else if (widget.puja.crowdStatus == 'Low') _crowdLevel = 2.0;
    else _crowdLevel = 5.0;
  }

  String _getCrowdLabel(int level) {
    if (level <= 3) return 'Low';
    if (level <= 7) return 'Moderate';
    return 'High';
  }

  String _getCrowdDescription(int level) {
    if (level <= 3) return 'Very little queue, easy entry.';
    if (level <= 7) return 'A short queue, moving steadily.';
    return 'Heavy crowd, expect long wait times.';
  }

  Future<void> _submitUpdate() async {
    setState(() => _isSubmitting = true);
    final repo = ref.read(pujaRepositoryProvider);
    
    final rainStatus = _rainOptions[_selectedRain]['title'];
    final crowdStatus = _getCrowdLabel(_crowdLevel.toInt());
    
    final success = await repo.submitLiveUpdate(widget.puja.id, rainStatus, crowdStatus);
    
    if (mounted) {
      Navigator.pop(context);
      if (success) {
        widget.onUpdate?.call(rainStatus, crowdStatus);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Update shared with others!' : 'Failed to submit update.')),
      );
    }
  }

  Color _getCrowdColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 7) return AppColors.antiqueGold;
    return AppColors.pujaRed;
  }

  @override
  Widget build(BuildContext context) {
    final crowdColor = _getCrowdColor(_crowdLevel.toInt());
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 12, 
        left: 24, 
        right: 24, 
        bottom: 120 + MediaQuery.of(context).viewInsets.bottom, // avoid bottom nav bar
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Header Row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Share live update',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 34), // Balance the close button
            ],
          ),
          const SizedBox(height: 24),
          
          // Pandal Info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.pujaRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.temple_hindu, color: AppColors.pujaRed),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.puja.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          widget.puja.area,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Text(
            'Your update helps other pujo lovers. Valid for 30 minutes.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 32),
          
          // Rain Status
          Row(
            children: [
              const Icon(Icons.water_drop_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text('Rain status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              final isSelected = _selectedRain == index;
              final option = _rainOptions[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRain = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? (option['activeColor'] as Color).withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? (option['activeColor'] as Color) : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          option['icon'],
                          color: isSelected ? option['activeColor'] : Colors.blueGrey,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          option['title'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? option['activeColor'] : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 32),
          
          // Crowd Level
          Row(
            children: [
              const Icon(Icons.people_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text('Crowd level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_crowdLevel.toInt()}/10',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: crowdColor),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCrowdLabel(_crowdLevel.toInt()),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: crowdColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCrowdDescription(_crowdLevel.toInt()),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: crowdColor,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: crowdColor,
              trackHeight: 8,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: _crowdLevel,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) {
                setState(() {
                  _crowdLevel = val;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(10, (index) {
                return Text('${index + 1}', style: TextStyle(color: Colors.grey.shade500, fontSize: 10));
              }),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Info Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.ivory,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Only users near or recently at this pandal can update.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitUpdate,
              icon: _isSubmitting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send, color: Colors.white, size: 16),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit update', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pujaRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'Not now',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
