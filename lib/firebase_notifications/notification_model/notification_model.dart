import 'data.dart';
import 'notification.dart';

class NotificationModel {
  LocalNotification? local_notification;
  Data? data;

  NotificationModel({this.local_notification, this.data});

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      local_notification: json['notification'] == null
          ? null
          : LocalNotification.fromJson(json['notification'] as Map<String, dynamic>),
      data: json['data'] == null
          ? null
          : Data.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'notification': local_notification?.toJson(),
        'data': data?.toJson(),
      };
}
