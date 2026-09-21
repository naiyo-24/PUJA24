import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/puja_detail_model.dart';
import '../../data/repositories/puja_repository.dart';

final popularPujasProvider = FutureProvider<List<PujaDetailModel>>((ref) async {
  final repository = ref.watch(pujaRepositoryProvider);
  double? lat, lng;
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      final position = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 5));
      lat = position.latitude;
      lng = position.longitude;
    }
  } catch (e) {
    // ignore if location fails
  }
  return repository.getPandals(isPopular: true, lat: lat, lng: lng);
});

final pandalSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredPujasProvider = FutureProvider.family<List<PujaDetailModel>, String>((ref, area) async {
  final repository = ref.watch(pujaRepositoryProvider);
  double? lat, lng;
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      final position = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 5));
      lat = position.latitude;
      lng = position.longitude;
    }
  } catch (e) {
    // ignore location errors
  }
  
  final searchQuery = ref.watch(pandalSearchQueryProvider).toLowerCase();
  List<PujaDetailModel> pandals;

  if (area == 'All' || area.isEmpty) {
    pandals = await repository.getPandals(lat: lat, lng: lng);
  } else if (area == 'Popular') {
    pandals = await repository.getPandals(isPopular: true, lat: lat, lng: lng);
  } else {
    pandals = await repository.getPandals(area: area, lat: lat, lng: lng);
  }

  if (searchQuery.isNotEmpty) {
    return pandals.where((p) => p.name.toLowerCase().contains(searchQuery) || p.area.toLowerCase().contains(searchQuery)).toList();
  }
  
  return pandals;
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
