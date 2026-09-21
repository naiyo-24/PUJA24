import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/banner_model.dart';
import '../../data/repositories/home_repository.dart';

final bannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);

  double lat = 22.5726; // Kolkata default
  double lng = 88.3639;

  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 5),
        );
        lat = position.latitude;
        lng = position.longitude;
      }
    }
  } catch (e) {
    // Ignore location errors and use fallback
  }

  return repository.getBanners(lat, lng);
});
