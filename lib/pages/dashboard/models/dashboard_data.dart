class DashBoardData {
  TodayOrdersCount? todayOrdersCount;
  TodayOrdersCount? allOrdersCount;

  DashBoardData({this.todayOrdersCount, this.allOrdersCount});

  DashBoardData.fromJson(Map<String, dynamic> json) {
    todayOrdersCount = json['today_orders_count'] != null
        ? TodayOrdersCount.fromJson(json['today_orders_count'])
        : null;
    allOrdersCount = json['all_orders_count'] != null
        ? TodayOrdersCount.fromJson(json['all_orders_count'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (todayOrdersCount != null) {
      data['today_orders_count'] = todayOrdersCount!.toJson();
    }
    if (allOrdersCount != null) {
      data['all_orders_count'] = allOrdersCount!.toJson();
    }
    return data;
  }
}

class TodayOrdersCount {
  int? aLLORDER;
  int? aSSIGNED;
  int? pICKED;
  int? oFD;
  int? uNDELIVERED;
  int? reached;
  int? dELIVERED;

  TodayOrdersCount(
      {this.aLLORDER,
        this.aSSIGNED,
        this.pICKED,
        this.oFD,
        this.uNDELIVERED,
        this.reached,
        this.dELIVERED});

  TodayOrdersCount.fromJson(Map<String, dynamic> json) {
    aLLORDER = json['ALL_ORDER'];
    aSSIGNED = json['ASSIGNED'];
    pICKED = json['PICKED'];
    oFD = json['OFD'];
    uNDELIVERED = json['UNDELIVERED'];
    reached= json['REACHED'];
    dELIVERED = json['DELIVERED'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ALL_ORDER'] = aLLORDER;
    data['ASSIGNED'] = aSSIGNED;
    data['PICKED'] = pICKED;
    data['OFD'] = oFD;
    data['UNDELIVERED'] = uNDELIVERED;
    data['REACHED'] = reached;
    data['DELIVERED'] = dELIVERED;
    return data;
  }
}

class AttendanceModel {
  // final int? id;
  // final int? userId;
  final bool? markAttendance;
  // final String? date;
  // final String? checkIn;
  // final String? checkOut;
  // final num workingHours;
  // final String? status;
  // final DateTime? createdAt;
  // final DateTime? updatedAt;

  AttendanceModel({
    // this.id,
    // this.userId,
    this.markAttendance = false,
    // this.date,
    // this.checkIn,
    // this.checkOut,
    // this.workingHours = 0,
    // this.status,
    // this.createdAt,
    // this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      // id: json['id'] as int?,
      // userId: json['user_id'] as int?,
      markAttendance: json['is_marked_attendance'],
      // date: json['date'] as String?,
      // checkIn: json['check_in'] as String?,
      // checkOut: json['check_out'] as String?,
      // workingHours: json['working_hours'] is num
      //     ? json['working_hours'] as num
      //     : num.tryParse(
      //   json['working_hours']?.toString() ?? '',
      // ) ??
      //     0,
      // status: json['status'] as String?,
      // createdAt: json['created_at'] != null
      //     ? DateTime.tryParse(json['created_at'].toString())
      //     : null,
      // updatedAt: json['updated_at'] != null
      //     ? DateTime.tryParse(json['updated_at'].toString())
      //     : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id': id,
      // 'user_id': userId,
      'is_marked_attendance': markAttendance,
      // 'date': date,
      // 'check_in': checkIn,
      // 'check_out': checkOut,
      // 'working_hours': workingHours,
      // 'status': status,
      // 'created_at': createdAt?.toIso8601String(),
      // 'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
