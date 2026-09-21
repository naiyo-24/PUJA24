import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../core/theme/app_colors.dart';
import '../features/pandals/presentation/puja_map_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Fixes the Flutter Android bug where PopScope stops working after backgrounding
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.charcoal : AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app, color: AppColors.pujaRed),
            const SizedBox(width: 8),
            Text(
              'Exit App',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.pureWhite : AppColors.deepMaroon,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to exit PUJO24?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.ivory : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'No',
              style: TextStyle(
                color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pujaRed,
              foregroundColor: AppColors.pureWhite,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, Exit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (widget.navigationShell.currentIndex != 0) {
          widget.navigationShell.goBranch(0);
        } else {
          final shouldExit = await _showExitDialog(context);
          if (shouldExit ?? false) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        extendBody: true,
        body: widget.navigationShell,
        bottomNavigationBar: ref.watch(mapNavigatingProvider) ? const SizedBox.shrink() : CurvedNavigationBar(
          index: widget.navigationShell.currentIndex,
          height: 75.0,
          items: const <Widget>[
            Icon(Icons.explore_outlined, size: 30, color: Colors.white),
            Icon(Icons.temple_hindu_outlined, size: 30, color: Colors.white),
            Icon(Icons.map_outlined, size: 30, color: Colors.white),
            Icon(Icons.favorite_outline, size: 30, color: Colors.white),
            Icon(Icons.groups_outlined, size: 30, color: Colors.white),
            Icon(Icons.person_outline, size: 30, color: Colors.white),
          ],
          color: AppColors.pujaRed,
          buttonBackgroundColor: AppColors.saffron,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 300),
          onTap: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          letIndexChange: (index) => true,
        ),
      ),
    );
  }
}
