import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:latlong2/latlong.dart' as osm;

extension GoogleToOSM on LatLng {
  osm.LatLng toOSM() => osm.LatLng(latitude, longitude);
}

extension OSMToGoogle on osm.LatLng {
  LatLng toGoogle() =>
      LatLng(latitude: latitude, longitude: longitude);
}
