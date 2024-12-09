import 'dart:async';

import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/pages/orders/orders_model.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:carson_zyppy/global/consts.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  final CargoOrderDataModel orderDetails;

  MapPage({required this.orderDetails});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = new Location();
  BitmapDescriptor riderIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor icPickLocation = BitmapDescriptor.defaultMarker;
  BitmapDescriptor icDropLocation = BitmapDescriptor.defaultMarker;

  /// Load custom icons
  void loadCustomIcons() async {
    final riderIconFuture = BitmapDescriptor.fromAssetImage(
       ImageConfiguration(size: Size(48, 48)),
      "assets/icons/ic_you.jpg",
    );

    final sourceIconFuture = BitmapDescriptor.fromAssetImage(
       ImageConfiguration(size: Size(48, 48)),
      "assets/icons/ic_pick_point.jpg",
    );

    final destinationIconFuture = BitmapDescriptor.fromAssetImage(
       ImageConfiguration(size: Size(48, 48)),
      "assets/icons/ic_drop_point.jpg",
    );

    // Wait for all icons to load
    final icons = await Future.wait(
        [riderIconFuture, sourceIconFuture, destinationIconFuture]);

    setState(() {
      riderIcon = icons[0];
      icPickLocation =  icons[1];
      icDropLocation = icons[2];
    });
  }

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  static  LatLng locationOne = LatLng(31.104799864999666, 77.17530880414573);
  static  LatLng locationTwo = LatLng(31.10377073511391, 77.19289128579997);
  LatLng? curentLocation = null;

  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    loadCustomIcons();
    super.initState();
    getLocationUpdates().then(
      (_) => {
        getPolylinePoints().then((coordinates) => {
              generatePolyLineFromPoints(coordinates),
            }),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: curentLocation == null
          ?  Center(
              child: utils.iosProgressIndicator(AppColors.primaryThemeColor),
            )
          : GoogleMap(
        gestureRecognizers: Set()
          ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
          ..add(Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer())),
              mapType: MapType.hybrid,
              myLocationEnabled : true,
              onMapCreated: ((GoogleMapController controller) =>
                  _mapController.complete(controller)),
              initialCameraPosition:  CameraPosition(
                target: locationOne,
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId:  MarkerId("_currentLocation"),
                  icon: BitmapDescriptor.defaultMarkerWithHue(0.5),
                  position: curentLocation!,
                ),
                Marker(
                  markerId:  MarkerId("_sourceLocation"),
                  //icon: icPickLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(220.5),
                  position: locationOne,
                  infoWindow:  InfoWindow(
                    title: "Pick-Up Address",
                    snippet: widget.orderDetails.shipperAddress,
                  ),
                ),
                Marker(
                    markerId:  MarkerId("_destionationLocation"),
                   // icon: icDropLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(120.5),
                    position: locationTwo,
                  infoWindow:  InfoWindow(
                    title: "Delivery Address",
                    snippet: widget.orderDetails.destination,
                  ),)
              },
              polylines: Set<Polyline>.of(polylines.values),

            ),
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    var zoomLevel = await controller.getZoomLevel();
    CameraPosition _newCameraPosition = CameraPosition(
     target: pos,
      zoom: zoomLevel,
    );

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPosition),
    );
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          curentLocation =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
         // _cameraToPosition(curentLocation!);
        });
      }
    });
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      GOOGLE_MAPS_API_KEY,
      PointLatLng(locationOne.latitude, locationOne.longitude),
      PointLatLng(locationTwo.latitude, locationTwo.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    return polylineCoordinates;
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id =  PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: AppColors.primaryThemeColor,
        points: polylineCoordinates,
        width: 8);
    setState(() {
      polylines[id] = polyline;
    });
  }
}
