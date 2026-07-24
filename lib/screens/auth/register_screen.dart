import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terralink/core/theme.dart';
import 'package:terralink/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRegistering = false;
  bool _isGoogleSigningIn = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

    final authService = context.read<AuthService>();
    final user = await authService.signUpWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isRegistering = false);

    if (user != null) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else if (authService.errorMessage != null) {
      _showErrorSnackbar(authService.errorMessage!);
      authService.clearError();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleSigningIn = true);

    final authService = context.read<AuthService>();
    final user = await authService.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isGoogleSigningIn = false);

    if (user != null) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else if (authService.errorMessage != null) {
      _showErrorSnackbar(authService.errorMessage!);
      authService.clearError();
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight,
          ),
          child: Column(
            children: [
              // ──────────── Header with gradient ────────────
              _buildHeader(context),

              // ──────────── Form Card ────────────
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Transform.translate(
                    offset: const Offset(0, -32),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildFormCard(),
                          const SizedBox(height: 20),
                          _buildGoogleSignInButton(),
                          const SizedBox(height: 28),
                          _buildSignInLink(),
                          SizedBox(height: bottomInset > 0 ? 16 : 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 28,
        bottom: 52,
        left: 28,
        right: 28,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and decorative icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.local_florist,
                    color: Colors.white.withValues(alpha: 0.1),
                    size: 36,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.eco,
                    color: Colors.white.withValues(alpha: 0.07),
                    size: 28,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // App icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.8,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Join TerraLink and start monitoring',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 0.3,
              fontWeight: FontWeight.w400,
            ),
          ),

          // Decorative divider
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 36,
                height: 2.5,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 2.5,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fill in the details below to get started',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // Name field
            _buildInputLabel('Full Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: _validateName,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_emailFocusNode);
              },
              decoration: const InputDecoration(
                hintText: 'John Doe',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.person_outline_rounded, size: 20),
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // Email field
            _buildInputLabel('Email'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              validator: _validateEmail,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.mail_outline_rounded, size: 20),
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // Password field
            _buildInputLabel('Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: _validatePassword,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
              },
              decoration: InputDecoration(
                hintText: 'Minimum 6 characters',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.lock_outline_rounded, size: 20),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    splashRadius: 20,
                  ),
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password field
            _buildInputLabel('Confirm Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              validator: _validateConfirmPassword,
              onFieldSubmitted: (_) => _handleRegister(),
              decoration: InputDecoration(
                hintText: 'Re-enter your password',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.lock_outline_rounded, size: 20),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                    splashRadius: 20,
                  ),
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),

            // Register Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isRegistering ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.mainAccent.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isRegistering
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),

            // Terms text
            const SizedBox(height: 14),
            Center(
              child: Text(
                'By creating an account, you agree to our\nTerms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Column(
      children: [
        // Divider with "or"
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or sign up with',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        const SizedBox(height: 20),

        // Google button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isGoogleSigningIn ? null : _handleGoogleSignIn,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isGoogleSigningIn
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textDark.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/login');
          },
          child: const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        letterSpacing: 0.3,
      ),
    );
  }
}
