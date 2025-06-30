import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showFullImage(String url) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InteractiveViewer(child: Image.network(url)),
        ),
      ),
      transitionBuilder: (_, anim1, __, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

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
        final profileImageUrl = user.profileImageUrl;

        return Scaffold(
          appBar: AppBar(title: const Text("Profile")),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SlideTransition(
                  position: _slideAnimation,
                  child: Card(
                    elevation: 6,
                    shadowColor: Colors.black45,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (profileImageUrl != null &&
                                  profileImageUrl.isNotEmpty) {
                                _showFullImage(profileImageUrl);
                              }
                            },
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.6, end: 1.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: _controller,
                                      curve: Curves.easeOutBack,
                                    ),
                                  ),
                              child: FadeTransition(
                                opacity: _controller,
                                child: profileImageUrl != null &&
                                        profileImageUrl.isNotEmpty
                                    ? CircleAvatar(
                                        radius: 28,
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                          profileImageUrl,
                                        ),
                                        backgroundColor: Colors.grey[300],
                                      )
                                    : CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.green.shade700,
                                        child: Text(
                                          username.isNotEmpty
                                              ? username[0].toUpperCase()
                                              : "U",
                                          style: const TextStyle(
                                            fontSize: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Role: $roleName",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text("Edit Profile"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/edit'),
                ),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.orange),
                  title: const Text("Change Password"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/change-password'),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.gavel, color: Colors.deepPurple),
                  title: const Text("Legal & Compliance"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/legal'),
                ),
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.teal),
                  title: const Text("About App"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/legal/about'),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    ref.read(authServiceProvider).logout();
                    context.push('/login');
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
