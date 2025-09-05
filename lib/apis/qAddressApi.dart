import 'dart:convert';

import 'package:carson_zyppy/pages/map/qAddressModel/QDeliveryAddress.dart';
import 'package:get/get.dart';

class Qaddressapi extends GetConnect {
  var locations = <QdeliveryAddress>[].obs;

  Future<QdeliveryAddress?> fetchDeliveryLocation(String zone, String street, String building) async {
    final fullUrl = 'https://qnas.qa/get_location/$zone/$street/$building';
    try {
      final response = await get(fullUrl);
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.bodyString!);
        locations.value = jsonResponse.map((item) => QdeliveryAddress.fromJson(item)).toList();
      return locations.first;
      } else {
        print(response.statusText);
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }
}