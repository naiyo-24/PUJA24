import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../domain/metro_data.dart';
import '../../../../core/services/places_api_service.dart';

class MetroGuideScreen extends StatefulWidget {
  const MetroGuideScreen({super.key});

  @override
  State<MetroGuideScreen> createState() => _MetroGuideScreenState();
}

class _MetroGuideScreenState extends State<MetroGuideScreen> {
  final PlacesApiService _placesApi = PlacesApiService();
  
  Map<String, dynamic>? _fromPlace;
  Map<String, dynamic>? _toPlace;
  
  String? _nearestFromMetro;
  String? _nearestToMetro;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNearestMetroToUser();
  }

  Future<void> _fetchNearestMetroToUser() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      
      String? nearestMetro;
      double minDistance = double.infinity;
      
      for (var line in MetroData.lines) {
        for (var station in line.stations) {
          double dx = position.latitude - station.lat;
          double dy = position.longitude - station.lng;
          double distance = dx * dx + dy * dy;
          if (distance < minDistance) {
            minDistance = distance;
            nearestMetro = station.name;
          }
        }
      }

      setState(() {
        _nearestFromMetro = nearestMetro;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.deepMaroon : AppColors.ivory,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/metro-map'),
        backgroundColor: AppColors.pujaRed,
        foregroundColor: AppColors.pureWhite,
        icon: const Icon(Icons.map),
        label: const Text('Live Map', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Metro Guide', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: isDark ? AppColors.pureWhite : AppColors.charcoal)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? AppColors.pureWhite : AppColors.charcoal, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Planner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan your journey', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // From Place
                  _buildAutocompleteField(
                    label: 'Start Location',
                    icon: Icons.my_location,
                    iconColor: AppColors.pujaRed,
                    onSelected: (place) => _onPlaceSelected(place, true),
                  ),
                  
                  if (_nearestFromMetro != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 48, top: 4),
                      child: Text('Nearest Metro: $_nearestFromMetro', style: const TextStyle(color: AppColors.pujaRed, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                    child: Icon(Icons.more_vert, color: AppColors.textSecondary.withOpacity(0.5)),
                  ),
                  
                  // To Place
                  _buildAutocompleteField(
                    label: 'Destination',
                    icon: Icons.location_on,
                    iconColor: AppColors.antiqueGold,
                    onSelected: (place) => _onPlaceSelected(place, false),
                  ),
                  
                  if (_nearestToMetro != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 48, top: 4),
                      child: Text('Nearest Metro: $_nearestToMetro', style: const TextStyle(color: AppColors.antiqueGold, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_nearestFromMetro != null && _nearestToMetro != null && !_isLoading) ? () {} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pujaRed,
                        foregroundColor: AppColors.pureWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pureWhite))
                          : const Text('Find Metro Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text('Metro Lines', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Lines List
            ...MetroData.lines.map((line) => _buildLineCard(line, theme, isDark)).toList(),
            const SizedBox(height: 60), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildAutocompleteField({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Function(Map<String, dynamic>) onSelected,
  }) {
    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty || textEditingValue.text.length < 3) {
          return const Iterable<Map<String, dynamic>>.empty();
        }
        return await _placesApi.getAutocomplete(textEditingValue.text);
      },
      displayStringForOption: (option) => option['description'],
      onSelected: onSelected,
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Search $label',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              prefixIcon: Icon(icon, color: iconColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200.0,
              width: MediaQuery.of(context).size.width - 64, // roughly match text field width
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option['description'], style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onPlaceSelected(Map<String, dynamic> place, bool isFrom) async {
    setState(() {
      if (isFrom) _fromPlace = place;
      else _toPlace = place;
      _isLoading = true;
    });

    final latLng = await _placesApi.getPlaceDetails(place['place_id']);
    
    if (latLng != null) {
      // Find nearest metro from our hardcoded list for routing
      String? nearestMetro;
      double minDistance = double.infinity;
      
      for (var line in MetroData.lines) {
        for (var station in line.stations) {
          // Simple euclidean distance approximation for closest station
          double dx = latLng.latitude - station.lat;
          double dy = latLng.longitude - station.lng;
          double distance = dx * dx + dy * dy;
          if (distance < minDistance) {
            minDistance = distance;
            nearestMetro = station.name;
          }
        }
      }

      setState(() {
        if (isFrom) _nearestFromMetro = nearestMetro;
        else _nearestToMetro = nearestMetro;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildLineCard(MetroLine line, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line.color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: line.color,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          line.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${line.stations.first.name} - ${line.stations.last.name}',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: line.color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: line.stations.map((station) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: station.isInterchange ? Colors.white : line.color,
                          border: Border.all(color: line.color, width: 2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        station.name,
                        style: TextStyle(
                          fontWeight: station.isInterchange ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      if (station.isInterchange) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.antiqueGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Interchange', style: TextStyle(fontSize: 10, color: AppColors.antiqueGold, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}
