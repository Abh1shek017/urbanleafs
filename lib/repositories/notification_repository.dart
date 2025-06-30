import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notifiction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsRepository {
  Stream<List<NotificationModel>> getAllNotificationsStream() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return NotificationModel(
              id: doc.id,
              title: data['title'],
              body: data['body'],
              isRead: data['isRead'] ?? false,
            );
          }).toList(),
        );
  }

  Future<void> createNotification({
    required String title,
    required String body,
    bool isRead = false,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'body': body,
      'isRead': isRead,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository();
});
