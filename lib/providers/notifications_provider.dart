import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notifiction_model.dart';
import '../repositories/notification_repository.dart';

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((
  ref,
) {
  return ref.watch(notificationsRepositoryProvider).getAllNotificationsStream();
});

final createNotificationProvider =
    FutureProvider.family<void, Map<String, String>>((ref, params) async {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.createNotification(
        title: params['title'] ?? '',
        body: params['body'] ?? '',
      );
    });
