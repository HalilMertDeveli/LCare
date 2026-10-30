import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/service_requests/presentation/create_request_screen.dart';
import '../../features/service_requests/presentation/request_detail_screen.dart';
import '../../features/service_requests/presentation/request_list_screen.dart';
import '../../features/shell/no_access_screen.dart';
import '../../features/shell/profile_screen.dart';
import '../../features/shell/shell_scaffold.dart';
import '../../features/shell/technician_jobs_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const noAccess = '/no-access';

  static const customer = '/customer';
  static const customerRequests = '/customer/requests';
  static const customerNewRequest = '/customer/requests/new';
  static const customerProfile = '/customer/profile';

  static const admin = '/admin';
  static const adminRequests = '/admin/requests';
  static const adminProfile = '/admin/profile';

  static const technician = '/technician';
  static const technicianJobs = '/technician/jobs';
  static const technicianProfile = '/technician/profile';

  static String homeFor(AppShell shell) => switch (shell) {
        AppShell.admin => adminRequests,
        AppShell.customer => customerRequests,
        AppShell.technician => technicianJobs,
        AppShell.none => noAccess,
      };

  static String areaFor(AppShell shell) => switch (shell) {
        AppShell.admin => admin,
        AppShell.customer => customer,
        AppShell.technician => technician,
        AppShell.none => noAccess,
      };
}

/// Pure guard: where should [location] go for [auth]? `null` = stay.
String? authRedirect(AuthState auth, String location) {
  switch (auth) {
    case AuthRestoring() || AuthRestoreFailed():
      return location == Routes.splash ? null : Routes.splash;
    case AuthSignedOut():
      return location == Routes.login ? null : Routes.login;
    case AuthSignedIn(:final me):
      final area = Routes.areaFor(me.shell);
      if (location == area || location.startsWith('$area/')) return null;
      return Routes.homeFor(me.shell);
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.listen<AuthState>(authControllerProvider, (_, next) => auth.value = next);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: auth,
    redirect: (context, state) => authRedirect(auth.value, state.uri.path),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.noAccess, builder: (_, _) => const NoAccessScreen()),
      GoRoute(path: Routes.customer, redirect: (_, _) => Routes.customerRequests),
      GoRoute(path: Routes.admin, redirect: (_, _) => Routes.adminRequests),
      GoRoute(path: Routes.technician, redirect: (_, _) => Routes.technicianJobs),

      // Customer shell
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScaffold(
          shell: shell,
          kind: ShellKind.customer,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.customerRequests,
              builder: (_, _) => const RequestListScreen(
                mode: RequestListMode.customer,
                basePath: Routes.customerRequests,
              ),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, _) => const CreateRequestScreen(),
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, state) => RequestDetailScreen(
                    id: state.pathParameters['id']!,
                    staffView: false,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.customerProfile,
              builder: (_, _) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // Staff (admin) shell
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScaffold(
          shell: shell,
          kind: ShellKind.admin,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.adminRequests,
              builder: (_, _) => const RequestListScreen(
                mode: RequestListMode.staff,
                basePath: Routes.adminRequests,
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, state) => RequestDetailScreen(
                    id: state.pathParameters['id']!,
                    staffView: true,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.adminProfile,
              builder: (_, _) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // Technician shell (no assignments in Phase 0)
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScaffold(
          shell: shell,
          kind: ShellKind.technician,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.technicianJobs,
              builder: (_, _) => const TechnicianJobsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.technicianProfile,
              builder: (_, _) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    auth.dispose();
    router.dispose();
  });
  return router;
});
