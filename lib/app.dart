import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terralink/core/theme.dart';
import 'package:terralink/services/auth_service.dart';
import 'package:terralink/screens/auth/login_screen.dart';
import 'package:terralink/screens/auth/register_screen.dart';
import 'package:terralink/screens/dashboard/dashboard_screen.dart';

class TerraLinkApp extends StatelessWidget {
  const TerraLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TerraLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    if (authService.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.mainAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'TerraLink',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainAccent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (authService.currentUser != null) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
