import 'dart:async';

import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart'
    hide Marker;

// Opened with Get.arguments = {"title": String, "destination": LatLng}.
// Runs a full in-app turn-by-turn guidance session end to end: one-time
// terms dialog, session init, route calculation, guidance - then pops back
// with `true` once GoogleMapsNavigator's own arrival event fires (or `false`
// if the rider exits manually), so ActiveDeliveryScreen can nudge them
// toward the right "Confirm ..." step without us auto-changing order status.
class TurnByTurnNavigationController extends GetxController {
  late final String destinationTitle;
  late final LatLng destination;

  GoogleNavigationViewController? navViewController;
  StreamSubscription<OnArrivalEvent>? _arrivalSubscription;

  var isInitializing = true.obs;
  var errorMessage = Rxn<String>();
  bool _arrived = false;
  bool _cleanedUp = false;

  @override
  void onInit() {
    final args = Get.arguments;
    destinationTitle =
        (args is Map ? args['title'] as String? : null) ?? "Destination";
    destination =
        (args is Map ? args['destination'] as LatLng? : null) ??
        const LatLng(latitude: 0, longitude: 0);
    _setup();
    super.onInit();
  }

  Future<void> _setup() async {
    try {
      final termsAccepted = await GoogleMapsNavigator.areTermsAccepted();
      if (!termsAccepted) {
        final accepted = await GoogleMapsNavigator.showTermsAndConditionsDialog(
          "Navigation Terms of Service",
          "Drop-it",
        );
        if (!accepted) {
          errorMessage.value =
              "Navigation requires accepting Google's terms of service.";
          isInitializing.value = false;
          return;
        }
      }

      await GoogleMapsNavigator.initializeNavigationSession();

      final status = await GoogleMapsNavigator.setDestinations(
        Destinations(
          waypoints: [
            NavigationWaypoint.withLatLngTarget(
              title: destinationTitle,
              target: destination,
            ),
          ],
          displayOptions: NavigationDisplayOptions(
            showDestinationMarkers: true,
          ),
        ),
      );
      if (status != NavigationRouteStatus.statusOk) {
        errorMessage.value = _routeStatusMessage(status);
        isInitializing.value = false;
        return;
      }

      await GoogleMapsNavigator.startGuidance();
      _arrivalSubscription = GoogleMapsNavigator.setOnArrivalListener((_) {
        _arrived = true;
        Get.back(result: true);
      });
      isInitializing.value = false;
    } on SessionInitializationException catch (e) {
      errorMessage.value = _sessionErrorMessage(e.code);
      isInitializing.value = false;
    } catch (e) {
      errorMessage.value = "Couldn't start navigation: $e";
      isInitializing.value = false;
    }
  }

  String _routeStatusMessage(NavigationRouteStatus status) {
    switch (status) {
      case NavigationRouteStatus.locationUnavailable:
        return "Waiting for a GPS fix - move to an open area and try again.";
      case NavigationRouteStatus.networkError:
        return "No network connection. Check your connection and try again.";
      case NavigationRouteStatus.routeNotFound:
        return "Couldn't find a route to this stop.";
      case NavigationRouteStatus.quotaExceeded:
        return "Navigation is temporarily unavailable. Try again shortly.";
      default:
        return "Couldn't calculate a route to this stop.";
    }
  }

  String _sessionErrorMessage(SessionInitializationError code) {
    switch (code) {
      case SessionInitializationError.notAuthorized:
        return "Navigation isn't enabled for this app yet.";
      case SessionInitializationError.locationPermissionMissing:
        return "Location permission is required for navigation.";
      case SessionInitializationError.termsNotAccepted:
        return "Navigation requires accepting Google's terms of service.";
    }
  }

  void onViewCreated(GoogleNavigationViewController controller) {
    navViewController = controller;
    controller.setNavigationHeaderEnabled(true);
    controller.setNavigationFooterEnabled(true);
    controller.setMyLocationEnabled(true);
    controller.followMyLocation(CameraPerspective.tilted);
  }

  void exitNavigation() {
    Get.back(result: _arrived);
  }

  @override
  void onClose() {
    _arrivalSubscription?.cancel();
    if (!_cleanedUp) {
      _cleanedUp = true;
      GoogleMapsNavigator.cleanup();
    }
    super.onClose();
  }
}
