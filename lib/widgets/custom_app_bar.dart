import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/current_user_stream_provider.dart';
import '../../providers/notifications_provider.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  const CustomAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return currentUserAsync.when(
      loading: () => AppBar(title: Text(title)),
      error: (_, __) => AppBar(title: Text(title)),
      data: (user) {
        return AppBar(
          title: Text(
            "UrbanLeafs",
            style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
          ),
          actions: [
            notificationsAsync.when(
              data: (notifications) {
                final unreadCount =
                    notifications.where((n) => !n.isRead).length;
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        GoRouter.of(context).push('/notifications');
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
              error: (_, __) => IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // 🚀 Now directly navigate to your new settings menu screen
                GoRouter.of(context).push('/settings-menu');
              },
            ),
          ],
        );
      },
    );
  }
}
