import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/models/user_mode.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/rescuer_auth_screen.dart';
import 'features/auth/victim_auth_screen.dart';
import 'features/onboarding/mode_selection_screen.dart';
import 'features/rescuer/ar/rescuer_ar_screen.dart';
import 'features/rescuer/dashboard/rescuer_dashboard_screen.dart';
import 'features/rescuer/home/rescuer_home_screen.dart';
import 'features/rescuer/triage/triage_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/victim/chat/chat_screen.dart';
import 'features/victim/checkin/checkin_screen.dart';
import 'features/victim/donation/donation_screen.dart';
import 'features/victim/health/health_card_screen.dart';
import 'features/victim/home/victim_home_screen.dart';
import 'features/victim/map/assembly_map_screen.dart';
import 'features/victim/sos/sos_active_screen.dart';

/// Açılışta Supabase oturumu varsa kullanıcıyı doğrudan rolüne uygun ana
/// ekrana atar; yoksa onboarding'i gösterir. Böylece bir kez giriş yapan
/// kullanıcı bir daha auth ekranını görmez.
String _initialLocation() {
  try {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return '/onboarding';
    final role = session.user.userMetadata?['role'] as String?;
    return role == 'rescuer' ? '/rescuer' : '/victim';
  } catch (_) {
    return '/onboarding';
  }
}

final _router = GoRouter(
  initialLocation: _initialLocation(),
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => ModeSelectionScreen(
        onModeSelected: (mode) {
          if (mode == UserMode.victim) {
            context.go('/auth/victim');
          } else {
            context.go('/auth/rescuer');
          }
        },
      ),
    ),
    GoRoute(
      path: '/auth/victim',
      builder: (context, state) => const VictimAuthScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/auth/rescuer',
      builder: (context, state) => const RescuerAuthScreen(),
    ),
    GoRoute(
      path: '/victim',
      builder: (context, state) => const VictimHomeScreen(),
      routes: [
        GoRoute(
          path: 'sos',
          builder: (context, state) => const SosActiveScreen(),
        ),
        GoRoute(
          path: 'chat',
          builder: (context, state) => ChatScreen(),
        ),
        GoRoute(
          path: 'health',
          builder: (context, state) => const HealthCardScreen(),
        ),
        GoRoute(
          path: 'map',
          builder: (context, state) => const AssemblyMapScreen(),
        ),
        GoRoute(
          path: 'checkin',
          builder: (context, state) => const CheckinScreen(),
        ),
        GoRoute(
          path: 'donation',
          builder: (context, state) => const DonationScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/rescuer',
      builder: (context, state) => const RescuerDashboardScreen(),
      routes: [
        GoRoute(
          path: 'scan',
          builder: (context, state) => const RescuerHomeScreen(),
        ),
        GoRoute(
          path: 'ar',
          builder: (context, state) => const RescuerArScreen(),
        ),
        GoRoute(
          path: 'triage',
          builder: (context, state) => const TriageScreen(),
        ),
      ],
    ),
  ],
);

class YanindaApp extends ConsumerWidget {
  const YanindaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Yanındayım',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
