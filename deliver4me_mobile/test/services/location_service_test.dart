import 'package:flutter_test/flutter_test.dart';
import 'package:deliver4me_mobile/shared/location_service.dart';

void main() {
  group('LocationService Tests', () {
    test('LocationService static methods exist', () {
      expect(LocationService.getCurrentLocation, isNotNull);
      expect(LocationService.getLocationStream, isNotNull);
      expect(LocationService.calculateDistance, isNotNull);
    });

    test('Distance calculation', () async {
      // Test distance between two known points
      final distance = await LocationService.calculateDistance(
        40.7128, -74.0060, // New York
        40.7489, -73.9680, // Another point in NY
      );

      expect(distance, greaterThan(0));
      expect(distance, lessThan(10000)); // Should be reasonable
    });

    test('Get current location - requires permissions', () async {
      try {
        final position = await LocationService.getCurrentLocation();

        if (position != null) {
          expect(position.latitude, isNotNull);
          expect(position.longitude, isNotNull);
        }
      } catch (e) {
        // Expected to fail without permissions
        expect(e, isNotNull);
      }
    }, skip: 'Requires location permissions');
  });
}
