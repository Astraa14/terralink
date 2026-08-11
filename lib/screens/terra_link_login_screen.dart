import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/redesign/glass_card.dart';

class TerraLinkLoginScreen extends StatefulWidget {
  final AuthService authService;

  const TerraLinkLoginScreen({super.key, required this.authService});

  @override
  State<TerraLinkLoginScreen> createState() => _TerraLinkLoginScreenState();
}

class _TerraLinkLoginScreenState extends State<TerraLinkLoginScreen>
    with SingleTickerProviderStateMixin {
  AuthService get _auth => widget.authService;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 24),
                    const Text(
                      'TerraLink',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Intelligent terrarium monitoring.',
                      style: TextStyle(color: AppColors.mutedForeground, fontSize: 15),
                    ),
                    const SizedBox(height: 32),
                    if (_isSignUp) ...[
                      _buildField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Jane Doe',
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'hello@example.com',
                      keyboard: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: '••••••••',
                      obscure: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.mutedForeground,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: AppColors.primary, fontSize: 14),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.primaryForeground,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppColors.radiusSm),
                          ),
                        ),
                        onPressed: _auth.isLoading ? null : _handleEmailAuth,
                        child: _auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'Create Account' : 'Sign In',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Or continue with',
                            style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _SocialButton(label: 'Google', onTap: _handleGoogle)),
                        const SizedBox(width: 16),
                        Expanded(child: _SocialButton(label: 'Guest', onTap: _handleGuest)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text.rich(
                        TextSpan(
                          text: _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                          style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                          children: [
                            TextSpan(
                              text: _isSignUp ? 'Sign In' : 'Sign Up',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Image.asset('assets/terralink.png', fit: BoxFit.contain),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GlassSurface(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            style: const TextStyle(color: AppColors.foreground),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter your email and password.');
      return;
    }

    final success = _isSignUp
        ? await _auth.signUpWithEmail(email, password, _nameController.text.trim())
        : await _auth.signInWithEmail(email, password);

    if (!mounted) return;
    if (!success) {
      _snack(_auth.lastError ?? 'Authentication failed.');
    } else if (_isSignUp) {
      _snack('Account created successfully!');
    }
  }

  Future<void> _handleGoogle() async {
    final success = await _auth.signInWithGoogle();
    if (!mounted) return;
    if (!success) _snack(_auth.lastError ?? 'Google Sign-In failed.');
  }

  Future<void> _handleGuest() async {
    await _auth.signInAsGuest();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SocialButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12),
        gradient: false,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
