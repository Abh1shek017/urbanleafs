import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

// ✅ Stream provider that listens to all notifications from all types
final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return repository.getAllNotificationsStream();
});

// ✅ Future provider for creating notifications with explicit type
final createNotificationProvider = FutureProvider.family<void, Map<String, String>>((ref, params) async {
  final repository = ref.read(notificationsRepositoryProvider);

  final type = params['type'];
  if (type == null) {
    throw Exception("Notification type is required.");
  }

  await repository.createNotification(
    title: params['title'] ?? '',
    body: params['body'] ?? '',
    type: type,
  );
});
