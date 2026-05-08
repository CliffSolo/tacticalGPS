import 'package:flutter/material.dart';

class Waypoint {
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

  final double? roadDistance;

  Waypoint({
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
    this.roadDistance,
  });
}
