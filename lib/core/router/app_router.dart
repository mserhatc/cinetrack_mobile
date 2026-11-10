import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/create_post/screens/create_post_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/media/screens/media_detail_screen.dart';
import '../../features/profile/cubit/profile_cubit.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/user_list_screen.dart';
import '../../features/profile/screens/watched_list_screen.dart';
import '../../features/shell/main_navigation_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/feed',
    routes: [
      // Stateful Nested Shell Route (Bottom Navigation Bar)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          // Sekme 1: Ana Sayfa (Feed)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          // Sekme 2: Yeni Paylaşım
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/new-post',
                builder: (context, state) => const CreatePostScreen(),
              ),
            ],
          ),
          // Sekme 3: Ben (Profil)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Parametrik Diğer Kullanıcı Profili
      GoRoute(
        path: '/profile/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final userId = int.tryParse(state.pathParameters['userId'] ?? '');
          return BlocProvider<ProfileCubit>(
            create: (_) => ProfileCubit()..loadProfile(userId: userId),
            child: ProfileScreen(targetUserId: userId),
          );
        },
      ),

      // Parametrik Film / Dizi Detayı: /media/:type/:id
      GoRoute(
        path: '/media/:type/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'movie';
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return MediaDetailScreen(mediaType: type, id: id);
        },
      ),

      // Parametrik Takipçi / Takip Edilenler Listesi: /user-list/:type/:userId
      GoRoute(
        path: '/user-list/:type/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'followers';
          final userId = int.tryParse(state.pathParameters['userId'] ?? '0') ?? 0;
          return UserListScreen(type: type, userId: userId);
        },
      ),

      // Parametrik İzlenenler Listesi: /watched-list/:type/:userId
      GoRoute(
        path: '/watched-list/:type/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'movie';
          final userId = int.tryParse(state.pathParameters['userId'] ?? '0') ?? 0;
          return WatchedListScreen(mediaType: type, userId: userId);
        },
      ),
    ],
  );
}

