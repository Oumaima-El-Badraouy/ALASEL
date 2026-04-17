import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/responsive_content.dart';
import '../widgets/shell_messages_bar.dart';
import 'client_favorites_screen.dart';
import 'client_feed_screen.dart';
import 'client_profile_screen.dart';

class ClientShellScreen extends ConsumerStatefulWidget {
  const ClientShellScreen({super.key});

  @override
  ConsumerState<ClientShellScreen> createState() => _ClientShellScreenState();
}

class _ClientShellScreenState extends ConsumerState<ClientShellScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ShellMessagesBar(),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: ResponsiveContent(
                child: IndexedStack(
                  index: tab,
                  children: const [
                    ClientFeedScreen(),
                    ClientFavoritesScreen(),
                    ClientProfileScreen(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Favoris',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
        indicatorColor: AppColors.gold.withValues(alpha: 0.35),
      ),
    );
  }
}
