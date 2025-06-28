import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/user_repository.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart'; // Ensure this includes UserRole enum

// Capitalize helper
String capitalize(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1).toLowerCase();
}

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final usersAsync = ref.watch(allUsersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error loading users: $err")),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user.username),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ID: ${user.id}"),
                    Text("Role: ${capitalize(user.role.name)}"), // ✅ fixed
                  ],
                ),
                trailing: DropdownButton<UserRole>( // ✅ fixed
                  value: user.role,
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text("Admin"),
                    ),
                    DropdownMenuItem(
                      value: UserRole.regular,
                      child: Text("Worker"),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value != null && value != user.role) {
                      final repo = UserRepository();
                      await repo.updateUser(user.id, {'role': value.name}); // Send string to backend
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
