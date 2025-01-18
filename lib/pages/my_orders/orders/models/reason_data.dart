class CancelReason {
  final int id;
  final String reason;
  final String type;
  final int active;
  final DateTime createdAt;
  final DateTime updatedAt;

  CancelReason({
    required this.id,
    required this.reason,
    required this.type,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CancelReason.fromJson(Map<String, dynamic> json) {
    return CancelReason(
      id: json['id'],
      reason: json['reason'],
      type: json['type'],
      active: json['active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reason': reason,
      'type': type,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
