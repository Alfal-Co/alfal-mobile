import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_provider.dart';
import '../features/auth/view/login_screen.dart';
import '../features/dashboard/view/dashboard_screen.dart';
import '../features/customers/view/customers_screen.dart';
import '../features/sales/view/sales_screen.dart';
import '../features/payments/view/payments_screen.dart';
import '../features/ai_assistant/view/ai_chat_screen.dart';
import '../features/procurement/view/procurement_screen.dart';
import '../features/hr/view/my_profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SalesScreen(),
          ),
          GoRoute(
            path: '/procurement',
            builder: (context, state) => const ProcurementScreen(),
          ),
          GoRoute(
            path: '/hr',
            builder: (context, state) => const MyProfileScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentsScreen(),
          ),
          // Customers accessible via navigation from Sales screen
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/ai',
            builder: (context, state) => const AiChatScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Main shell with bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getIndex(GoRouterState.of(context).matchedLocation),
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'المبيعات'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'المشتريات'),
          NavigationDestination(icon: Icon(Icons.badge), label: 'الموظفين'),
          NavigationDestination(icon: Icon(Icons.payments), label: 'التحصيل'),
        ],
      ),
    );
  }

  int _getIndex(String location) {
    if (location.startsWith('/sales')) return 1;
    if (location.startsWith('/procurement')) return 2;
    if (location.startsWith('/hr')) return 3;
    if (location.startsWith('/payments')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/dashboard');
      case 1: context.go('/sales');
      case 2: context.go('/procurement');
      case 3: context.go('/hr');
      case 4: context.go('/payments');
    }
  }
}
