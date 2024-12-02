class CargoOrderDataModel {
  CargoOrderDataModel({
    String? shipperName,
    String? shipperContactNo,
    String? shipperAddress,
    String? email,
    String? pickupDate,
    String? qatarId,
    String? hawbNo,
    String? destination,
    String? feCode,
    String? fieldExecutiveName,
    dynamic remarks,
    String? status,
    String? cargoType,
    dynamic billNo,
    String? movementType,
    dynamic orderType,
    bool? isUserAgree,
    dynamic pkg,
    dynamic grW,
    dynamic volumeWeight,
    dynamic dimension,
    dynamic chargeableAmount,
  }) {
    _shipperName = shipperName;
    _shipperContactNo = shipperContactNo;
    _shipperAddress = shipperAddress;
    _email = email;
    _pickupDate = pickupDate;
    _qatarId = qatarId;
    _hawbNo = hawbNo;
    _destination = destination;
    _feCode = feCode;
    _fieldExecutiveName = fieldExecutiveName;
    _remarks = remarks;
    _status = status;
    _cargoType = cargoType;
    _billNo = billNo;
    _movementType = movementType;
    _orderType = orderType;
    _pkg = pkg;
    _grW = grW;
    _volumeWeight = volumeWeight;
    _dimension = dimension;
    _chargeableAmount = chargeableAmount;
  }

  CargoOrderDataModel.fromJson(dynamic json) {
    _shipperName = json['shipper_name'];
    _shipperContactNo = json['shipper_contact_no'];
    _shipperAddress = json['shipper_address'];
    _email = json['email'];
    _pickupDate = json['pickup_date'];
    _qatarId = json['qatar_id'];
    _hawbNo = json['hawb_no'];
    _destination = json['destination'];
    _feCode = json['fe_code'];
    _fieldExecutiveName = json['field_executive_name'];
    _remarks = json['remarks'];
    _status = json['status'];
    _cargoType = json['cargo_type'];
    _billNo = json['bill_no'];
    _movementType = json['movement_type'];
    _orderType = json['order_type'];
    _pkg = json['pkg'];
    _grW = json['gr_w'];
    _volumeWeight = json['volume_weight'];
    _dimension = json['dimension'];
    _chargeableAmount = json['chargeable_amount'];
  }

  String? _shipperName;
  String? _shipperContactNo;
  String? _shipperAddress;
  String? _email;
  String? _pickupDate;
  String? _qatarId;
  String? _hawbNo;
  String? _destination;
  String? _feCode;
  String? _fieldExecutiveName;
  dynamic _remarks;
  String? _status;
  String? _cargoType;
  dynamic _billNo;
  String? _movementType;
  dynamic _orderType;
  dynamic _pkg;
  dynamic _grW;
  dynamic _volumeWeight;
  dynamic _dimension;
  dynamic _chargeableAmount;
  bool? isUserAgree;

  CargoOrderDataModel copyWith({
    String? shipperName,
    String? shipperContactNo,
    String? shipperAddress,
    String? email,
    String? pickupDate,
    String? qatarId,
    String? hawbNo,
    String? destination,
    String? feCode,
    String? fieldExecutiveName,
    dynamic remarks,
    String? status,
    String? cargoType,
    dynamic billNo,
    String? movementType,
    dynamic orderType,
    dynamic pkg,
    dynamic grW,
    dynamic volumeWeight,
    dynamic dimension,
    dynamic chargeableAmount,
    bool? isUserAgree,
  }) =>
      CargoOrderDataModel(
        shipperName: shipperName ?? _shipperName,
        shipperContactNo: shipperContactNo ?? _shipperContactNo,
        shipperAddress: shipperAddress ?? _shipperAddress,
        email: email ?? _email,
        pickupDate: pickupDate ?? _pickupDate,
        qatarId: qatarId ?? _qatarId,
        hawbNo: hawbNo ?? _hawbNo,
        destination: destination ?? _destination,
        feCode: feCode ?? _feCode,
        fieldExecutiveName: fieldExecutiveName ?? _fieldExecutiveName,
        remarks: remarks ?? _remarks,
        status: status ?? _status,
        cargoType: cargoType ?? _cargoType,
        billNo: billNo ?? _billNo,
        movementType: movementType ?? _movementType,
        orderType: orderType ?? _orderType,
        pkg: pkg ?? _pkg,
        grW: grW ?? _grW,
        volumeWeight: volumeWeight ?? _volumeWeight,
        dimension: dimension ?? _dimension,
        chargeableAmount: chargeableAmount ?? _chargeableAmount,
        isUserAgree: isUserAgree ?? false,
      );

  String? get shipperName => _shipperName;

  String? get shipperContactNo => _shipperContactNo;

  String? get shipperAddress => _shipperAddress;

  String? get email => _email;

  String? get pickupDate => _pickupDate;

  String? get qatarId => _qatarId;

  String? get hawbNo => _hawbNo;

  String? get destination => _destination;

  String? get feCode => _feCode;

  String? get fieldExecutiveName => _fieldExecutiveName;

  dynamic get remarks => _remarks;

  String? get status => _status;

  String? get cargoType => _cargoType;

  dynamic get billNo => _billNo;

  String? get movementType => _movementType;

  dynamic get orderType => _orderType;

  dynamic get pkg => _pkg;

  dynamic get grW => _grW;

  dynamic get volumeWeight => _volumeWeight;

  dynamic get dimension => _dimension;

  dynamic get chargeableAmount => _chargeableAmount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['shipper_name'] = _shipperName;
    map['shipper_contact_no'] = _shipperContactNo;
    map['shipper_address'] = _shipperAddress;
    map['email'] = _email;
    map['pickup_date'] = _pickupDate;
    map['qatar_id'] = _qatarId;
    map['hawb_no'] = _hawbNo;
    map['destination'] = _destination;
    map['fe_code'] = _feCode;
    map['field_executive_name'] = _fieldExecutiveName;
    map['remarks'] = _remarks;
    map['status'] = _status;
    map['cargo_type'] = _cargoType;
    map['bill_no'] = _billNo;
    map['movement_type'] = _movementType;
    map['order_type'] = _orderType;
    map['pkg'] = _pkg;
    map['gr_w'] = _grW;
    map['volume_weight'] = _volumeWeight;
    map['dimension'] = _dimension;
    map['chargeable_amount'] = _chargeableAmount;
    return map;
  }
}
