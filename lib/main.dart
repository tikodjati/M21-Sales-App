import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/store_provider.dart';
import 'providers/visit_provider.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/home/admin_home_screen.dart';
import 'ui/screens/home/sales_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => StoreProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => VisitProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => OrderProvider(apiClient)),
      ],
      child: const M21SalesApp(),
    ),
  );
}

class M21SalesApp extends StatefulWidget {
  const M21SalesApp({super.key});

  @override
  State<M21SalesApp> createState() => _M21SalesAppState();
}

class _M21SalesAppState extends State<M21SalesApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M21 Sales App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (auth.isAuthenticated) {
            if (auth.currentUser?.isAdmin == true) {
              return const AdminHomeScreen();
            }
            return const SalesHomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
