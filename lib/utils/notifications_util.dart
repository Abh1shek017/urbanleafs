import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addNotification(String type, String title, String message) async {
  final firestore = FirebaseFirestore.instance;

  await firestore
      .collection('notifications')
      .doc(type)
      .collection('items')
      .add({
    'title': title,
    'message': message,
    'type': type,
    'isRead': false,
    'timestamp': FieldValue.serverTimestamp(),
  });
}
