import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/models/user_mode.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/rescuer_auth_screen.dart';
import 'features/auth/victim_auth_screen.dart';
import 'features/onboarding/mode_selection_screen.dart';
import 'features/rescuer/home/rescuer_home_screen.dart';
import 'features/rescuer/triage/triage_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/victim/chat/chat_screen.dart';
import 'features/victim/checkin/checkin_screen.dart';
import 'features/victim/donation/donation_screen.dart';
import 'features/victim/home/victim_home_screen.dart';
import 'features/victim/map/assembly_map_screen.dart';
import 'features/victim/pfa/pfa_screen.dart';
import 'features/victim/sos/sos_active_screen.dart';

final _router = GoRouter(
  initialLocation: '/onboarding',
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
          path: 'pfa',
          builder: (context, state) => const PfaScreen(),
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
      builder: (context, state) => const RescuerHomeScreen(),
      routes: [
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
      title: 'Yanında',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
