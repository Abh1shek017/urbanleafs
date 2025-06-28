import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("General Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: themeMode == AppTheme.dark,
            onChanged: (value) {
              final newTheme = value ? AppTheme.dark : AppTheme.light;
              ref.read(themeModeProvider.notifier).state = newTheme;
            },
          ),
          SwitchListTile(
            title: const Text("Auto Sync Data"),
            value: true,
            onChanged: null,
          ),
          ListTile(
            title: const Text("Language"),
            subtitle: const Text("English"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, '/settings/language'),
          ),
          const Divider(),
          const ListTile(
            title: Text("App Version"),
            subtitle: Text("v1.0.0"),
          ),
          ListTile(
            title: const Text("Data Backup"),
            subtitle: const Text("Manual backup to Google Drive"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Coming Soon")),
            ),
          ),
        ],
      ),
    );
  }
}
