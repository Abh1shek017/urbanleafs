import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> types = ['orders', 'expenses', 'payments', 'inventory'];

  // 🔥 Get a combined stream of all notifications across all types
  Stream<List<NotificationModel>> getAllNotificationsStream() {
    final streams = types.map((type) {
      return _firestore
          .collection('notifications')
          .doc(type)
          .collection('items')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return NotificationModel(
                id: doc.id,
                title: data['title'] ?? '',
                body: data['message'] ?? '',
                timestamp:
                    (data['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                type: type,
                isRead: data['isRead'] ?? false,
              );
            }).toList(),
          );
    }).toList();

    // merge all streams into one
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      final allNotifications = <NotificationModel>[];
      for (final stream in streams) {
        final notifications = await stream.first;
        allNotifications.addAll(notifications);
      }
      allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allNotifications;
    });
  }

  // 🔥 Create a notification under correct subcollection
  Future<void> createNotification({
    required String title,
    required String body,
    required String type, // now must specify type
    bool isRead = false,
  }) async {
    await _firestore
        .collection('notifications')
        .doc(type)
        .collection('items')
        .add({
          'title': title,
          'message': body,
          'type': type,
          'isRead': isRead,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // 🔥 Mark a specific notification as read
  Future<void> markAsRead(String type, String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(type)
        .collection('items')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // 🔥 Mark ALL notifications as read across all types
  Future<void> markAllAsRead() async {
    final batch = _firestore.batch();

    for (final type in types) {
      final snapshot = await _firestore
          .collection('notifications')
          .doc(type)
          .collection('items')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
    }

    await batch.commit();
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository();
});
