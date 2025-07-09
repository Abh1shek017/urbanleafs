import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.timestamp,
  });

  // ✅ Handles both 'body' & 'message' fields for backward compatibility
  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? map['message'] ?? '',
      type: map['type'] ?? 'general',
      isRead: map['isRead'] ?? false,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ✅ Consistently saves as 'message' to Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': body,
      'type': type,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
