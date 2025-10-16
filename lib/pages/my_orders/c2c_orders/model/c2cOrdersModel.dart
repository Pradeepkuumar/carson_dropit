
// class C2COrdersData {
//   int? id;
//   int? merchantId;
//   String? awbNo;
//   String? orderRefNumber;
//   String? shipperName;
//   String? shipperMobileNo;
//   String? shipperEmail;
//   String? shipperZoneNo;
//   String? shipperStreetNo;
//   String? shipperBuildingNo;
//   String? shipperAddress;
//   String? shipperLatitude;
//   String? shipperLongitude;
//   String? consigneeName;
//   String? consigneeMobileNo;
//   String? consigneeEmail;
//   String? consigneeZoneNo;
//   String? consigneeStreetNo;
//   String? consigneeBuildingNo;
//   String? consigneeAddress;
//   String? consigneeLatitude;
//   String? consigneeLongitude;
//   String? itemName;
//   String? itemDescription;
//   int? quantity;
//   String? weight;
//   String? orderAmount;
//   String? paymentType;
//   String? feCode;
//   String? status;
//   String? pickedAt;
//   String? deliveredAt;
//   String? failedAt;
//   String? deliveryProof;
//   String? failedDeliveryProof;
//   String? signature;
//   String? collectedAmount;
//   int? reconciled;
//   String? reconciledAt;
//   String? cancelReason;
//   String? remarks;
//   String? createdAt;
//   String? updatedAt;

//   C2COrdersData(
//       {this.id,
//       this.merchantId,
//       this.awbNo,
//       this.orderRefNumber,
//       this.shipperName,
//       this.shipperMobileNo,
//       this.shipperEmail,
//       this.shipperZoneNo,
//       this.shipperStreetNo,
//       this.shipperBuildingNo,
//       this.shipperAddress,
//       this.shipperLatitude,
//       this.shipperLongitude,
//       this.consigneeName,
//       this.consigneeMobileNo,
//       this.consigneeEmail,
//       this.consigneeZoneNo,
//       this.consigneeStreetNo,
//       this.consigneeBuildingNo,
//       this.consigneeAddress,
//       this.consigneeLatitude,
//       this.consigneeLongitude,
//       this.itemName,
//       this.itemDescription,
//       this.quantity,
//       this.weight,
//       this.orderAmount,
//       this.paymentType,
//       this.feCode,
//       this.status,
//       this.pickedAt,
//       this.deliveredAt,
//       this.failedAt,
//       this.deliveryProof,
//       this.failedDeliveryProof,
//       this.signature,
//       this.collectedAmount,
//       this.reconciled,
//       this.reconciledAt,
//       this.cancelReason,
//       this.remarks,
//       this.createdAt,
//       this.updatedAt});

