class DashBoardData {
  TodayOrdersCount? todayOrdersCount;
  TodayOrdersCount? allOrdersCount;

  DashBoardData({this.todayOrdersCount, this.allOrdersCount});

  DashBoardData.fromJson(Map<String, dynamic> json) {
    todayOrdersCount = json['today_orders_count'] != null
        ? new TodayOrdersCount.fromJson(json['today_orders_count'])
        : null;
    allOrdersCount = json['all_orders_count'] != null
        ? new TodayOrdersCount.fromJson(json['all_orders_count'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.todayOrdersCount != null) {
      data['today_orders_count'] = this.todayOrdersCount!.toJson();
    }
    if (this.allOrdersCount != null) {
      data['all_orders_count'] = this.allOrdersCount!.toJson();
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
  int? dELIVERED;

  TodayOrdersCount(
      {this.aLLORDER,
        this.aSSIGNED,
        this.pICKED,
        this.oFD,
        this.uNDELIVERED,
        this.dELIVERED});

  TodayOrdersCount.fromJson(Map<String, dynamic> json) {
    aLLORDER = json['ALL_ORDER'];
    aSSIGNED = json['ASSIGNED'];
    pICKED = json['PICKED'];
    oFD = json['OFD'];
    uNDELIVERED = json['UNDELIVERED'];
    dELIVERED = json['DELIVERED'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ALL_ORDER'] = this.aLLORDER;
    data['ASSIGNED'] = this.aSSIGNED;
    data['PICKED'] = this.pICKED;
    data['OFD'] = this.oFD;
    data['UNDELIVERED'] = this.uNDELIVERED;
    data['DELIVERED'] = this.dELIVERED;
    return data;
  }
}
