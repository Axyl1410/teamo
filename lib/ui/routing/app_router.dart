import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zola/ui/features/admin/views/screens/admin_screen.dart';
import 'package:zola/ui/features/admin/views/screens/admin_users_screen.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';
import 'package:zola/ui/features/auth/views/auth_required_view.dart';
import 'package:zola/ui/features/auth/views/banned_view.dart';
import 'package:zola/ui/features/auth/views/login_view.dart';
import 'package:zola/ui/features/contacts/views/screens/contacts_screen.dart';
import 'package:zola/ui/features/contacts/views/screens/full_screen_page.dart';
import 'package:zola/ui/features/discover/views/screens/discover_screen.dart';
import 'package:zola/ui/features/home/views/home_view.dart';
import 'package:zola/ui/features/messages/views/screens/messages_screen.dart';
import 'package:zola/ui/features/personal/views/screens/personal_screen.dart';
import 'package:zola/ui/features/settings/views/screens/settings_screen.dart';
import 'package:zola/ui/features/wall/views/screens/wall_screen.dart';
import 'package:zola/ui/routing/app_routes.dart';
import 'package:zola/ui/routing/auth_loading_view.dart';
import 'package:zola/ui/routing/auth_status_listenable.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  bool isAuthRoute(String location) {
    return AppRoute.authOnly.contains(location);
  }

  bool isHomeRoute(String location) {
    return location.startsWith('/home/');
  }

  bool isProtectedRoute(String location) {
    return isHomeRoute(location) ||
        location.startsWith(AppRoute.admin) ||
        location == AppRoute.settings;
  }

  int tabIndexForLocation(String location) {
    if (location.startsWith(AppRoute.homeContacts)) {
      return 1;
    }
    if (location.startsWith(AppRoute.homeDiscover)) {
      return 2;
    }
    if (location.startsWith(AppRoute.homeWall)) {
      return 3;
    }
    if (location.startsWith(AppRoute.homePersonal)) {
      return 4;
    }
    return 0;
  }

  String tabRouteForIndex(int index) {
    switch (index) {
      case 0:
        return AppRoute.homeMessages;
      case 1:
        return AppRoute.homeContacts;
      case 2:
        return AppRoute.homeDiscover;
      case 3:
        return AppRoute.homeWall;
      case 4:
        return AppRoute.homePersonal;
      default:
        return AppRoute.homeMessages;
    }
  }

  final rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'rootNavigator',
  );
  final listenable = AuthStatusListenable(ref);

  String? redirect(BuildContext context, GoRouterState state) {
    final status = ref.read(authStatusNotifierProvider);
    final loc = state.matchedLocation;
    final inAuthRoute = isAuthRoute(loc);
    final inProtectedRoute = isProtectedRoute(loc);

    final target = switch (status) {
      AuthStatus.checking => loc == AppRoute.loading ? null : AppRoute.loading,
      AuthStatus.unauthenticated =>
        loc == AppRoute.login
            ? null
            : (inProtectedRoute || inAuthRoute ? AppRoute.login : null),
      AuthStatus.banned => loc == AppRoute.banned ? null : AppRoute.banned,
      AuthStatus.sessionRecoveryRequired =>
        loc == AppRoute.authRequired ? null : AppRoute.authRequired,
      AuthStatus.authenticated => inAuthRoute ? AppRoute.homeMessages : null,
    };
    if (kDebugMode && target != null && target != loc) {
      debugPrint('Router redirect: status=$status from=$loc to=$target');
    }
    return target;
  }

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.root,
    refreshListenable: listenable,
    redirect: redirect,
    routes: <RouteBase>[
      GoRoute(path: AppRoute.root, redirect: (_, _) => AppRoute.homeMessages),
      GoRoute(
        path: AppRoute.loading,
        builder: (_, _) => const AuthLoadingView(),
      ),
      GoRoute(path: AppRoute.login, builder: (_, _) => const LoginView()),
      GoRoute(path: AppRoute.banned, builder: (_, _) => const BannedView()),
      GoRoute(
        path: AppRoute.authRequired,
        builder: (_, _) => const AuthRequiredView(),
      ),
      ShellRoute(
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state, child) => HomeView(
          currentIndex: tabIndexForLocation(state.matchedLocation),
          onTabSelected: (index) => context.go(tabRouteForIndex(index)),
          child: child,
        ),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoute.homeMessages,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: MessagesScreen()),
          ),
          GoRoute(
            path: AppRoute.homeContacts,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: ContactsScreen()),
            routes: <RouteBase>[
              GoRoute(
                path: 'full',
                parentNavigatorKey: rootNavigatorKey,
                builder: (_, _) => const FullScreenPage(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.homeDiscover,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: DiscoverScreen()),
          ),
          GoRoute(
            path: AppRoute.homeWall,
            pageBuilder: (_, _) => const NoTransitionPage(child: WallScreen()),
          ),
          GoRoute(
            path: AppRoute.homePersonal,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: PersonalScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.admin,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const AdminScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'users',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const AdminUsersScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.settings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
