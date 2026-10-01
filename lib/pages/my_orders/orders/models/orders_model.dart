class OrdersData {
  int? id;
  int? merchantId;
  int? locationId;
  String? orderRefNumber;
  String? jobType;
  String? awbNo;
  String? feCode;
  String? status;
  String? runSheetNo;
  String? orderAmount;
  String? paymentType;
  int? quantity;
  String? itemName;
  String? itemDescription;
  String? weight;
  String? consigneeName;
  String? consigneeMobileNo;
  String? consigneeAddress;
  String? consigneeStreetNumber;
  String? consigneeZone;
  String? consigneeBuildingNo;
  String? consigneeUnitNo;
  String? dropoffLatitude;
  String? dropoffLongitude;
  String? remarks;
  String? createdAt;
  String? updatedAt;
  String? pickupLocationName;
  String? pickupAddress;
  String? pickupPhoneNo;
  String? pickupZoneNo;
  String? pickupLatitude;
  String? pickupLongitude;
  String? merchantName;
  String? merchantCode;
  String? contact_person_name;
  String? contact_person_phoneno;
  String? sla_in_hours;
  String? reason;
  String? failed_delivery_proof;
  String? distance;
  String? duration;
  String? distanceInKms;
  String? remainingTime;
  String? current_pickup_distance;
  String? current_pickup_duration;
  double? current_pickup_distance_value;
  String? current_dropoff_distance;
  String? current_dropoff_duration;
  double? current_dropoff_distance_value;
  String? pickup_buffer_time_in_minutes;
  String? dropoff_buffer_time_in_minutes;
  String? serviceType;
  bool? isActivePriority;
  String? deliveryType;

  // The API actually flags a priority order via delivery_type == "PRIORITY",
  // not is_active_priority (kept above as its own field/key regardless).
  static const String _priorityDeliveryType = "PRIORITY";
  bool get isPriorityOrder =>
      isActivePriority == true || deliveryType == _priorityDeliveryType;

  OrdersData({
    this.id,
    this.merchantId,
    this.locationId,
    this.orderRefNumber,
    this.jobType,
    this.awbNo,
    this.feCode,
    this.status,
    this.runSheetNo,
    this.orderAmount,
    this.paymentType,
    this.quantity,
    this.itemName,
    this.itemDescription,
    this.weight,
    this.consigneeName,
    this.consigneeMobileNo,
    this.consigneeAddress,
    this.consigneeStreetNumber,
    this.consigneeZone,
    this.consigneeBuildingNo,
    this.consigneeUnitNo,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.remarks,
    this.createdAt,
    this.updatedAt,
    this.pickupLocationName,
    this.pickupAddress,
    this.pickupPhoneNo,
    this.pickupZoneNo,
    this.pickupLatitude,
    this.pickupLongitude,
    this.merchantName,
    this.merchantCode,
    this.contact_person_name,
    this.contact_person_phoneno,
    this.sla_in_hours,
    this.reason,
    this.failed_delivery_proof,
    this.distance,
    this.duration,
    this.distanceInKms,
    this.remainingTime,
    this.current_pickup_distance,
    this.current_pickup_duration,
    this.current_pickup_distance_value,
    this.current_dropoff_distance,
    this.current_dropoff_duration,
    this.current_dropoff_distance_value,
    this.pickup_buffer_time_in_minutes,
    this.dropoff_buffer_time_in_minutes,
    this.serviceType,
    this.isActivePriority,
    this.deliveryType,
  });

  OrdersData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    merchantId = json['merchant_id'];
    locationId = json['location_id'];
    orderRefNumber = json['order_ref_number'];
    jobType = json['job_type'];
    awbNo = json['awb_no'];
    feCode = json['fe_code'];
    status = json['status'];
    runSheetNo = json['run_sheet_no'];
    orderAmount = json['order_amount'];
    paymentType = json['payment_type'];
    quantity = json['quantity'];
    itemName = json['item_name'];
    itemDescription = json['item_description'];
    weight = json['weight'];
    consigneeName = json['consignee_name'];
    consigneeMobileNo = json['consignee_mobile_no'];
    consigneeAddress = json['consignee_address'];
    consigneeStreetNumber = json['consignee_street_no'];
    consigneeZone = json['consignee_zone_no'];
    consigneeBuildingNo = json['consignee_building_no'];
    consigneeUnitNo = json['consignee_unit_no'];
    dropoffLatitude = json['dropoff_latitude'];
    dropoffLongitude = json['dropoff_longitude'];
    remarks = json['remarks'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    pickupLocationName = json['pickup_location_name'];
    pickupAddress = json['pickup_address'];
    pickupPhoneNo = json['pickup_phone_no'];
    pickupZoneNo = json['pickup_zone_no'];
    pickupLatitude = json['pickup_latitude'];
    pickupLongitude = json['pickup_longitude'];
    merchantName = json['merchant_name'];
    merchantCode = json['merchant_code'];
    contact_person_name = json['contact_person_name'];
    contact_person_phoneno = json['contact_person_phoneno'];
    sla_in_hours = json['sla_in_hours'];
    reason = json['reason'];
    failed_delivery_proof = json['failed_delivery_proof'];
    distance = json['distance'];
    duration = json['duration'];
    distanceInKms = json['distance_in_kms'];
    remainingTime = json['remainingTimeFormatted'];
    pickup_buffer_time_in_minutes = json['pickup_buffer_time_in_minutes'];
    dropoff_buffer_time_in_minutes = json['dropoff_buffer_time_in_minutes'];
    current_dropoff_duration = json['current_dropoff_duration'];
    current_dropoff_distance = json['current_dropoff_distance'];
    current_pickup_duration = json['current_pickup_duration'];
    current_pickup_distance = json['current_pickup_distance'];
    current_pickup_distance_value =
        json['current_pickup_distance_value'] != null
        ? double.tryParse(json['current_pickup_distance_value'].toString())
        : null;
    current_dropoff_distance_value =
        json['current_dropoff_distance_value'] != null
        ? double.tryParse(json['current_dropoff_distance_value'].toString())
        : null;
    serviceType = json['service_type'];
    isActivePriority = json['is_active_priority'];
    deliveryType = json['delivery_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['merchant_id'] = merchantId;
    data['location_id'] = locationId;
    data['order_ref_number'] = orderRefNumber;
    data['job_type'] = jobType;
    data['awb_no'] = awbNo;
    data['fe_code'] = feCode;
    data['status'] = status;
    data['run_sheet_no'] = runSheetNo;
    data['item_amount'] = orderAmount;
    data['payment_type'] = paymentType;
    data['quantity'] = quantity;
    data['item_name'] = itemName;
    data['item_description'] = itemDescription;
    data['weight'] = weight;
    data['consignee_name'] = consigneeName;
    data['consignee_mobile_no'] = consigneeMobileNo;
    data['consignee_address'] = consigneeAddress;
    data['consignee_city'] = consigneeStreetNumber;
    data['consignee_zone'] = consigneeZone;
    data['consignee_state'] = consigneeBuildingNo;
    data['dropoff_latitude'] = dropoffLatitude;
    data['dropoff_longitude'] = dropoffLongitude;
    data['remarks'] = remarks;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['pickup_location_name'] = pickupLocationName;
    data['pickup_address'] = pickupAddress;
    data['pickup_phone_no'] = pickupPhoneNo;
    data['pickup_zone_no'] = pickupZoneNo;
    data['pickup_latitude'] = pickupLatitude;
    data['pickup_longitude'] = pickupLongitude;
    data['merchant_name'] = merchantName;
    data['merchant_code'] = merchantCode;
    data['contact_person_name'] = contact_person_name;
    data['contact_person_phoneno'] = contact_person_phoneno;
    data['sla_in_hours'] = sla_in_hours;
    data['reason'] = reason;
    data['failed_delivery_proof'] = failed_delivery_proof;
    data['distance'] = distance;
    data['duration'] = duration;
    data['distance_in_kms'] = distanceInKms;
    data['remainingTimeFormatted'] = remainingTime;
    data['current_dropoff_duration'] = current_dropoff_duration;
    data['current_dropoff_distance'] = current_dropoff_distance;
    data['current_pickup_duration'] = current_pickup_duration;
    data['current_pickup_distance'] = current_pickup_distance;
    data['pickup_buffer_time_in_minutes'] = pickup_buffer_time_in_minutes;
    data['dropoff_buffer_time_in_minutes'] = dropoff_buffer_time_in_minutes;
    data['current_pickup_distance_value'] = current_pickup_distance_value;
    data['current_dropoff_distance_value'] = current_dropoff_distance_value;
    data['service_type'] = serviceType;
    data['is_active_priority'] = isActivePriority;
    data['delivery_type'] = deliveryType;
    return data;
  }
}
