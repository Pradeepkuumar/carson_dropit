
import 'dart:convert';

DriverData driverDataFromJson(String str) => DriverData.fromJson(json.decode(str));

String driverDataToJson(DriverData data) => json.encode(data.toJson());

class DriverData {
    DriverData({
         this.code,
         this.apiToken,
         this.active,
         this.createdAt,
         this.attendances,
         this.updatedAt,
         this.roleId,
         this.phone,
         this.vendorId,
         this.deviceToken,
         this.name,
         this.id,
         this.email,
    });

    String? code;
    String? apiToken;
    int? active;
    DateTime? createdAt;
    List<Attendance>? attendances;
    DateTime? updatedAt;
    int? roleId;
    String? phone;
    int? vendorId;
    String? deviceToken;
    String? name;
    int? id;
    String? email;

    factory DriverData.fromJson(Map<dynamic, dynamic> json) => DriverData(
        code: json["code"],
        apiToken: json["api_token"],
        active: json["active"],
        createdAt: DateTime.parse(json["created_at"]),
        attendances: List<Attendance>.from(json["attendances"].map((x) => Attendance.fromJson(x))),
        updatedAt: DateTime.parse(json["updated_at"]),
        roleId: json["role_id"],
        phone: json["phone"],
        vendorId: json["vendor_id"],
        deviceToken: json["device_token"],
        name: json["name"],
        id: json["id"],
        email: json["email"],
    );

    Map<dynamic, dynamic> toJson() => {
        "code": code,
        "api_token": apiToken,
        "active": active,
        "created_at": createdAt?.toIso8601String(),
        "attendances": List<dynamic>.from(attendances!.map((x) => x.toJson())),
        "updated_at": updatedAt?.toIso8601String(),
        "role_id": roleId,
        "phone": phone,
        "vendor_id": vendorId,
        "device_token": deviceToken,
        "name": name,
        "id": id,
        "email": email,
    };
}

class Attendance {
    Attendance({
         this.date,
         this.updatedAt,
         this.userId,
         this.workingHours,
         this.createdAt,
         this.id,
         this.markAttendance,
         this.status,
    });

    DateTime? date;
    DateTime? updatedAt;
    int? userId;
    String? workingHours;
    DateTime? createdAt;
    int? id;
    int? markAttendance;
    String? status;

    factory Attendance.fromJson(Map<dynamic, dynamic> json) => Attendance(
        date: DateTime.parse(json["date"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        userId: json["user_id"],
        workingHours: json["working_hours"],
        createdAt: DateTime.parse(json["created_at"]),
        id: json["id"],
        markAttendance: json["mark_attendance"],
        status: json["status"],
    );

    Map<dynamic, dynamic> toJson() => {
        "date": "${date?.year.toString().padLeft(4, '0')}-${date?.month.toString().padLeft(2, '0')}-${date?.day.toString().padLeft(2, '0')}",
        "updated_at": updatedAt?.toIso8601String(),
        "user_id": userId,
        "working_hours": workingHours,
        "created_at": createdAt?.toIso8601String(),
        "id": id,
        "mark_attendance": markAttendance,
        "status": status,
    };
}
