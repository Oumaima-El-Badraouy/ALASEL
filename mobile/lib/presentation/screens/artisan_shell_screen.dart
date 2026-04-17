import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/l10n/strings.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (prefs.getBool('welcome_artisan_snack_v1') ?? false) return;
      await prefs.setBool('welcome_artisan_snack_v1', true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.welcomeSnack), behavior: SnackBarBehavior.floating),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
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
          NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: S.navDemands),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: S.navDiscover),
          NavigationDestination(icon: Icon(Icons.post_add_outlined), selectedIcon: Icon(Icons.post_add), label: S.navMyPosts),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: S.navProfile),
        ],
      ),
    );
  }
}
