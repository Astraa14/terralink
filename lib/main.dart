import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/terra_link_login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  } else {
    debugPrint(
      'Supabase not configured — paste your URL and key in '
      'lib/config/supabase_config.dart',
    );
  }

  runApp(const TerraLinkApp());
}

class TerraLinkApp extends StatefulWidget {
  const TerraLinkApp({super.key});

  @override
  State<TerraLinkApp> createState() => _TerraLinkAppState();
}

class _TerraLinkAppState extends State<TerraLinkApp> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authService.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TerraLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _authService.isAuthenticated
          ? DashboardScreen(authService: _authService)
          : TerraLinkLoginScreen(authService: _authService),
    );
  }
}
