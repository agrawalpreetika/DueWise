import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/dashboard/dashboard_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/dashboard/calendar_screen.dart';
import 'features/analytics/payment_history_screen.dart';
import 'features/subscriptions/subscription_provider.dart';
import 'features/auth/auth_provider.dart';
import 'services/notification_service.dart'; // Notification service import added

import 'theme/theme_toggle_button.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(subscriptionProvider.notifier).refreshFromCloud();
    });
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AnalyticsScreen(),
    const CalendarScreen(),
    const PaymentHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        // Consistent brand title & logo across all tabs
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: Colors.deepPurple,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'DueWise',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        centerTitle: false,
        actions: const [
          ThemeToggleButton(), // Theme toggle switch added in AppBar
          SizedBox(width: 8),
        ],
      ),
      // Consistent Hamburger Drawer across all tabs to view user info/sign out
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                user?.displayName ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (user?.displayName?.isNotEmpty ?? false)
                      ? user!.displayName![0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              decoration: BoxDecoration(color: Colors.deepPurple.shade700),
            ),

            // --- TEST NOTIFICATION OPTION ---
            ListTile(
              leading: const Icon(
                Icons.notifications_active,
                color: Colors.deepPurple,
              ),
              title: const Text('Test Notification'),
              subtitle: const Text('Check instant local notification'),
              onTap: () async {
                Navigator.of(context).pop(); // Close drawer first
                await NotificationService().showTestNotification();
              },
            ),

            // --- CHECK PENDING NOTIFICATIONS OPTION ADDED HERE ---
            ListTile(
              leading: const Icon(
                Icons.list_alt_rounded,
                color: Colors.blueAccent,
              ),
              title: const Text('Check Scheduled Reminders'),
              subtitle: const Text('Print pending alerts to console'),
              onTap: () async {
                Navigator.of(context).pop(); // Close drawer first
                await NotificationService().printPendingNotifications();

                // Show a quick snackbar confirmation on screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Check your terminal/debug console for pending notifications!',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            // ----------------------------------------------------

            const Divider(), // Divider before sign out

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(authRepositoryProvider).signOut();
              },
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.cardColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.unselectedWidgetColor,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
