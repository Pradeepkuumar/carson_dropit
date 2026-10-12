import 'dart:async';

import 'package:location/location.dart';

class LocationUtils {
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  Future<LocationData?> getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    try {
      return await _location.getLocation().timeout(
        const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
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

