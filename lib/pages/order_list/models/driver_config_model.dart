class DriverConfigData {
  int? driverId;
  String? driverCode;
  String? driverName;
  String? driverPhone;
 // String? driverType;
  List<String>? allowedChannels;
  bool? canHandleB2c;
  bool? canHandleC2c;
  bool? canHandleWa;
  List<String>? allowedStatuses;

  DriverConfigData({
    this.driverId,
    this.driverCode,
    this.driverName,
    this.driverPhone,
    //this.driverType,
    this.allowedChannels,
    this.canHandleB2c,
    this.canHandleC2c,
    this.canHandleWa,
    this.allowedStatuses,
  });

  DriverConfigData.fromJson(Map<String, dynamic> json) {
    driverId = json['driver_id'];
    driverCode = json['driver_code'];
    driverName = json['driver_name'];
    driverPhone = json['driver_phone'];
   // driverType = json['driver_type'];
    allowedChannels = (json['allowed_channels'] as List?)
        ?.map((e) => e.toString())
        .toList();
    canHandleB2c = json['can_handle_b2c'];
    canHandleC2c = json['can_handle_c2c'];
    canHandleWa = json['can_handle_wa'];
    allowedStatuses = (json['allowed_statuses'] as List?)
        ?.map((e) => e.toString())
        .toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['driver_id'] = driverId;
    data['driver_code'] = driverCode;
    data['driver_name'] = driverName;
    data['driver_phone'] = driverPhone;
  //  data['driver_type'] = driverType;
    data['allowed_channels'] = allowedChannels;
    data['can_handle_b2c'] = canHandleB2c;
    data['can_handle_c2c'] = canHandleC2c;
    data['can_handle_wa'] = canHandleWa;
    data['allowed_statuses'] = allowedStatuses;
    return data;
  }
}