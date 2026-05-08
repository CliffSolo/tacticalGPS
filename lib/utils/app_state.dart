

import 'package:flutter/material.dart';
import 'waypoint.dart';

// Settings enums
enum AppThemeMode { catppuccin, tacticalGreen }
enum UnitSystem { imperial, metric }


class DroppedPin {
  final String name;
  final double latitude;
  final double longitude;
  final double altitude;
  final Color color;
  final DateTime timestamp;
  final String address;
  final String mgrs;
  final String latDMS;
  final String lonDMS;

  DroppedPin({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.color,
    required this.timestamp,
    this.address = '',
    this.mgrs = '',
    this.latDMS = '',
    this.lonDMS = '',
  });
}

class AppState extends ChangeNotifier {
  List<Waypoint> waypoints = [];
  List<DroppedPin> pins = [];
  List<String> recentWaypointNames = [];

  // Settings
  AppThemeMode themeMode = AppThemeMode.catppuccin;
  UnitSystem unitSystem = UnitSystem.imperial;

  void setTheme(AppThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void setUnitSystem(UnitSystem system) {
    unitSystem = system;
    notifyListeners();
  }
  double? destLat;
  double? destLon;
  double? destAlt;
  String destLabel = '';
  String destAddress = '';
  String destMGRS = '';
  String destLatDMS = '';
  String destLonDMS = '';
  String destElevation = '';
  bool hasDestination = false;

  void addWaypoint(Waypoint wp) {
    waypoints.add(wp);
    // Save to recent history (max 10, no duplicates)
    recentWaypointNames.remove(wp.name);
    recentWaypointNames.insert(0, wp.name);
    if (recentWaypointNames.length > 10) {
      recentWaypointNames = recentWaypointNames.sublist(0, 10);
    }
    notifyListeners();
  }

  void removeWaypoint(int index) {
    waypoints.removeAt(index);
    notifyListeners();
  }

  void renameWaypoint(int index, String newName) {
    final wp = waypoints[index];
    waypoints[index] = Waypoint(
      name: newName,
      latitude: wp.latitude,
      longitude: wp.longitude,
      altitude: wp.altitude,
      color: wp.color,
      timestamp: wp.timestamp,
      address: wp.address,
      mgrs: wp.mgrs,
      latDMS: wp.latDMS,
      lonDMS: wp.lonDMS,
    );
    notifyListeners();
  }

  void addPin(DroppedPin pin) {
    pins.add(pin);
    notifyListeners();
  }

  void removePin(int index) {
    pins.removeAt(index);
    notifyListeners();
  }

  void renamePin(int index, String newName) {
    final pin = pins[index];
    pins[index] = DroppedPin(
      name: newName,
      latitude: pin.latitude,
      longitude: pin.longitude,
      altitude: pin.altitude,
      color: pin.color,
      timestamp: pin.timestamp,
      address: pin.address,
      mgrs: pin.mgrs,
      latDMS: pin.latDMS,
      lonDMS: pin.lonDMS,
    );
    notifyListeners();
  }

  void setDestination({
    required double lat,
    required double lon,
    required String label,
    String address = '',
    String mgrs = '',
    String latDMS = '',
    String lonDMS = '',
    String elevation = '',
    double alt = 0,
  }) {
    destLat = lat;
    destLon = lon;
    destAlt = alt;
    destLabel = label;
    destAddress = address;
    destMGRS = mgrs;
    destLatDMS = latDMS;
    destLonDMS = lonDMS;
    destElevation = elevation;
    hasDestination = true;
    notifyListeners();
  }

  void clearDestination() {
    destLat = null;
    destLon = null;
    destAlt = null;
    destLabel = '';
    destAddress = '';
    destMGRS = '';
    destLatDMS = '';
    destLonDMS = '';
    destElevation = '';
    hasDestination = false;
    notifyListeners();
  }
}
