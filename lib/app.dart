import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/models/user_mode.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/rescuer_auth_screen.dart';
import 'features/auth/victim_auth_screen.dart';
import 'features/onboarding/mode_selection_screen.dart';
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
          builder: (context, state) => const _PlaceholderScreen(
            title: 'AI Sohbet',
            subtitle: 'Offline asistan — Serhat tarafından',
          ),
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
      builder: (context, state) => const _PlaceholderScreen(
        title: 'Kurtarıcı Modu',
        subtitle: 'Tarama haritası yapım aşamasında...',
      ),
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

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/onboarding'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction_rounded,
                size: 64,
                color: Color(0xFF5B6661),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
