

import 'package:geocoding/geocoding.dart';

Future<Location?> getLatLangFromAddress(String? consigneeAddress) async {
 try {
   List<Location> deliveryLatLang = await locationFromAddress(
       consigneeAddress ?? "Sharq Plaza, D Ring Rd, Doha, Qatar");
   return deliveryLatLang.first;
 }catch(e){
   return null ;
 }
}