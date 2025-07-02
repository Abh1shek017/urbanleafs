import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/theme_provider.dart';
import '../../providers/local_storage_provider.dart';

class SettingsMenuScreen extends ConsumerStatefulWidget {
  const SettingsMenuScreen({super.key});

  @override
  ConsumerState<SettingsMenuScreen> createState() => _SettingsMenuScreenState();
}

class _SettingsMenuScreenState extends ConsumerState<SettingsMenuScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, bool> expandedStates = {
    "master_data": false,
    "settings": false,
    "activity": false,
    "support": false,
    "legal": false,
  };

  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideAnimations = List.generate(5, (i) {
      final start = i * 0.1;
      return Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.5, curve: Curves.easeOut),
        ),
      );
    });

    _fadeAnimations = List.generate(5, (i) {
      final start = i * 0.1;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.5, curve: Curves.easeOut),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == AppTheme.dark;

    final categories = [
      _buildCategory("📚 Master Data", "master_data", [
        _menuTile(
          context,
          "Manage Customers",
          Icons.people,
          '/master-data/customers',
        ),
        _menuTile(
          context,
          "Inventory Edits",
          Icons.inventory,
          '/master-data/inventory',
        ),
        _menuTile(
          context,
          "Orders Edit",
          Icons.shopping_cart,
          '/master-data/orders',
        ),
        _menuTile(
          context,
          "Expenses Edit",
          Icons.money_off,
          '/master-data/expenses',
        ),
      ]),
      _buildCategory("⚙️ App Settings", "settings", [
        _menuTile(
          context,
          "General Settings",
          Icons.settings,
          '/settings/general',
        ),
        _menuTile(context, "Language", Icons.language, '/settings/language'),
      ]),
      _buildCategory("📊 Activity", "activity", [
        _menuTile(
          context,
          "My Orders / History",
          Icons.history,
          '/orders/history',
        ),
        _menuTile(
          context,
          "Favorites / Bookmarks",
          Icons.bookmark_border,
          '/activity/favorites',
        ),
        _menuTile(context, "Downloads", Icons.download, '/activity/downloads'),
        _menuTile(
          context,
          "Recent Activity",
          Icons.access_time,
          '/activity/recent',
        ),
        _menuTile(
          context,
          "Usage Stats",
          Icons.pie_chart_outline,
          '/activity/usage',
        ),
      ]),
      _buildCategory("💬 Support & Feedback", "support", [
        _menuTile(
          context,
          "Help & Support",
          Icons.help_outline,
          '/support/help',
        ),
        _menuTile(context, "FAQs", Icons.question_answer, '/support/faq'),
        _menuTile(context, "Feedback", Icons.feedback, '/support/feedback'),
        _menuTile(
          context,
          "Report a Problem",
          Icons.report_problem,
          '/support/report',
        ),
        _menuTile(
          context,
          "Contact Us",
          Icons.contact_mail,
          '/support/contact',
        ),
      ]),
      _buildCategory("📄 Legal & Info", "legal", [
        _menuTile(context, "About App", Icons.info_outline, '/legal/about'),
        _menuTile(
          context,
          "Terms & Conditions",
          Icons.article,
          '/legal/terms-of-service',
        ),
        _menuTile(
          context,
          "Privacy Policy",
          Icons.privacy_tip,
          '/legal/privacy-policy',
        ),
        _menuTile(
          context,
          "App Version",
          Icons.system_update_alt,
          '/legal/about',
        ),
      ]),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.black, Colors.deepPurple.shade900]
              : [Colors.blue.shade100, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Menu"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _themeToggle(isDark),
            const SizedBox(height: 12),
            for (int i = 0; i < categories.length; i++)
              SlideTransition(
                position: _slideAnimations[i],
                child: FadeTransition(
                  opacity: _fadeAnimations[i],
                  child: _glassCard(child: categories[i]),
                ),
              ),
            const Divider(),
            _glassCard(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  GoRouter.of(context).push('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  Widget _themeToggle(bool isDark) {
    return _glassCard(
      child: SwitchListTile(
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
        },
      ),
    );
  }

  Widget _buildCategory(String title, String key, List<Widget> children) {
    return ExpansionTile(
      initiallyExpanded: expandedStates[key] ?? false,
      onExpansionChanged: (isExpanded) {
        setState(() {
          expandedStates[key] = isExpanded;
        });
      },
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      children: children,
    );
  }

  Widget _menuTile(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        GoRouter.of(context).push(route);
      },
    );
  }
}
