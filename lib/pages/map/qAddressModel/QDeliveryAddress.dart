class QdeliveryAddress {
  String? coordX;
  String? coordY;

  QdeliveryAddress({
    required this.coordX,
    required this.coordY,
  });


  factory QdeliveryAddress.fromJson(Map<String, dynamic> json) {
    return QdeliveryAddress(
      coordX: json['coord_x'],
      coordY: json['coord_y'],
    );
  }
}
