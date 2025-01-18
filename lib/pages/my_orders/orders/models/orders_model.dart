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

  OrdersData(
      {this.id,
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
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['merchant_id'] = this.merchantId;
    data['location_id'] = this.locationId;
    data['order_ref_number'] = this.orderRefNumber;
    data['job_type'] = this.jobType;
    data['awb_no'] = this.awbNo;
    data['fe_code'] = this.feCode;
    data['status'] = this.status;
    data['run_sheet_no'] = this.runSheetNo;
    data['item_amount'] = this.orderAmount;
    data['payment_type'] = this.paymentType;
    data['quantity'] = this.quantity;
    data['item_name'] = this.itemName;
    data['item_description'] = this.itemDescription;
    data['weight'] = this.weight;
    data['consignee_name'] = this.consigneeName;
    data['consignee_mobile_no'] = this.consigneeMobileNo;
    data['consignee_address'] = this.consigneeAddress;
    data['consignee_city'] = this.consigneeStreetNumber;
    data['consignee_zone'] = this.consigneeZone;
    data['consignee_state'] = this.consigneeBuildingNo;
    data['dropoff_latitude'] = this.dropoffLatitude;
    data['dropoff_longitude'] = this.dropoffLongitude;
    data['remarks'] = this.remarks;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['pickup_location_name'] = this.pickupLocationName;
    data['pickup_address'] = this.pickupAddress;
    data['pickup_phone_no'] = this.pickupPhoneNo;
    data['pickup_zone_no'] = this.pickupZoneNo;
    data['pickup_latitude'] = this.pickupLatitude;
    data['pickup_longitude'] = this.pickupLongitude;
    data['merchant_name'] = this.merchantName;
    data['merchant_code'] = this.merchantCode;
    data['contact_person_name'] = this.contact_person_name;
    data['contact_person_phoneno'] = this.contact_person_phoneno;
    data['sla_in_hours'] = this.sla_in_hours;
    data['reason'] = this.reason;
    data['failed_delivery_proof'] = this.failed_delivery_proof;
    return data;
  }
}
