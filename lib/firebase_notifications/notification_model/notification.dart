import 'package:floor/floor.dart';

@entity
class LocalNotification {
  @Insert(onConflict: OnConflictStrategy.replace)
  @PrimaryKey(autoGenerate: true)
  int? id;
  String? body;
  String? title;

  LocalNotification({this.body, this.title});

  factory LocalNotification.fromJson(Map<String, dynamic> json) => LocalNotification(
        body: json['body'] as String?,
        title: json['title'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'body': body,
        'title': title,
      };
}
