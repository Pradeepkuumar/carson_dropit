class Data {
  String? priority;
  bool? sound;
  bool? contentAvailable;
  String? bodyText;
  String? organization;

  Data({
    this.priority,
    this.sound,
    this.contentAvailable,
    this.bodyText,
    this.organization,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        priority: json['priority'] as String?,
        sound: json['sound'] as bool?,
        contentAvailable: json['content_available'] as bool?,
        bodyText: json['bodyText'] as String?,
        organization: json['organization'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'priority': priority,
        'sound': sound,
        'content_available': contentAvailable,
        'bodyText': bodyText,
        'organization': organization,
      };
}
