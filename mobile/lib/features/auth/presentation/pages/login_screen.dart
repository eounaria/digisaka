import 'package:flutter/material.dart';
import 'package:digisaka/core/constant/app_assets.dart';
import 'package:digisaka/core/data/seed_user.dart';
import 'package:digisaka/core/theme/app_colors.dart';
import 'package:digisaka/shared/components/app_button.dart';
import 'package:digisaka/features/shell/presentation/pages/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Key used to run the validators of the form.
  final _formKey = GlobalKey<FormState>();

  // Controllers let us read what the user typed.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true; // password hidden by default
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    // Always free controllers to avoid memory leaks.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Runs when the LOGIN button is tapped.
  Future<void> _handleLogin() async {
    // Stop here if the inputs are empty or invalid.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Check the typed email/mobile + password against the seed users.
    final UserModel? user = authenticate(
      _emailController.text,
      _passwordController.text,
    );

    if (user == null) {
      _showMessage('Incorrect email/mobile number or password');
      return;
    }

    // Only reaches here when the login is correct.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset keeps the layout from breaking
      // when the keyboard opens.
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildSkyBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildLoginCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sky photo that only covers the upper part of the screen.
  Widget _buildSkyBackground() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      decoration: const BoxDecoration(
        // Fallback color in case the image is not found.
        color: AppColors.primaryGreen,
        image: DecorationImage(
          image: AssetImage(AppAssets.skyBackground),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Logo, "Digisaka" title, and the "My QR" pill button.
  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppAssets.logo,
          height: 110,
          // If the logo file is missing, show an icon instead of a red error box.
          errorBuilder: (_, __, ___) => const Icon(
            Icons.location_on,
            size: 100,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Bogart AI',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 14),
        Material(
          color: AppColors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            onTap: () => _showMessage('My QR tapped'),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.white.withOpacity(0.6)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_2, color: AppColors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'My QR',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The white rounded container holding the form.
  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      // Minimum height so the white area reaches the bottom of the screen.
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.62,
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmailField(),
            const SizedBox(height: 18),
            _buildPasswordField(),
            const SizedBox(height: 26),

            AppButton(
              label: 'LOGIN',
              onPressed: _handleLogin,
              isLoading: _isLoading,
              backgroundColor: AppColors.accentYellow,
              textColor: AppColors.primaryGreen,
            ),
            const SizedBox(height: 18),

            _buildRememberMeRow(),
            const SizedBox(height: 40),

            _buildLegalLinks(),
            const SizedBox(height: 24),

            AppButton(
              label: 'NO ACCOUNT YET? SIGN UP',
              onPressed: () => _showMessage('Go to Sign Up screen'),
              backgroundColor: AppColors.primaryGreen,
              textColor: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }

  /// "Email or Mobile Number" input.
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(fontSize: 16, color: AppColors.textDark),
      decoration: const InputDecoration(
        hintText: 'Email or Mobile Number',
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 16, right: 12),
          child: Icon(Icons.email, color: AppColors.primaryGreen, size: 26),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter your email or mobile number';
        }
        return null;
      },
    );
  }

  /// "Password" input with the show/hide eye icon.
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: 16, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 12),
          child: Icon(Icons.lock, color: AppColors.primaryGreen, size: 26),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.primaryGreen,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  /// "Remember me" checkbox on the left, "Forgot Access?" on the right.
  Widget _buildRememberMeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) =>
                    setState(() => _rememberMe = value ?? false),
                activeColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.textDark, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Remember me',
              style: TextStyle(fontSize: 15, color: AppColors.textDark),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => _showMessage('Forgot Access tapped'),
          child: const Text(
            'Forgot Access?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
        ),
      ],
    );
  }

  /// Privacy Policy and Terms links.
  Widget _buildLegalLinks() {
    const linkStyle = TextStyle(
      color: AppColors.primaryGreen,
      fontSize: 15,
      decoration: TextDecoration.underline,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _showMessage('Privacy Policy'),
          child: const Text('Privacy Policy', style: linkStyle),
        ),
        const Text('  and  ',
            style: TextStyle(fontSize: 15, color: AppColors.textGrey)),
        GestureDetector(
          onTap: () => _showMessage('Terms and Conditions'),
          child: const Text('Terms and Conditions', style: linkStyle),
        ),
      ],
    );
  }
}