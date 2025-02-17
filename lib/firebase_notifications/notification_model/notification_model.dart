import 'package:floor/floor.dart';

import 'data.dart';
import 'notification.dart';

class NotificationModel {

  LocalNotification? localNotification;
  Data? data;
  NotificationModel({this.localNotification, this.data});

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      localNotification: json['notification'] == null
          ? null
          : LocalNotification.fromJson(json['notification'] as Map<String, dynamic>),
      data: json['data'] == null
          ? null
          : Data.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'notification': localNotification?.toJson(),
        'data': data?.toJson(),
      };
}
