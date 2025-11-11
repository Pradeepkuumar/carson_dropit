// class QdeliveryAddress {
//   String? coordX;
//   String? coordY;

//   QdeliveryAddress({
//     required this.coordX,
//     required this.coordY,
//   });


//   factory QdeliveryAddress.fromJson(Map<String, dynamic> json) {
//     return QdeliveryAddress(
//       coordX: json['coord_x'],
//       coordY: json['coord_y'],
//     );
//   }
// }


class QdeliveryAddress {
  final String? mapUrl;
  final String? address;
  final double? latitude;
  final double? longitude;

  QdeliveryAddress({
    this.mapUrl,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory QdeliveryAddress.fromJson(Map<String, dynamic> json) {
    return QdeliveryAddress(
      mapUrl: json['map_url'],
      address: json['address'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }
}