//   C2COrdersData.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     merchantId = json['merchant_id'];
//     awbNo = json['awb_no'];
//     orderRefNumber = json['order_ref_number'];
//     shipperName = json['shipper_name'];
//     shipperMobileNo = json['shipper_mobile_no'];
//     shipperEmail = json['shipper_email'];
//     shipperZoneNo = json['shipper_zone_no'];
//     shipperStreetNo = json['shipper_street_no'];
//     shipperBuildingNo = json['shipper_building_no'];
//     shipperAddress = json['shipper_address'];
//     shipperLatitude = json['shipper_latitude'];
//     shipperLongitude = json['shipper_longitude'];
//     consigneeName = json['consignee_name'];
//     consigneeMobileNo = json['consignee_mobile_no'];
//     consigneeEmail = json['consignee_email'];
//     consigneeZoneNo = json['consignee_zone_no'];
//     consigneeStreetNo = json['consignee_street_no'];
//     consigneeBuildingNo = json['consignee_building_no'];
//     consigneeAddress = json['consignee_address'];
//     consigneeLatitude = json['consignee_latitude'];
//     consigneeLongitude = json['consignee_longitude'];
//     itemName = json['item_name'];
//     itemDescription = json['item_description'];
//     quantity = json['quantity'];
//     weight = json['weight'];
//     orderAmount = json['order_amount'];
//     paymentType = json['payment_type'];
//     feCode = json['fe_code'];
//     status = json['status'];
//     pickedAt = json['picked_at'];
//     deliveredAt = json['delivered_at'];
//     failedAt = json['failed_at'];
//     deliveryProof = json['delivery_proof'];
//     failedDeliveryProof = json['failed_delivery_proof'];
//     signature = json['signature'];
//     collectedAmount = json['collected_amount'];
//     reconciled = json['reconciled'];
//     reconciledAt = json['reconciled_at'];
//     cancelReason = json['cancel_reason'];
//     remarks = json['remarks'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['merchant_id'] = this.merchantId;
//     data['awb_no'] = this.awbNo;
//     data['order_ref_number'] = this.orderRefNumber;
//     data['shipper_name'] = this.shipperName;
//     data['shipper_mobile_no'] = this.shipperMobileNo;
//     data['shipper_email'] = this.shipperEmail;
//     data['shipper_zone_no'] = this.shipperZoneNo;
//     data['shipper_street_no'] = this.shipperStreetNo;
//     data['shipper_building_no'] = this.shipperBuildingNo;
//     data['shipper_address'] = this.shipperAddress;
//     data['shipper_latitude'] = this.shipperLatitude;
//     data['shipper_longitude'] = this.shipperLongitude;
//     data['consignee_name'] = this.consigneeName;
//     data['consignee_mobile_no'] = this.consigneeMobileNo;
//     data['consignee_email'] = this.consigneeEmail;
//     data['consignee_zone_no'] = this.consigneeZoneNo;
//     data['consignee_street_no'] = this.consigneeStreetNo;
//     data['consignee_building_no'] = this.consigneeBuildingNo;
//     data['consignee_address'] = this.consigneeAddress;
//     data['consignee_latitude'] = this.consigneeLatitude;
//     data['consignee_longitude'] = this.consigneeLongitude;
//     data['item_name'] = this.itemName;
//     data['item_description'] = this.itemDescription;
//     data['quantity'] = this.quantity;
//     data['weight'] = this.weight;
//     data['order_amount'] = this.orderAmount;
//     data['payment_type'] = this.paymentType;
//     data['fe_code'] = feCode;
//     data['status'] = this.status;
//     data['picked_at'] = this.pickedAt;
//     data['delivered_at'] = this.deliveredAt;
//     data['failed_at'] = this.failedAt;
//     data['delivery_proof'] = this.deliveryProof;
//     data['failed_delivery_proof'] = this.failedDeliveryProof;
//     data['signature'] = this.signature;
//     data['collected_amount'] = this.collectedAmount;
//     data['reconciled'] = this.reconciled;
//     data['reconciled_at'] = this.reconciledAt;
//     data['cancel_reason'] = this.cancelReason;
//     data['remarks'] = this.remarks;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     return data;
//   }
// }


class C2cOrdersData {
  int? id;
  int? merchantId;
  String? awbNo;
  String? orderRefNumber;
  String? shipperName;
  String? shipperMobileNo;
  String? shipperEmail;
  String? shipperZoneNo;
  String? shipperStreetNo;
  String? shipperBuildingNo;
  String? shipperAddress;
  String? shipperLatitude;
  String? shipperLongitude;
  String? consigneeName;
  String? consigneeMobileNo;
  String? consigneeEmail;
  String? consigneeZoneNo;
  String? consigneeStreetNo;
  String? consigneeBuildingNo;
  String? consigneeAddress;
  String? consigneeLatitude;
  String? consigneeLongitude;
  String? itemName;
  String? itemDescription;
  int? quantity;
  String? weight;
  String? orderAmount;
  String? paymentType;
  String? feCode;
  String? status;
  String? pickedAt;
  String? deliveredAt;
  String? failedAt;
  String? deliveryProof;
  String? failedDeliveryProof;
  String? signature;
  String? collectedAmount;
  bool? reconciled;
  String? reconciledAt;
  String? reason;
  String? remarks;
  String? createdAt;
  String? updatedAt;

  C2cOrdersData(
      {this.id,
      this.merchantId,
      this.awbNo,
      this.orderRefNumber,
      this.shipperName,
      this.shipperMobileNo,
      this.shipperEmail,
      this.shipperZoneNo,
      this.shipperStreetNo,
      this.shipperBuildingNo,
      this.shipperAddress,
      this.shipperLatitude,
      this.shipperLongitude,
      this.consigneeName,
      this.consigneeMobileNo,
      this.consigneeEmail,
      this.consigneeZoneNo,
      this.consigneeStreetNo,
      this.consigneeBuildingNo,
      this.consigneeAddress,
      this.consigneeLatitude,
      this.consigneeLongitude,
      this.itemName,
      this.itemDescription,
      this.quantity,
      this.weight,
      this.orderAmount,
      this.paymentType,
      this.feCode,
      this.status,
      this.pickedAt,
      this.deliveredAt,
      this.failedAt,
      this.deliveryProof,
      this.failedDeliveryProof,
      this.signature,
      this.collectedAmount,
      this.reconciled,
      this.reconciledAt,
      this.reason,
      this.remarks,
      this.createdAt,
      this.updatedAt});

