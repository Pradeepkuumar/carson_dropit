import 'package:location/location.dart';

class LocationUtils {
  final Location _location = Location();

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


  void startListeningToLocationUpdates({
    required Function(LocationData) onLocationChanged,
  }) {
    _location.enableBackgroundMode(enable: true);
    _location.changeSettings(interval: 10000, distanceFilter: 0);
    _location.onLocationChanged.listen(onLocationChanged);
  }
}

