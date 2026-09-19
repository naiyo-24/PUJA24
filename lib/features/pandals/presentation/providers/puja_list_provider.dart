import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/puja_detail_model.dart';
import '../../data/repositories/puja_repository.dart';

final popularPujasProvider = FutureProvider<List<PujaDetailModel>>((ref) async {
  final repository = ref.watch(pujaRepositoryProvider);
  double? lat, lng;
  try {
    final position = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 5));
    lat = position.latitude;
    lng = position.longitude;
  } catch (e) {
    // ignore if location fails
  }
  return repository.getPandals(isPopular: true, lat: lat, lng: lng);
});

final filteredPujasProvider = FutureProvider.family<List<PujaDetailModel>, String>((ref, area) async {
  final repository = ref.watch(pujaRepositoryProvider);
  double? lat, lng;
  try {
    final position = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 5));
    lat = position.latitude;
    lng = position.longitude;
  } catch (e) {
    // ignore
  }
  
  if (area == 'All' || area.isEmpty) {
    return repository.getPandals(lat: lat, lng: lng);
  } else if (area == 'Popular') {
    return repository.getPandals(isPopular: true, lat: lat, lng: lng);
  } else {
    return repository.getPandals(area: area, lat: lat, lng: lng);
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
    return Future.error('Location permissions are denied');
  }
  
  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied.');
  } 

  final position = await Geolocator.getCurrentPosition();
  return repository.getPandals(lat: position.latitude, lng: position.longitude);
});
