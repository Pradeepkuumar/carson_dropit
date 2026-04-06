// lib/services/osm_navigation_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:http/http.dart' as http;



class OSMNavigationService {
  static const String OSRM_BASE_URL = 'https://router.project-osrm.org/route/v1/driving/';
  
  // For self-hosted OSRM server (optional, better for production)
  // static const String OSRM_BASE_URL = 'http://your-server:5000/route/v1/driving/';
  
  // Cache for route data
  final Map<String, RouteData> _routeCache = {};
  
  Future<RouteData?> getRoute(LatLng start, LatLng end) async {
    String cacheKey = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
    
    if (_routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey];
    }
    
    try {
      final url = '${OSRM_BASE_URL}${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline&steps=true';
      
      if (kDebugMode) {
        print('OSRM Request: $url');
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok') {
          final route = data['routes'][0];
          final routeData = RouteData(
            distance: route['distance'],
            duration: route['duration'],
            geometry: route['geometry'],
            legs: route['legs'],
          );
          
          _routeCache[cacheKey] = routeData;
          return routeData;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting route from OSRM: $e');
      }
    }
    return null;
  }
  
  Future<List<LatLng>> decodePolyline(String encodedPolyline) {
    return compute(_decodePolylineIsolate, encodedPolyline);
  }
  
  static List<LatLng> _decodePolylineIsolate(String encodedPolyline) {
    List<LatLng> points = [];
    int index = 0;
    int len = encodedPolyline.length;
    int lat = 0;
    int lng = 0;
    
    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encodedPolyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      
      shift = 0;
      result = 0;
      do {
        b = encodedPolyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      
      points.add(LatLng(latitude:  lat / 1e5, longitude:  lng / 1e5));
    }
    
    return points;
  }
  
  // Calculate distance between two points (Haversine formula)
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // in meters
    
    double lat1 = point1.latitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    double deltaLon = (point2.longitude - point1.longitude) * pi / 180;
    
    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  // Estimate time based on distance (assuming average speed of 30 km/h in city)
  Duration estimateTime(double distanceInMeters) {
    double speedInMps = 8.33; // 30 km/h in m/s
    int seconds = (distanceInMeters / speedInMps).round();
    return Duration(seconds: seconds);
  }
}

class RouteData {
  final double distance; // in meters
  final double duration; // in seconds
  final String geometry; // encoded polyline
  final List<dynamic> legs;
  
  RouteData({
    required this.distance,
    required this.duration,
    required this.geometry,
    required this.legs,
  });
}