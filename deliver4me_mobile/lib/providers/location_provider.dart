import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:deliver4me_mobile/shared/location_service.dart';

// Current location provider
final currentLocationProvider = StreamProvider<Position?>((ref) {
  return LocationService.getLocationStream();
});

// Single location fetch
final fetchLocationProvider = FutureProvider<Position?>((ref) {
  return LocationService.getCurrentLocation();
});
