import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final bool showUserLocation;
  final VoidCallback? onMapTap;

  const MapWidget({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.markers = const [],
    this.polylines = const [],
    this.showUserLocation = false,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onTap: onMapTap != null ? (_, __) => onMapTap!() : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.deliver4me.app',
          maxZoom: 19,
        ),
        if (polylines.isNotEmpty)
          PolylineLayer(
            polylines: polylines,
          ),
        if (markers.isNotEmpty)
          MarkerLayer(
            markers: markers,
          ),
      ],
    );
  }

  static Marker buildMarker({
    required LatLng point,
    required Widget child,
    double width = 40,
    double height = 40,
  }) {
    return Marker(
      width: width,
      height: height,
      point: point,
      child: child,
    );
  }

  static Polyline buildPolyline({
    required List<LatLng> points,
    Color color = const Color(0xFF135BEC),
    double strokeWidth = 4.0,
  }) {
    return Polyline(
      points: points,
      strokeWidth: strokeWidth,
      color: color,
    );
  }
}
