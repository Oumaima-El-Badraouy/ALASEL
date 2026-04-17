import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/shell_messages_bar.dart';
import 'artisan_demands_screen.dart';
import 'artisan_discover_screen.dart';
import 'artisan_my_posts_screen.dart';
import 'artisan_profile_tab_screen.dart';

class ArtisanShellScreen extends ConsumerStatefulWidget {
  const ArtisanShellScreen({super.key});

  @override
  ConsumerState<ArtisanShellScreen> createState() => _ArtisanShellScreenState();
}

class _ArtisanShellScreenState extends ConsumerState<ArtisanShellScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ShellMessagesBar(),
          Expanded(
            child: IndexedStack(
              index: tab,
              children: const [
                ArtisanDemandsScreen(),
                ArtisanDiscoverScreen(),
                ArtisanMyPostsScreen(),
                ArtisanProfileTabScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'Demandes'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Découvrir'),
          NavigationDestination(icon: Icon(Icons.post_add_outlined), selectedIcon: Icon(Icons.post_add), label: 'Mes posts'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
        indicatorColor: AppColors.gold.withValues(alpha: 0.35),
      ),
    );
  }
}
