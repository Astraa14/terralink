import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class TerraLinkLoginScreen extends StatefulWidget {
  final AuthService authService;

  const TerraLinkLoginScreen({super.key, required this.authService});

  @override
  State<TerraLinkLoginScreen> createState() => _TerraLinkLoginScreenState();
}

class _TerraLinkLoginScreenState extends State<TerraLinkLoginScreen>
    with SingleTickerProviderStateMixin {
  AuthService get _authService => widget.authService;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  LoginMethod _selectedMethod = LoginMethod.guest;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Palette
  // ─────────────────────────────────────────────
  static const _bg        = Color(0xFF0D1610);
  static const _surface   = Color(0xFF182419);
  static const _card      = Color(0xFF1E2E21);
  static const _green     = Color(0xFF4CAF50);
  static const _textLight = Colors.white;
  static const _textSub   = Color(0xFFAAAA9F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: LayoutBuilder(
            builder: (ctx, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      _buildLogo(),
                      const SizedBox(height: 28),
                      _buildHeading(),
                      const SizedBox(height: 40),
                      _buildMethodSelector(),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            SizeTransition(sizeFactor: anim, child: child),
                        child: _selectedMethod == LoginMethod.email
                            ? _buildEmailFields()
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 28),
                      _buildLoginButton(),
                      const Spacer(flex: 3),
                      _buildFooter(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Logo – display the PNG as-is (no colour tint)
  // ─────────────────────────────────────────────
  Widget _buildLogo() {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _card,
        border: Border.all(color: _green.withValues(alpha: 0.6), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.3),
            blurRadius: 48,
            spreadRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Image.asset(
        'assets/terralink.png',
        fit: BoxFit.contain,
        // No `color:` parameter — show the real image colours
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Heading
  // ─────────────────────────────────────────────
  Widget _buildHeading() {
    return Column(
      children: [
        const Text(
          'TerraLink',
          style: TextStyle(
            color: _textLight,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Smart Terrarium Monitor',
          style: TextStyle(
            color: _textSub,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Method selector – segmented chip style
  // ─────────────────────────────────────────────
  Widget _buildMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _methodChip(LoginMethod.google, Icons.g_mobiledata_rounded, 'Google'),
          _methodChip(LoginMethod.email,  Icons.mail_outline_rounded,  'Email'),
          _methodChip(LoginMethod.guest,  Icons.person_outline_rounded, 'Guest'),
        ],
      ),
    );
  }

  Widget _methodChip(LoginMethod method, IconData icon, String label) {
    final selected = _selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? _green : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [BoxShadow(color: _green.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 3))]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? Colors.white : _textSub, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _textSub,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Email / Password fields
  // ─────────────────────────────────────────────
  Widget _buildEmailFields() {
    return Column(
      key: const ValueKey('emailFields'),
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          inputType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: !_isPasswordVisible,
          suffix: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: _textSub,
              size: 20,
            ),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text('Forgot password?', style: TextStyle(color: _green.withValues(alpha: 0.85), fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType inputType = TextInputType.text,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      style: const TextStyle(color: _textLight, fontSize: 15),
      cursorColor: _green,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textSub, fontSize: 14),
        filled: true,
        fillColor: _surface,
        prefixIcon: Icon(icon, color: _textSub, size: 20),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Login button
  // ─────────────────────────────────────────────
  Widget _buildLoginButton() {
    final label = switch (_selectedMethod) {
      LoginMethod.google => 'Continue with Google',
      LoginMethod.email  => 'Sign In',
      LoginMethod.guest  => 'Enter as Guest',
    };

    final icon = switch (_selectedMethod) {
      LoginMethod.google => Icons.g_mobiledata_rounded,
      LoginMethod.email  => Icons.login_rounded,
      LoginMethod.guest  => Icons.explore_outlined,
    };

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ).copyWith(
          overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.12)),
        ),
        onPressed: _authService.isLoading ? null : () => _handleLogin(context),
        icon: _authService.isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Icon(icon, size: 22),
        label: _authService.isLoading
            ? const Text('Please wait…', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Footer
  // ─────────────────────────────────────────────
  Widget _buildFooter() {
    return Text(
      '© 2025 TerraLink · Smart Ecosystem Control',
      style: TextStyle(color: _textSub.withValues(alpha: 0.6), fontSize: 11),
    );
  }

  // ─────────────────────────────────────────────
  // Auth handler
  // ─────────────────────────────────────────────
  Future<void> _handleLogin(BuildContext context) async {
    switch (_selectedMethod) {
      case LoginMethod.google:
        await _authService.signInWithGoogle();
      case LoginMethod.email:
        if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
          _showSnack(context, 'Please enter your email and password.');
          return;
        }
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      case LoginMethod.guest:
        await _authService.signInAsGuest();
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

enum LoginMethod { google, email, guest }
