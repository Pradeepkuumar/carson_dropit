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

    return await _location.getLocation();
  }


  void startListeningToLocationUpdates({
    required Function(LocationData) onLocationChanged,
  }) {
    _location.enableBackgroundMode(enable: true);
    _location.onLocationChanged.listen(onLocationChanged);
  }
}

