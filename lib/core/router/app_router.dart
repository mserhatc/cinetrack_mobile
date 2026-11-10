import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/create_post/screens/create_post_screen.dart';
import '../../features/explore/cubit/explore_cubit.dart';
import '../../features/explore/screens/explore_screen.dart';
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
    initialLocation: '/explore',
    routes: [
      // Stateful Nested Shell Route (Bottom Navigation Bar)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          // Sekme 1: Feed (Akış)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          // Sekme 2: Explore (Movie Explorer - Dribbble Kart Görünümü)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => BlocProvider<ExploreCubit>(
                  create: (_) => ExploreCubit(),
                  child: const ExploreScreen(),
                ),
              ),
            ],
          ),
          // Sekme 3: You (Profil)
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

      // Yeni Paylaşım / Post Oluşturma (Modal / Ayrı Ekran)
      GoRoute(
        path: '/new-post',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatePostScreen(),
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

      // Parametrik Film / Dizi Detayı: /media/:type/:id (Dribbble "American Beauty" ekranı)
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

      // Parametrik İzlenenler / İzleme Listesi Sayfası
      GoRoute(
        path: '/watched-list/:type/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'movies';
          final userId = int.tryParse(state.pathParameters['userId'] ?? '0') ?? 0;
          return WatchedListScreen(type: type, userId: userId);
        },
      ),
    ],
  );
}
