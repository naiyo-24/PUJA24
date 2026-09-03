import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/puja_detail_model.dart';
import '../../data/repositories/puja_repository.dart';

final popularPujasProvider = FutureProvider<List<PujaDetailModel>>((ref) async {
  final repository = ref.watch(pujaRepositoryProvider);
  return repository.getPandals(isPopular: true);
});

final filteredPujasProvider = FutureProvider.family<List<PujaDetailModel>, String>((ref, area) async {
  final repository = ref.watch(pujaRepositoryProvider);
  // 'All' usually means no area filter
  if (area == 'All' || area.isEmpty) {
    return repository.getPandals();
  } else if (area == 'Popular') {
    return repository.getPandals(isPopular: true);
  } else {
    return repository.getPandals(area: area);
  }
});

final nearbyPandalsProvider = FutureProvider<List<PujaDetailModel>>((ref) async {
  final repository = ref.watch(pujaRepositoryProvider);
  
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied.');
  } 

  final position = await Geolocator.getCurrentPosition();
  return repository.getPandals(lat: position.latitude, lng: position.longitude);
});
