import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

class LocationUtils {
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  void _log(String source, String message) {
    if (kDebugMode) {
      final tag = source == 'auto' ? 'AUTO_LOCATION' : 'MANUAL_LOCATION';
      debugPrint('[$tag] $message');
    }
  }

  Future<LocationData?> getCurrentLocation({
    String source = 'manual',
  }) async {
    _log(source, 'Location service request started; instance=${identityHashCode(this)}');
    try {
      final location = await _getCurrentLocation(source).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log(source, 'Location service request timed out after 30 seconds');
          return null;
        },
      );
      _log(source, 'Location service request completed: available=${location != null}');
      return location;
    } catch (e, stackTrace) {
      _log(source, 'Location service request error: $e\n$stackTrace');
      return null;
    }
  }

  Future<LocationData?> _getCurrentLocation(String source) async {
    _log(source, 'Checking GPS/service availability');
    final serviceEnabled = await _location.serviceEnabled();
    _log(source, 'GPS/service enabled=$serviceEnabled');
    if (!serviceEnabled) {
      _log(source, 'Requesting GPS/service enablement');
      final enabled = await _location.requestService();
      _log(source, 'GPS/service enable result=$enabled');
      if (!enabled) return null;
    }

    var permissionGranted = await _location.hasPermission();
    _log(source, 'Location permission status=$permissionGranted');
    if (permissionGranted != PermissionStatus.granted) {
      _log(source, 'Requesting foreground location permission');
      permissionGranted = await _location.requestPermission();
      _log(source, 'Location permission result=$permissionGranted');
      if (permissionGranted != PermissionStatus.granted) return null;
    }

    _log(source, 'Platform current position request started');
    final location = await _location
        .getLocation()
        .timeout(const Duration(seconds: 10));
    _log(
      source,
      'Platform current position completed: lat=${location.latitude}; lng=${location.longitude}',
    );
    return location;
  }


  Future<void> startListeningToLocationUpdates({
    required Function(LocationData) onLocationChanged,
  }) async {
    // Drop any previous listener so repeated starts don't stack up streams.
    await _locationSubscription?.cancel();
    try {
      await _location.enableBackgroundMode(enable: true);
    } catch (_) {
      // Background permission denied - keep foreground updates going.
    }
    await _location.changeSettings(interval: 10000, distanceFilter: 0);
    _locationSubscription = _location.onLocationChanged.listen(onLocationChanged);
  }

  Future<void> stopListeningToLocationUpdates() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    try {
      await _location.enableBackgroundMode(enable: false);
    } catch (_) {}
  }
}

