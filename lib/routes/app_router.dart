import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/profile_creation_screen.dart';
import '../features/auth/presentation/map_picker_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/pandals/presentation/puja_detail_screen.dart';
import '../features/pandals/presentation/puja_directory_screen.dart';
import '../features/pandals/presentation/puja_map_screen.dart';
import '../features/food/presentation/cafe_directory_screen.dart';
import '../features/home/presentation/puja_pass_details_screen.dart';
import '../features/home/presentation/pass_purchase_form_screen.dart';
import '../features/home/presentation/payment_success_screen.dart';
import '../features/profile/presentation/my_passes_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/privacy_policy_screen.dart';
import '../features/profile/presentation/terms_of_service_screen.dart';
import '../features/profile/presentation/about_us_screen.dart';
import '../features/food/presentation/restaurant_detail_screen.dart';
import '../features/food/domain/models/restaurant_model.dart';
import '../features/planner/presentation/planner_screen.dart';
import '../features/saved/presentation/saved_screen.dart';
import '../features/transport/presentation/metro_guide_screen.dart';
import '../features/transport/presentation/metro_live_map_screen.dart';
import '../features/transport/presentation/parking_map_screen.dart';
import '../features/groups/presentation/groups_dashboard_screen.dart';
import '../features/groups/presentation/create_group_screen.dart';
import '../features/groups/presentation/join_group_screen.dart';
import '../features/groups/presentation/group_details_screen.dart';
import '../features/groups/presentation/group_info_screen.dart';
import '../features/groups/presentation/group_live_map_screen.dart';
import '../shell/app_shell.dart';
import '../core/theme/app_colors.dart';
import '../features/advertisement/presentation/advertisement_details_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
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
          return const ProfileCreationScreen();
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
      GoRoute(
        path: '/about-us',
        builder: (context, state) => const AboutUsScreen(),
      ),
      GoRoute(
        path: '/restaurant_detail/:id',
        builder: (context, state) {
          final restaurant = state.extra as RestaurantModel;
          return RestaurantDetailScreen(restaurant: restaurant);
        },
      ),
      GoRoute(
        path: '/puja-pass',
        builder: (context, state) => const PujaPassDetailsScreen(),
      ),
      GoRoute(
        path: '/pass-purchase',
        builder: (context, state) {
          final packageId = state.extra as String? ?? '';
          return PassPurchaseFormScreen(packageId: packageId);
        },
      ),
      GoRoute(
        path: '/payment-success',
        builder: (context, state) {
          final paymentId = state.extra as String? ?? 'TXN_SUCCESS';
          return PaymentSuccessScreen(paymentId: paymentId);
        },
      ),
      GoRoute(
        path: '/my-passes',
        builder: (context, state) => const MyPassesScreen(),
      ),
      GoRoute(
        path: '/cafe',
        builder: (context, state) => const CafeDirectoryScreen(),
      ),
      GoRoute(
        path: '/plan',
        builder: (context, state) => const PlannerScreen(),
      ),
      GoRoute(
        path: '/metro',
        builder: (context, state) => const MetroGuideScreen(),
      ),
      GoRoute(
        path: '/metro-map',
        builder: (context, state) => const MetroLiveMapScreen(),
      ),
      GoRoute(
        path: '/parking',
        builder: (context, state) => const ParkingMapScreen(),
      ),
      GoRoute(
        path: '/groups/create',
        name: 'createGroup',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/groups/join',
        name: 'joinGroup',
        builder: (context, state) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: '/groups/details/:id',
        name: 'groupDetails',
        builder: (context, state) => GroupDetailsScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/groups/info/:id',
        name: 'groupInfo',
        builder: (context, state) => GroupInfoScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/join-group/:link',
        name: 'joinGroupWithLink',
        builder: (context, state) {
          final link = state.pathParameters['link'] ?? '';
          return JoinGroupScreen(inviteLink: link);
        },
      ),
      GoRoute(
        path: '/advertisement',
        name: 'advertisement',
        builder: (context, state) => const AdvertisementDetailsScreen(),
      ),
      GoRoute(
        path: '/groups/live-map/:id',
        name: 'groupLiveMap',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'unknown';
          return GroupLiveMapScreen(groupId: id);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                name: RouteNames.explore,
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
                path: '/map',
                builder: (context, state) => PopScope(
                  canPop: false,
                  onPopInvoked: (didPop) {
                    if (didPop) return;
                    context.go('/explore');
                  },
                  child: const PujaMapScreen(),
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
                  child: const SavedScreen(),
                ),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'groups',
                path: '/groups',
                builder: (context, state) => PopScope(
                  canPop: false,
                  onPopInvoked: (didPop) {
                    if (didPop) return;
                    context.go('/explore');
                  },
                  child: const GroupsDashboardScreen(),
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
