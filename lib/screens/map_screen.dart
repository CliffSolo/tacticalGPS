import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../theme/catppuccin.dart';
import '../utils/app_state.dart';
import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  final double currentLat;
  final double currentLon;
  final double heading;

  const MapScreen({
    super.key,
    required this.currentLat,
    required this.currentLon,
    required this.heading,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  Widget _circle(Color borderColor, Widget child) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CatppuccinMocha.yellow.withOpacity(0.70),
            border: Border.all(
              color: CatppuccinMocha.yellow.withOpacity(0.70),
              width: 2,
            ),
          ),
        ),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final myPos = LatLng(widget.currentLat, widget.currentLon);

    // Bearing lines
    List<Polyline> bearingLines = [];
    for (final wp in appState.waypoints) {
      bearingLines.add(Polyline(
        points: [myPos, LatLng(wp.latitude, wp.longitude)],
        color: wp.color.withOpacity(0.7),
        strokeWidth: 2,
        pattern: StrokePattern.dashed(segments: [8, 4]),
      ));
    }
    if (appState.hasDestination) {
      bearingLines.add(Polyline(
        points: [myPos, LatLng(appState.destLat!, appState.destLon!)],
        color: CatppuccinMocha.peach.withOpacity(0.7),
        strokeWidth: 2,
        pattern: StrokePattern.dashed(segments: [8, 4]),
      ));
    }

    // Markers
    List<Marker> markers = [];

    // My location
    markers.add(Marker(
      point: myPos,
      width: 80,
      height: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circle(
            CatppuccinMocha.blue,
            Transform.rotate(
              angle: widget.heading * math.pi / 180,
              child: Icon(Icons.navigation_rounded,
                  color: CatppuccinMocha.blue, size: 26),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: CatppuccinMocha.base.withOpacity(0.9),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text('YOU',
                style: TextStyle(
                    color: CatppuccinMocha.blue,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace')),
          ),
        ],
      ),
    ));

    // Waypoints
    for (final wp in appState.waypoints) {
      markers.add(Marker(
        point: LatLng(wp.latitude, wp.longitude),
        width: 90,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circle(
              wp.color,
              Icon(Icons.flag_rounded, color: wp.color, size: 24),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: CatppuccinMocha.base.withOpacity(0.9),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: wp.color.withOpacity(0.5)),
              ),
              child: Text(
                wp.name,
                style: TextStyle(
                    color: wp.color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ));
    }

    // Destination
    if (appState.hasDestination) {
      markers.add(Marker(
        point: LatLng(appState.destLat!, appState.destLon!),
        width: 110,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circle(
              CatppuccinMocha.peach,
              Icon(Icons.location_on_rounded,
                  color: CatppuccinMocha.peach, size: 26),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: CatppuccinMocha.base.withOpacity(0.9),
                borderRadius: BorderRadius.circular(3),
                border:
                    Border.all(color: CatppuccinMocha.peach.withOpacity(0.5)),
              ),
              child: Text(
                appState.destLabel,
                style: TextStyle(
                    color: CatppuccinMocha.peach,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ));
    }

    return Scaffold(
      backgroundColor: CatppuccinMocha.base,
      appBar: AppBar(
        backgroundColor: CatppuccinMocha.mantle,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: CatppuccinMocha.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('MAP',
            style: TextStyle(
                color: CatppuccinMocha.blue,
                letterSpacing: 4,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location, color: CatppuccinMocha.blue),
            onPressed: () => _mapController.move(myPos, 16),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: myPos,
          initialZoom: 16,
          backgroundColor: CatppuccinMocha.base,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.tactical_compass',
          ),
          if (bearingLines.isNotEmpty)
            PolylineLayer(polylines: bearingLines),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
