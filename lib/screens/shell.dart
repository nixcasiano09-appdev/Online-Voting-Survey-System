import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/services/app_repository.dart';
import '../core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  String get _title {
    if (location == '/home') return 'HOME';
    if (location == '/notifications') return 'NOTIFICATIONS';
    if (location == '/profile') return 'PROFILE';
    if (location == '/admin') return 'ADMIN';
    if (location.startsWith('/election')) return 'ELECTIONS';
    if (location.startsWith('/survey')) return 'SURVEYS';
    if (location == '/results') return 'RESULTS';
    if (location == '/my-votes') return 'MY VOTES';
    if (location == '/history') return 'HISTORY';
    if (location.startsWith('/help')) return 'GET HELP';
    return 'SCHOOL ONLINE VOTING';
  }

  int get _selectedIndex {
    if (location == '/notifications') return 0;
    if (location == '/profile') return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_title),
      leading: location == '/home'
          ? Builder(
              builder: (context) => IconButton(
                tooltip: 'Open menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
            )
          : IconButton(
              tooltip: 'Back',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    ),
    drawer: _NavigationDrawer(),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: child,
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/notifications');
          case 1:
            context.go('/home');
          case 2:
            context.go('/profile');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.notifications_none_rounded),
          selectedIcon: Icon(Icons.notifications_rounded),
          label: 'Alerts',
        ),
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    ),
  );
}

class _NavigationDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AppRepository>();
    final student = repository.student;
    return NavigationDrawer(
      selectedIndex: null,
      onDestinationSelected: (index) {
        Navigator.pop(context);
        final routes = <String>[
          '/profile',
          '/my-votes',
          '/history',
          '/help',
          '/results',
          if (student.role == 'admin') '/admin',
        ];
        if (index < routes.length) context.go(routes[index]);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 30, 18, 20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 27,
                backgroundColor: AppTheme.paleBlue,
                child: Icon(Icons.person, color: AppTheme.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Student ID: ${student.studentId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(indent: 18, endIndent: 18),
        const NavigationDrawerDestination(
          icon: Icon(Icons.account_circle_outlined),
          label: Text('My Profile'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.how_to_vote_outlined),
          label: Text('My Votes'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.history_rounded),
          label: Text('History'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.help_outline_rounded),
          label: Text('Get Help'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.bar_chart_rounded),
          label: Text('Results'),
        ),
        if (student.role == 'admin')
          const NavigationDrawerDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            label: Text('Admin Console'),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Divider(),
        ),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: AppTheme.navy),
          title: const Text('Logout'),
          onTap: () async {
            Navigator.pop(context);
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Log out?'),
                content: const Text('Are you sure you want to log out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('NO'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('YES'),
                  ),
                ],
              ),
            );
            if (shouldLogout == true && context.mounted) {
              await context.read<AppRepository>().signOut();
              if (context.mounted) context.go('/');
            }
          },
        ),
      ],
    );
  }
}
