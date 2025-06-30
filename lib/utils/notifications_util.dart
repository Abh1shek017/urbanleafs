import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addNotification({
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
