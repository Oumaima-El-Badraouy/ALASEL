import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/artisan_detail_screen.dart';
import '../presentation/screens/artisan_home_screen.dart';
import '../presentation/screens/explore_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/request_screen.dart';
import '../presentation/screens/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/explore',
      builder: (context, state) => const ExploreScreen(),
    ),
    GoRoute(
      path: '/artisan',
      builder: (context, state) => const ArtisanHomeScreen(),
    ),
    GoRoute(
      path: '/request',
      builder: (context, state) => const RequestScreen(),
    ),
    GoRoute(
      path: '/artisan/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ArtisanDetailScreen(artisanId: id);
      },
    ),
  ],
);
