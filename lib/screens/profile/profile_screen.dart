import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urbanleafs/providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userAsync = ref.watch(currentUserStreamProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text("Error: $err"))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text("User not found")));
        }

        final username = user.username;
        final roleName = user.role.name;

        return Scaffold(
          appBar: AppBar(title: const Text("Profile")),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade200,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : "U",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(username),
                  subtitle: Text("Role: $roleName"),
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  title: const Text("Edit Profile"),
                  onTap: () => context.go('/profile/edit'),
                ),
                ListTile(
                  title: const Text("Change Password"),
                  onTap: () => context.go('/profile/change-password'),
                ),
                ListTile(
                  title: const Text("Legal & Compliance"),
                  onTap: () => context.go('/legal'),
                ),
                ListTile(
                  title: const Text("About App"),
                  onTap: () => context.go('/legal/about'),
                ),
                ListTile(
                  title: const Text("Logout"),
                  trailing: const Icon(Icons.logout),
                  onTap: () {
                    ref.read(authServiceProvider).logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
