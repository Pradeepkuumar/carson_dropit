import 'dart:convert';

DashboardData dashboardDataFromJson(String str) => DashboardData.fromJson(json.decode(str));

String dashboardDataToJson(DashboardData data) => json.encode(data.toJson());

class DashboardData {
    DashboardData({
         this.cancelled,
         this.delivered,
         this.assigned,
         this.ofd,
         this.picked,
         this.allOrder,
    });

    int? cancelled;
    int? delivered;
    int? assigned;
    int? ofd;
    int? picked;
    int? allOrder;

    factory DashboardData.fromJson(Map<dynamic, dynamic> json) => DashboardData(
        cancelled: json["CANCELLED"],
        delivered: json["DELIVERED"],
        assigned: json["ASSIGNED"],
        ofd: json["OFD"],
        picked: json["PICKED"],
        allOrder: json["ALL_ORDER"],
    );

    Map<dynamic, dynamic> toJson() => {
        "CANCELLED": cancelled,
        "DELIVERED": delivered,
        "ASSIGNED": assigned,
        "OFD": ofd,
        "PICKED": picked,
        "ALL_ORDER": allOrder,
    };
}
