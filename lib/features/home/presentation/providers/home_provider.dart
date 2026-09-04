import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/banner_model.dart';
import '../../data/repositories/home_repository.dart';

final bannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);

  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
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
  return repository.getBanners(position.latitude, position.longitude);
});
