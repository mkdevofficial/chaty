import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/chat/presentation/screens/conversations_screen.dart';
import '../features/friends/presentation/friends_list_screen.dart';
import '../features/friends/presentation/search_users_screen.dart';
import '../features/profile/presentation/my_profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/stories/presentation/create_story_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return null;
      }

      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchUsersScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsListScreen(),
      ),
      GoRoute(
        path: '/profile/me',
        builder: (context, state) => const MyProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/story/create',
        builder: (context, state) => const CreateStoryScreen(),
      ),
    ],
  );
});
