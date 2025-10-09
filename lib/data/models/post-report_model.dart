class PostReport {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reportedPostId;
  final String reason;
  final String? adminNotes;
  final DateTime reportTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reportedPostId,
    required this.reason,
    this.adminNotes,
    required this.reportTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostReport.fromJson(Map<String, dynamic> json) {
    return PostReport(
      id: json['_id'] ?? json['id'],
      reporterId: json['reporterId'],
      reportedUserId: json['reportedUserId'],
      reportedPostId: json['reportedPostId'],
      reason: json['reason'],
      adminNotes: json['adminNotes'],
      reportTime: DateTime.parse(json['reportTime']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reportedPostId': reportedPostId,
      'reason': reason,
      'status': status,
      'adminNotes': adminNotes,
      'reportTime': reportTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
