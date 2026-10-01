class CancelReason {
  final int id;
  final String reason;
  final String type;
  final int active;


  CancelReason({
    required this.id,
    required this.reason,
    required this.type,
    required this.active,

  });

  factory CancelReason.fromJson(Map<String, dynamic> json) {
    return CancelReason(
      id: json['id'],
      reason: json['reason'],
      type: json['type'],
      active: json['active'],

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reason': reason,
      'type': type,
      'active': active,
    };
  }
}
