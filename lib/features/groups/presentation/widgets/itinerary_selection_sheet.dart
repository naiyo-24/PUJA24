import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pandals/providers/pandals_list_provider.dart';

class ItinerarySelectionSheet extends ConsumerStatefulWidget {
  final Function(List<Map<String, dynamic>>) onItineraryShared;

  const ItinerarySelectionSheet({
    super.key,
    required this.onItineraryShared,
  });

  @override
  ConsumerState<ItinerarySelectionSheet> createState() => _ItinerarySelectionSheetState();
}

class _ItinerarySelectionSheetState extends ConsumerState<ItinerarySelectionSheet> {
  final List<Map<String, dynamic>> _selectedPandals = [];
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final pandalsAsync = ref.watch(allPandalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Build Itinerary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search pandals...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // List
          Expanded(
            child: pandalsAsync.when(
              data: (pandals) {
                final filtered = pandals.where((p) {
                  final name = (p['name'] ?? '').toString().toLowerCase();
                  final area = (p['area'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || area.contains(_searchQuery);
                }).toList();
                
                if (filtered.isEmpty) {
                  return const Center(child: Text('No pandals found.'));
                }
                
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final pandal = filtered[index];
                    final isSelected = _selectedPandals.any((p) => p['id'] == pandal['id']);
                    
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: CircleAvatar(
                        backgroundColor: AppColors.saffron.withOpacity(0.2),
                        child: Text(
                          (pandal['name'] as String?)?.characters.first ?? 'P',
                          style: const TextStyle(color: AppColors.pujaRed),
                        ),
                      ),
                      title: Text(pandal['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(pandal['area'] ?? ''),
                      trailing: Checkbox(
                        value: isSelected,
                        activeColor: AppColors.pujaRed,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedPandals.add(pandal);
                            } else {
                              _selectedPandals.removeWhere((p) => p['id'] == pandal['id']);
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedPandals.removeWhere((p) => p['id'] == pandal['id']);
                          } else {
                            _selectedPandals.add(pandal);
                          }
                        });
                      },
                    ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.pujaRed)),
              error: (err, stack) => Center(child: Text('Error loading pandals: $err')),
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedPandals.length} selected',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectedPandals.isEmpty ? null : () {
                    widget.onItineraryShared(_selectedPandals);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pujaRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Share Itinerary', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
