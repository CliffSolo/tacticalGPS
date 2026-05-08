import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:mgrs_dart/mgrs_dart.dart';

class LocationUtils {
  static String decimalToDMS(double decimal, bool isLatitude) {
    final String direction;
    if (isLatitude) {
      direction = decimal >= 0 ? 'N' : 'S';
    } else {
      direction = decimal >= 0 ? 'E' : 'W';
    }
    decimal = decimal.abs();
    final int degrees = decimal.floor();
    final double minutesDecimal = (decimal - degrees) * 60;
    final int minutes = minutesDecimal.floor();
    final double seconds = (minutesDecimal - minutes) * 60;
    return '$degrees° $minutes\' ${seconds.toStringAsFixed(2)}" $direction';
  }

  static String latLonToMGRS(double latitude, double longitude) {
    try {
      final String raw = Mgrs.forward([longitude, latitude], 4);
      return formatMGRS(raw);
    } catch (e) {
      return 'MGRS N/A';
    }
  }

  static String formatMGRS(String raw) {
    try {
      int splitIndex = 0;
      for (int i = 0; i < raw.length; i++) {
        if (int.tryParse(raw[i]) != null) {
          splitIndex = i;
          break;
        }
      }
      final String gzdAndLetters = raw.substring(0, splitIndex);
      final String numbers = raw.substring(splitIndex);
      final String gzd = gzdAndLetters.substring(0, 3);
      final String letters = gzdAndLetters.substring(3);
      final int half = numbers.length ~/ 2;
      final String easting = numbers.substring(0, half);
      final String northing = numbers.substring(half);
      return '$gzd $letters $easting $northing';
    } catch (e) {
      return raw;
    }
  }

  static double metersToFeet(double meters) => meters * 3.28084;

  static String formatElevation(double meters) {
    final double feet = metersToFeet(meters);
    return '${feet.toStringAsFixed(1)} ft  /  ${meters.toStringAsFixed(1)} m';
  }

  static String formatDistance(double meters) {
    final double feet = metersToFeet(meters);
    if (meters < 300) {
      return '${feet.toStringAsFixed(0)} ft  /  ${meters.toStringAsFixed(0)} m';
    } else {
      final double miles = meters / 1609.344;
      final double km = meters / 1000;
      return '${miles.toStringAsFixed(2)} mi  /  ${km.toStringAsFixed(2)} km';
    }
  }

  static String formatSpeed(double metersPerSecond) {
    final double mph = metersPerSecond * 2.23694;
    final double kmh = metersPerSecond * 3.6;
    return '${mph.toStringAsFixed(1)} mph  /  ${kmh.toStringAsFixed(1)} km/h';
  }

  static double calculateBearing(double startLat, double startLon, double endLat, double endLon) {
    final double lat1 = startLat * math.pi / 180;
    final double lat2 = endLat * math.pi / 180;
    final double dLon = (endLon - startLon) * math.pi / 180;
    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000;
    final double dLat = (lat2 - lat1) * math.pi / 180;
    final double dLon = (lon2 - lon1) * math.pi / 180;
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static Future<double?> getRoadDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '\$lon1,\$lat1;\$lon2,\$lat2?overview=false';
      final uri = Uri.parse(url);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['code'] == 'Ok') {
        final routes = json['routes'] as List;
        if (routes.isNotEmpty) {
          return (routes[0]['distance'] as num).toDouble();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

}
