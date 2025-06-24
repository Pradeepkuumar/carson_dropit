import 'package:floor/floor.dart';

@entity
class UserData {
  @Insert(onConflict: OnConflictStrategy.replace)
  @PrimaryKey(autoGenerate: true)
  int? id;
  int? roleId;
  int? vendorId;
  String? name;
  String? code;
  String? email;
  String? phone;
  String? apiToken;
  String? address;
  int? active;
  String? avatar;
  String? deviceToken;
  String? latitude;
  String? longitude;
  String? emailVerifiedAt;
  String? createdAt;
  String? updatedAt;
  String? isSignedIn;

  UserData(
      {this.id,
        this.roleId,
        this.vendorId,
        this.name,
        this.code,
        this.email,
        this.phone,
        this.apiToken,
        this.address,
        this.active,
        this.avatar,
        this.deviceToken,
        this.latitude,
        this.longitude,
        this.emailVerifiedAt,
        this.createdAt,
        this.updatedAt,
        this.isSignedIn,
      });

  UserData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    roleId = json['role_id'];
    vendorId = json['vendor_id'];
    name = json['name'];
    code = json['code'];
    email = json['email'];
    phone = json['phone'];
    apiToken = json['api_token'];
    address = json['address'];
    active = json['active'];
    avatar = json['avatar'];
    deviceToken = json['device_token'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    emailVerifiedAt = json['email_verified_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    isSignedIn = json['is_signed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['role_id'] = roleId;
    data['vendor_id'] = vendorId;
    data['name'] = name;
    data['code'] = code;
    data['email'] = email;
    data['phone'] = phone;
    data['api_token'] = apiToken;
    data['address'] = address;
    data['active'] = active;
    data['avatar'] = avatar;
    data['device_token'] = deviceToken;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['email_verified_at'] = emailVerifiedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
