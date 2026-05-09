import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/config/supabase_config.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final isChofer = role.isChofer;

    int selectedIndex() {
      final location = GoRouterState.of(context).matchedLocation;
      if (location.startsWith('/trips')) return 0;
      if (location.startsWith('/containers')) return 1;
      if (location.startsWith('/dashboard')) return 2;
      if (location.startsWith('/drivers')) return 3;
      if (location.startsWith('/trucks')) return 4;
      return 2;
    }

    void onDestinationSelected(int i) {
      final routes = [
        '/trips',
        '/containers',
        '/dashboard',
        '/drivers',
        '/trucks',
      ];
      context.go(routes[i]);
    }

    final navItems = [
      _NavItem(
        icon: Icons.route_outlined,
        selectedIcon: Icons.route,
        label: 'Viajes',
        index: 0,
      ),
      _NavItem(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        label: 'Contenedores',
        index: 1,
      ),
      _NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        index: 2,
      ),
      _NavItem(
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge,
        label: 'Conductores',
        index: 3,
      ),
      _NavItem(
        icon: Icons.local_shipping_outlined,
        selectedIcon: Icons.local_shipping,
        label: 'Camiones',
        index: 4,
      ),
    ];

    final current = selectedIndex();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'LogiFlow'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          ...?actions,
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) async {
              if (value == 'logout') {
                await supabase.auth.signOut();
                if (context.mounted) context.go('/login');
              } else if (value == 'profile') {
                context.push('/profile');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Mi perfil'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: child,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LogiFlow',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Gestión logística',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Facturas'),
              onTap: () {
                Navigator.pop(context);
                context.push('/invoices');
              },
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Viajes'),
              onTap: () {
                Navigator.pop(context);
                context.go('/trips');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Contenedores'),
              onTap: () {
                Navigator.pop(context);
                context.go('/containers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Conductores'),
              onTap: () {
                Navigator.pop(context);
                context.go('/drivers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Camiones'),
              onTap: () {
                Navigator.pop(context);
                context.go('/trucks');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/dashboard');
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          padding: EdgeInsets.zero,
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(navItems[0], current, onDestinationSelected),
                _buildNavItem(navItems[1], current, onDestinationSelected),
                const SizedBox(width: 48),
                _buildNavItem(navItems[3], current, onDestinationSelected),
                _buildNavItem(navItems[4], current, onDestinationSelected),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (floatingActionButton != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: floatingActionButton,
            ),
          SizedBox(
            width: 64,
            height: 64,
            child: FloatingActionButton(
              onPressed: () => onDestinationSelected(2),
              backgroundColor: theme.primaryColor,
              elevation: 8,
              child: Icon(
                current == 2 ? Icons.dashboard : Icons.dashboard_outlined,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(
    _NavItem item,
    int currentIndex,
    void Function(int) onTap,
  ) {
    final selected = currentIndex == item.index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(item.index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                color: selected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.index,
  });
}