  C2cOrdersData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    merchantId = json['merchant_id'];
    awbNo = json['awb_no'];
    orderRefNumber = json['order_ref_number'];
    shipperName = json['shipper_name'];
    shipperMobileNo = json['shipper_mobile_no'];
    shipperEmail = json['shipper_email'];
    shipperZoneNo = json['shipper_zone_no'];
    shipperStreetNo = json['shipper_street_no'];
    shipperBuildingNo = json['shipper_building_no'];
    shipperAddress = json['shipper_address'];
    shipperLatitude = json['shipper_latitude'];
    shipperLongitude = json['shipper_longitude'];
    consigneeName = json['consignee_name'];
    consigneeMobileNo = json['consignee_mobile_no'];
    consigneeEmail = json['consignee_email'];
    consigneeZoneNo = json['consignee_zone_no'];
    consigneeStreetNo = json['consignee_street_no'];
    consigneeBuildingNo = json['consignee_building_no'];
    consigneeAddress = json['consignee_address'];
    consigneeLatitude = json['consignee_latitude'];
    consigneeLongitude = json['consignee_longitude'];
    itemName = json['item_name'];
    itemDescription = json['item_description'];
    quantity = json['quantity'];
    weight = json['weight'];
    orderAmount = json['order_amount'];
    paymentType = json['payment_type'];
    feCode = json['fe_code'];
    status = json['status'];
    pickedAt = json['picked_at'];
    deliveredAt = json['delivered_at'];
    failedAt = json['failed_at'];
    deliveryProof = json['delivery_proof'];
    failedDeliveryProof = json['failed_delivery_proof'];
    signature = json['signature'];
    collectedAmount = json['collected_amount'];
    reconciled = json['reconciled'];
    reconciledAt = json['reconciled_at'];
    reason = json['reason'];
    remarks = json['remarks'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['merchant_id'] = this.merchantId;
    data['awb_no'] = this.awbNo;
    data['order_ref_number'] = this.orderRefNumber;
    data['shipper_name'] = this.shipperName;
    data['shipper_mobile_no'] = this.shipperMobileNo;
    data['shipper_email'] = this.shipperEmail;
    data['shipper_zone_no'] = this.shipperZoneNo;
    data['shipper_street_no'] = this.shipperStreetNo;
    data['shipper_building_no'] = this.shipperBuildingNo;
    data['shipper_address'] = this.shipperAddress;
    data['shipper_latitude'] = this.shipperLatitude;
    data['shipper_longitude'] = this.shipperLongitude;
    data['consignee_name'] = this.consigneeName;
    data['consignee_mobile_no'] = this.consigneeMobileNo;
    data['consignee_email'] = this.consigneeEmail;
    data['consignee_zone_no'] = this.consigneeZoneNo;
    data['consignee_street_no'] = this.consigneeStreetNo;
    data['consignee_building_no'] = this.consigneeBuildingNo;
    data['consignee_address'] = this.consigneeAddress;
    data['consignee_latitude'] = this.consigneeLatitude;
    data['consignee_longitude'] = this.consigneeLongitude;
    data['item_name'] = this.itemName;
    data['item_description'] = this.itemDescription;
    data['quantity'] = this.quantity;
    data['weight'] = this.weight;
    data['order_amount'] = this.orderAmount;
    data['payment_type'] = this.paymentType;
    data['fe_code'] = this.feCode;
    data['status'] = this.status;
    data['picked_at'] = this.pickedAt;
    data['delivered_at'] = this.deliveredAt;
    data['failed_at'] = this.failedAt;
    data['delivery_proof'] = this.deliveryProof;
    data['failed_delivery_proof'] = this.failedDeliveryProof;
    data['signature'] = this.signature;
    data['collected_amount'] = this.collectedAmount;
    data['reconciled'] = this.reconciled;
    data['reconciled_at'] = this.reconciledAt;
    data['reason'] = this.reason;
    data['remarks'] = this.remarks;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
