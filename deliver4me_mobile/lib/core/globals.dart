// Deliver4Me Global Constants and Configuration

class AppConstants {
  // App Info
  static const String appName = 'Deliver4Me';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Connecting parcels to people, instantly.';

  // Colors
  static const int primaryBlue = 0xFF135BEC;
  static const int backgroundDark = 0xFF101622;
  static const int surfaceDark = 0xFF1C2433;
  static const int borderDark = 0xFF324467;

  // Map Configuration
  static const String mapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const double defaultMapZoom = 15.0;
  static const int maxMapZoom = 19;

  // Location
  static const double defaultLatitude = 40.7128; // New York
  static const double defaultLongitude = -74.0060;
  static const int locationUpdateInterval = 3; // seconds

  // API Endpoints (configure when backend is ready)
  static const String baseUrl = 'https://api.deliver4me.com';
  static const String apiVersion = 'v1';
}
