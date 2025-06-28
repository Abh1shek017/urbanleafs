import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urbanleafs/providers/auth_provider.dart';
// import '../../models/user_model.dart';
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (user) {
        if (user == null) {
          return const Center(child: Text("User not found"));
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Profile")),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: Text(user.username[0].toUpperCase()),
                ),
                title: Text(user.username),
                subtitle: Text("Role: ${user.role.name}"),
              ),
              const Divider(),
              ListTile(
                title: const Text("Edit Profile"),
                onTap: () => Navigator.pushNamed(context, '/profile/edit'),
              ),
              ListTile(
                title: const Text("Change Password"),
                onTap: () =>
                    Navigator.pushNamed(context, '/profile/change-password'),
              ),
              ListTile(
                title: const Text("Legal & Compliance"),
                onTap: () => Navigator.pushNamed(context, '/legal'),
              ),
              ListTile(
                title: const Text("About App"),
                onTap: () => Navigator.pushNamed(context, '/legal/about'),
              ),
              ListTile(
                title: const Text("Logout"),
                trailing: const Icon(Icons.logout),
                onTap: () {
                  ref.read(authServiceProvider).logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
