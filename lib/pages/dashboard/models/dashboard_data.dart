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
