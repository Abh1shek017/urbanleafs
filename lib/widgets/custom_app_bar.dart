import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../providers/current_user_stream_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/local_storage_provider.dart';
import '../../providers/theme_provider.dart';
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
                final unreadCount = notifications
                    .where((n) => !n.isRead)
                    .length;

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
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
              onPressed: () => _showSettingsMenu(context, ref, user),
            ),
          ],
        );
      },
    );
  }

  // your existing _showSettingsMenu, _buildCategory, _menuTile etc here...
}

void _showSettingsMenu(BuildContext context, WidgetRef ref, UserModel? user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) {
      // Map to store expansion state
      final Map<String, bool> expandedStates = {
        "user": false,
        "settings": false,
        "appearance": false,
        "activity": false,
        "support": false,
        "legal": false,
      };

      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildCategory(
                  ctx,
                  "🔐 User Account",
                  "user",
                  expandedStates,
                  setState,
                  [
                    _menuTile(ctx, "Profile", Icons.person, '/profile'),
                    _menuTile(ctx, "Edit Profile", Icons.edit, '/profile/edit'),
                    _menuTile(
                      ctx,
                      "Change Password",
                      Icons.lock_outline,
                      '/profile/change-password',
                    ),
                  ],
                ),
                _buildCategory(
                  ctx,
                  "⚙️ App Settings",
                  "settings",
                  expandedStates,
                  setState,
                  [
                    _menuTile(
                      ctx,
                      "General Settings",
                      Icons.settings,
                      '/settings/general',
                    ),
                    _menuTile(
                      ctx,
                      "Notifications",
                      Icons.notifications,
                      '/settings/notifications',
                    ),
                    _menuTile(
                      ctx,
                      "Privacy Settings",
                      Icons.privacy_tip,
                      '/settings/privacy',
                    ),
                    _menuTile(
                      ctx,
                      "Language",
                      Icons.language,
                      '/settings/language',
                    ),
                    _themeToggleTile(ctx, ref),
                  ],
                ),
                _buildCategory(
                  ctx,
                  "🎨 Appearance",
                  "appearance",
                  expandedStates,
                  setState,
                  [
                    _menuTile(ctx, "Font Size", Icons.format_size, null),
                    _menuTile(ctx, "Layout Mode", Icons.view_module, null),
                  ],
                ),
                _buildCategory(
                  ctx,
                  "📊 Activity",
                  "activity",
                  expandedStates,
                  setState,
                  [
                    _menuTile(ctx, "My Orders / History", Icons.history, null),
                    _menuTile(
                      ctx,
                      "Favorites / Bookmarks",
                      Icons.bookmark_border,
                      null,
                    ),
                    _menuTile(ctx, "Downloads", Icons.download, null),
                    _menuTile(ctx, "Recent Activity", Icons.access_time, null),
                    _menuTile(
                      ctx,
                      "Usage Stats",
                      Icons.pie_chart_outline,
                      null,
                    ),
                  ],
                ),
                _buildCategory(
                  ctx,
                  "💬 Support & Feedback",
                  "support",
                  expandedStates,
                  setState,
                  [
                    _menuTile(ctx, "Help & Support", Icons.help_outline, null),
                    _menuTile(ctx, "FAQs", Icons.question_answer, null),
                    _menuTile(ctx, "Feedback", Icons.feedback, null),
                    _menuTile(
                      ctx,
                      "Report a Problem",
                      Icons.report_problem,
                      null,
                    ),
                    _menuTile(ctx, "Contact Us", Icons.contact_mail, null),
                  ],
                ),
                _buildCategory(
                  ctx,
                  "📄 Legal & Info",
                  "legal",
                  expandedStates,
                  setState,
                  [
                    _aboutTile(ctx),
                    _menuTile(ctx, "Terms & Conditions", Icons.article, null),
                    _menuTile(ctx, "Privacy Policy", Icons.privacy_tip, null),
                    _menuTile(
                      ctx,
                      "App Version",
                      Icons.system_update_alt,
                      null,
                    ),
                  ],
                ),
                const Divider(),
                _logoutTile(ctx, ref),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildCategory(
  BuildContext context,
  String title,
  String key,
  Map<String, bool> expandedStates,
  void Function(void Function()) setState,
  List<Widget> children,
) {
  return ExpansionTile(
    initiallyExpanded: expandedStates[key]!,
    onExpansionChanged: (isExpanded) => setState(() {
      expandedStates[key] = isExpanded;
    }),
    title: Text(title, style: Theme.of(context).textTheme.titleMedium),
    children: children,
  );
}

Widget _menuTile(
  BuildContext context,
  String label,
  IconData icon,
  String? route,
) {
  return ListTile(
    leading: Icon(icon),
    title: Text(label),
    onTap: route != null
        ? () {
            Navigator.pop(context);
            GoRouter.of(context).push(route);
          }
        : null,
  );
}

Widget _themeToggleTile(BuildContext context, WidgetRef ref) {
  return StatefulBuilder(
    builder: (ctx, setState) {
      final isDark = ref.watch(themeModeProvider) == AppTheme.dark;
      return SwitchListTile(
        title: const Text("Theme (Light/Dark)"),
        secondary: const Icon(Icons.brightness_6),
        value: isDark,
        onChanged: (val) {
          ref.read(themeModeProvider.notifier).state = val
              ? AppTheme.dark
              : AppTheme.light;
          ref
              .read(localStorageServiceProvider)
              .saveThemeMode(val ? 'dark' : 'light');
          setState(() {});
        },
      );
    },
  );
}

Widget _aboutTile(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.info_outline),
    title: const Text("About App"),
    onTap: () {
      Navigator.pop(context);
      showAboutDialog(
        context: context,
        applicationName: "UrbanLeafs",
        applicationVersion: "v1.0.0",
        applicationLegalese: "© 2025 UrbanLeafs Pvt Ltd.",
      );
    },
  );
}

Widget _logoutTile(BuildContext context, WidgetRef ref) {
  return ListTile(
    leading: const Icon(Icons.logout, color: Colors.red),
    title: const Text("Logout", style: TextStyle(color: Colors.red)),
    onTap: () {
      ref.read(authServiceProvider).logout();
      Navigator.pop(context);
      GoRouter.of(context).push('/login');
    },
  );
}
