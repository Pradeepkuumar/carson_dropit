// lib/pages/map/controller/osm_map_controller.dart
import 'dart:async';
import 'package:carson_zyppy/pages/map/controller/all_orders_map_controller.dart' as base;
import 'package:carson_zyppy/pages/osrm/OsmNavigationSercice.dart';
import 'package:carson_zyppy/pages/osrm/latlng_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_navigation_flutter/src/types/lat_lng.dart';
import 'package:google_navigation_flutter/src/types/navigation_destinations.dart' as prefix0;
import 'package:get/get.dart';



class OSMMapController extends base.AllOrdersMapController {
  final OSMNavigationService osmService = OSMNavigationService();
  
  // Map controllers
  late MapController mapController;
  final List<Polyline> polylines = [];
  final List<Marker> osmMarkers = [];
  
  // Navigation state
  var currentRoute = Rx<RouteData?>(null);
  var navigationSteps = <NavigationStep>[].obs;
  var currentStepIndex = 0.obs;
  
  // Live tracking
  Timer? _navigationTimer;
  LatLng? _nextPoint;
  int _currentPointIndex = 0;
  List<LatLng> _currentPolylinePoints = [];
  
  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
  }
  
  @override
  Future<bool> setMarkers() async {
    osmMarkers.clear();
    
    var currentOrdersList = currentLocationOrders.isNotEmpty
        ? currentLocationOrders
        : ordersList;
    
    for (var order in currentOrdersList) {
      final double latitude = (order.status == "PICKED" || order.status == "OFD")
          ? double.tryParse(order.dropoffLatitude ?? "0.0") ?? 0.0
          : double.tryParse(order.pickupLatitude ?? "0.0") ?? 0.0;
          
      final double longitude = (order.status == "PICKED" || order.status == "OFD")
          ? double.tryParse(order.dropoffLongitude ?? "0.0") ?? 0.0
          : double.tryParse(order.pickupLongitude ?? "0.0") ?? 0.0;
      
      final position = LatLng( latitude: latitude, longitude:  longitude);
      
      // Create custom marker widget
      osmMarkers.add(
        Marker(
          point: position.toOSM(),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              selectedOrderAwbId.value = order.awbNo!;
              selectedLocationOrders();
            },
            child: Container(
              decoration: BoxDecoration(
                color: (order.status == "PICKED" || order.status == "OFD") 
                    ? Colors.green 
                    : Colors.blue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    order.awbNo!.substring(order.awbNo!.length - 4),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Icon(
                    (order.status == "PICKED" || order.status == "OFD") 
                        ? Icons.location_on 
                        : Icons.store,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      // markerLatLangList.add(position);
      waypoints.add(NavigationWaypoint(
        title: order.consigneeAddress?.toString() ?? "Destination",
        target: position,
      ) as prefix0.NavigationWaypoint);
    }
    
    update();
    return true;
  }
  
  Future<void> drawRoute(LatLng start, LatLng end) async {
    final routeData = await osmService.getRoute(start, end);
    
    if (routeData != null) {
      currentRoute.value = routeData;
      _currentPolylinePoints = (await osmService.decodePolyline(routeData.geometry)).cast<LatLng>();
      
      // Create polyline
      polylines.clear();
      polylines.add(
        Polyline(
          points:  _currentPolylinePoints.map((e) => e.toOSM()).toList(),
          color: Colors.blue,
          strokeWidth: 4.0,
        ),
      );
      
      // Extract navigation steps
      navigationSteps.clear();
      if (routeData.legs.isNotEmpty) {
        final leg = routeData.legs[0];
        if (leg['steps'] != null) {
          for (var step in leg['steps']) {
            navigationSteps.add(NavigationStep(
              instruction: step['maneuver']?['instruction'] ?? 'Continue',
              distance: step['distance'] ?? 0,
              duration: step['duration'] ?? 0,
              location: LatLng( latitude: 
                step['maneuver']?['location']?[1] ?? 0.0, longitude: 
                step['maneuver']?['location']?[0] ?? 0.0,
              ),
            ));
          }
        }
      }
      
      update();
    }
  }
  
  // @override
  // Future<void> startGuidedNavigation() async {
  //   if (!isNavigationRunning.value && currentLocation != null && markerLatLangList.isNotEmpty) {
  //     final nearestDestination = findNearestDestination(currentLocation!, markerLatLangList);
      
  //     if (nearestDestination != null) {
  //       await drawRoute(currentLocation! as LatLng, nearestDestination as LatLng);
  //       startNavigationSimulation();
  //       isNavigationRunning.value = true;
  //     }
  //   }
  // }
  
  void startNavigationSimulation() {
    _navigationTimer?.cancel();
    _currentPointIndex = 0;
    
    if (_currentPolylinePoints.isEmpty) return;
    
    _navigationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentPointIndex < _currentPolylinePoints.length - 1) {
        _currentPointIndex++;
        _nextPoint = _currentPolylinePoints[_currentPointIndex];
        
        // Update current location to simulate movement
        currentLocation = _nextPoint;
        
        // Update remaining distance
        if (_currentPointIndex < _currentPolylinePoints.length - 1) {
          final remainingPoints = _currentPolylinePoints.sublist(_currentPointIndex);
          remainingDistance.value = remainingPoints.fold(0.0, (sum, point) {
            if (_nextPoint != null) {
              return sum + osmService.calculateDistance(_nextPoint!, point);
            }
            return sum;
          });
        }
        
        // Check if near destination
        if (remainingDistance.value <= 500) {
          filterCurrentLocationOrders(500);
        }
        
        // Update driver location
        DateTime now = DateTime.now();
        if (updateDriverLocationInterval == null || 
            now.difference(updateDriverLocationInterval!).inMinutes >= 1) {
          updateDriverLocationInterval = now;
          sendDriverLocation(currentLocation!);
        }
        
        // Animate camera to follow
        mapController.move( _nextPoint!.toOSM(), mapController.camera.zoom);
        
        update();
      } else {
        // Reached destination
        timer.cancel();
        isNavigationRunning.value = false;
      }
    });
  }
  

  @override
  Future<void> stopGuidedNavigation()  async {
    _navigationTimer?.cancel();
    isNavigationRunning.value = false;
    polylines.clear();
    update();
  }
  
  @override
  void onClose() {
    _navigationTimer?.cancel();
    mapController.dispose();
    super.onClose();
  }
}

class NavigationWaypoint {
  final String title;
  final LatLng target;
  
  NavigationWaypoint({required this.title, required this.target});
}

class NavigationStep {
  final String instruction;
  final double distance;
  final double duration;
  final LatLng location;
  
  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.location,
  });
}