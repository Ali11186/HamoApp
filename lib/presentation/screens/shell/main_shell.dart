import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/nova_assistant_fab.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  bool _notificationStreamReady = false;

  final _routes = [
    RouteConstants.home,
    RouteConstants.search,
    RouteConstants.notifications,
    RouteConstants.profile,
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(unreadNotificationCountProvider, (previous, next) {
      if (_notificationStreamReady && next > (previous ?? 0)) {
        // A short native click keeps the notification subtle and premium.
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.lightImpact();
      }
      _notificationStreamReady = true;
    });
    // .valueOrNull-style access: if the stream errors (e.g. permission-denied)
    // we simply show no badge instead of crashing the whole shell.
    final unreadCount = ref.watch(totalUnreadCountProvider).maybeWhen(
          data: (v) => v,
          orElse: () => 0,
        );

    return Scaffold(
      body: widget.child,
      floatingActionButton:
          _currentIndex == 0 ? null : const NovaAssistantFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.dividerBorder.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_rounded),
              label: 'بحث',
            ),
            BottomNavigationBarItem(
              icon: badges.Badge(
                showBadge: unreadCount > 0,
                badgeContent: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: AppColors.notificationYellow,
                  padding: EdgeInsets.all(4),
                ),
                child: const Icon(Icons.notifications_outlined),
              ),
              activeIcon: const Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'الملف الشخصي',
            ),
          ],
        ),
      ),
    );
  }
}
