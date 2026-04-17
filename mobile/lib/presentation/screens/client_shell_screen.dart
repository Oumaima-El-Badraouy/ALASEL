import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/l10n/strings.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (prefs.getBool('welcome_snack_v3') ?? false) return;
      await prefs.setBool('welcome_snack_v3', true);
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
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: S.navHome),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: S.navFavorites,
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: S.navProfile),
        ],
      ),
    );
  }
}
