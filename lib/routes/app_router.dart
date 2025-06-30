// import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../utils/go_router_refresh_stream.dart';

// Screens
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/balance_sheet/balance_sheet_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/orders/today_orders_screen.dart';
import '../screens/payments/today_payments_screen.dart';

// Profile
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';

// Settings
import '../screens/settings/settings_screen.dart';
import '../screens/settings/general_setting_screen.dart';
import '../screens/settings/notifications_screen.dart';
import '../screens/settings/privacy_settings_screen.dart';
import '../screens/settings/language_screen.dart';
import '../screens/appearance/appearance_setting_screen.dart';
import '../screens/settings/manage_users_screen.dart';

// Support
import '../screens/support/faq_screen.dart';
import '../screens/support/feedback_screen.dart';
import '../screens/support/contact_us_screen.dart';

// Legal
import '../screens/legal/legal_screen.dart';
import '../screens/legal/app_info_screen.dart';
import '../screens/legal/privacy_screen.dart';
import '../screens/legal/terms_screen.dart';

// User Test
// import '../../test/user_test.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      ref.read(authServiceProvider).authState,
    ),
    redirect: (context, state) {
      final loggedIn = authStateAsync.asData?.value != null;
      final loggingIn = state.uri.path == '/login';

      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      // Auth & Dashboard
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Core Modules
      GoRoute(
        path: '/attendance',
        name: 'attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/balance-sheet',
        name: 'balanceSheet',
        builder: (context, state) => BalanceSheetScreen(),
      ),
      GoRoute(
        path: '/inventory',
        name: 'inventory',
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: '/orders',
        name: 'todayOrders',
        builder: (context, state) => const TodayOrdersScreen(),
      ),
      GoRoute(
        path: '/payments',
        name: 'todayPayments',
        builder: (context, state) => const TodayPaymentsScreen(),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit_profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/change-password',
        name: 'change_password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/general',
        name: 'general_settings',
        builder: (context, state) => const GeneralSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        name: 'privacy_settings',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/language',
        name: 'language_selection',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/settings/appearance',
        name: 'appearance_settings',
        builder: (context, state) => const AppearanceSettingsScreen(),
      ),

      // Support
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/support/faq',
        name: 'help_faq',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/support/feedback',
        name: 'feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/support/contact',
        name: 'contact_us',
        builder: (context, state) => const ContactSupportScreen(),
      ),

      // Legal
      GoRoute(
        path: '/legal',
        name: 'legal',
        builder: (context, state) => const LegalScreen(),
      ),
      GoRoute(
        path: '/legal/about',
        name: 'app_info',
        builder: (context, state) => const AppInfoScreen(),
      ),
      GoRoute(
        path: '/legal/privacy-policy',
        name: 'privacy_policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/legal/terms-of-service',
        name: 'terms_of_service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),

      // Admin only
      GoRoute(
        path: '/users',
        name: 'manage_users',
        redirect: (context, state) {
          final currentUser = ref.read(currentUserStreamProvider).value;
          if (currentUser?.role.name != AppConstants.roleAdmin) {
            return '/profile';
          }
          return null;
        },
        builder: (context, state) => const ManageUsersScreen(),
      ),
    ],
  );
});
