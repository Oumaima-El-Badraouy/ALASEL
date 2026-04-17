import 'package:go_router/go_router.dart';

import '../presentation/screens/artisan_detail_screen.dart';
import '../presentation/screens/artisan_shell_screen.dart';
import '../presentation/screens/auth_login_screen.dart';
import '../presentation/screens/auth_register_artisan_screen.dart';
import '../presentation/screens/auth_register_client_screen.dart';
import '../presentation/screens/chat_screen.dart';
import '../presentation/screens/client_shell_screen.dart';
import '../presentation/screens/inbox_screen.dart';
import '../presentation/screens/create_post_screen.dart';
import '../presentation/screens/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/auth/login', builder: (context, state) => const AuthLoginScreen()),
    GoRoute(path: '/auth/register/client', builder: (context, state) => const AuthRegisterClientScreen()),
    GoRoute(path: '/auth/register/artisan', builder: (context, state) => const AuthRegisterArtisanScreen()),
    GoRoute(path: '/client', builder: (context, state) => const ClientShellScreen()),
    GoRoute(path: '/artisan', builder: (context, state) => const ArtisanShellScreen()),
    GoRoute(path: '/inbox', builder: (context, state) => const InboxScreen()),
    GoRoute(
      path: '/create-post',
      builder: (context, state) {
        final t = state.uri.queryParameters['type'] ?? 'client_request';
        return CreatePostScreen(postType: t);
      },
    ),
    GoRoute(
      path: '/chat/:peerId',
      builder: (context, state) {
        final peerId = state.pathParameters['peerId']!;
        // Déjà décodé par Uri.queryParameters — ne pas rappeler decodeComponent
        // (ex. « 20% » dans le titre provoquerait « Illegal percent encoding »).
        final name = state.uri.queryParameters['name'] ?? 'Chat';
        return ChatScreen(peerId: peerId, peerName: name);
      },
    ),
    GoRoute(
      path: '/legacy/artisan/:id',
      builder: (context, state) => ArtisanDetailScreen(artisanId: state.pathParameters['id']!),
    ),
  ],
);
