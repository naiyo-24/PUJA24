import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/profile_creation_screen.dart';
import '../features/auth/presentation/map_picker_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/pandals/presentation/puja_detail_screen.dart';
import '../features/pandals/presentation/puja_directory_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/privacy_policy_screen.dart';
import '../features/profile/presentation/terms_of_service_screen.dart';
import '../shell/app_shell.dart';
import '../core/theme/app_colors.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        name: RouteNames.login,
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: RouteNames.otp,
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpScreen(
            phone: extra['phone'] as String? ?? 'Unknown',
          );
        },
      ),
      GoRoute(
        name: RouteNames.createProfile,
        path: '/create_profile',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ProfileCreationScreen(
            loginMethod: extra['loginMethod'] as String? ?? 'phone',
            prefilledPhone: extra['phone'] as String?,
            prefilledName: extra['name'] as String?,
            prefilledPhotoUrl: extra['photoUrl'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/map_picker',
        builder: (context, state) => const MapPickerScreen(),
      ),
      GoRoute(
        name: RouteNames.pujaDetail,
        path: '/puja_detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'unknown';
          return PujaDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.explore,
                path: '/explore',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/puja',
                builder: (context, state) => PopScope(
                  canPop: false,
                  onPopInvoked: (didPop) {
                    if (didPop) return;
                    context.go('/explore');
                  },
                  child: const PujaDirectoryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan',
                builder: (context, state) => PopScope(
                  canPop: false,
                  onPopInvoked: (didPop) {
                    if (didPop) return;
                    context.go('/explore');
                  },
                  child: const Scaffold(body: Center(child: Text('Planner'))),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.saved,
                path: '/saved',
                builder: (context, state) => PopScope(
                  canPop: false,
                  onPopInvoked: (didPop) {
                    if (didPop) return;
                    context.go('/explore');
                  },
                  child: const Scaffold(body: Center(child: Text('Saved Places'))),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.profile,
                path: '/profile',
                builder: (context, state) => PopScope(
                  canPop: false,
                  onPopInvoked: (didPop) {
                    if (didPop) return;
                    context.go('/explore');
                  },
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      // Add other routes here as we build them out
    ],
  );
});
