import 'package:flutter/material.dart';
import '../../../../data/services/smart_bazar_api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_context.dart';
import 'smart_bazar_dashboard_screen.dart';
import 'smart_bazar_login_page.dart';

class SmartBazarRegistrationPage extends StatefulWidget {
  const SmartBazarRegistrationPage({super.key});

  @override
  State<SmartBazarRegistrationPage> createState() =>
      _SmartBazarRegistrationPageState();
}

class _SmartBazarRegistrationPageState
    extends State<SmartBazarRegistrationPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = SmartBazarApiService();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  SmartBazarRole _selectedRole = SmartBazarRole.customer;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              bn: 'à¦…à¦¨à§à¦—à§à¦°à¦¹ à¦•à¦°à§‡ à¦¨à¦¾à¦®, à¦«à§‹à¦¨ à¦¨à¦®à§à¦¬à¦° à¦à¦¬à¦‚ à¦ªà¦¾à¦¸à¦“à§Ÿà¦¾à¦°à§à¦¡ à¦ªà§‚à¦°à¦£ à¦•à¦°à§à¦¨à¥¤',
              en: 'Please fill name, phone number, and password.',
            ),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              bn: 'à¦ªà¦¾à¦¸à¦“à¦¯à¦¼à¦¾à¦°à§à¦¡ à¦¦à§à¦Ÿà¦¿ à¦®à§‡à¦²à§‡à¦¨à¦¿!',
              en: 'Passwords do not match!',
            ),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = await _apiService.register(
        fullName: name,
        phoneNumber: phone,
        password: password,
        confirmPassword: confirmPassword,
        role: _roleApiValue(_selectedRole),
        email: _emailController.text.trim(),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              bn: 'à¦¸à§à¦®à¦¾à¦°à§à¦Ÿ à¦¬à¦¾à¦œà¦¾à¦°à§‡ à¦¸à¦«à¦²à¦­à¦¾à¦¬à§‡ à¦…à§à¦¯à¦¾à¦•à¦¾à¦‰à¦¨à§à¦Ÿ à¦¤à§ˆà¦°à¦¿ à¦¹à§Ÿà§‡à¦›à§‡!',
              en: 'Registered to Smart Bazar successfully!',
            ),
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => SmartBazarDashboardScreen(
            initialRole: _selectedRole,
            userId: auth.userId,
            fullName: auth.fullName,
            phoneNumber: auth.phoneNumber,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // Header
              Text(
                context.tr(
                  bn: 'à¦¸à§à¦®à¦¾à¦°à§à¦Ÿ à¦¬à¦¾à¦œà¦¾à¦° à¦¨à¦¿à¦¬à¦¨à§à¦§à¦¨',
                  en: 'Smart Bazar Registration',
                ),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  bn: 'à¦†à¦ªà¦¨à¦¾à¦° à¦…à§à¦¯à¦¾à¦•à¦¾à¦‰à¦¨à§à¦Ÿ à¦¤à§ˆà¦°à¦¿ à¦•à¦°à§‡ à¦•à§‡à¦¨à¦¾à¦•à¦¾à¦Ÿà¦¾ à¦¶à§à¦°à§ à¦•à¦°à§à¦¨',
                  en: 'Create your account to start shopping',
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 30),

              // Role Selector
              Text(
                context.tr(
                  bn: 'à¦†à¦ªà¦¨à¦¾à¦° à¦…à§à¦¯à¦¾à¦ªà§‡à¦° à¦§à¦°à¦¨',
                  en: 'App Role Type',
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildRoleSelectorTab(
                        role: SmartBazarRole.customer,
                        label: context.tr(
                          bn: 'à¦—à§à¦°à¦¾à¦¹à¦•',
                          en: 'Customer',
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildRoleSelectorTab(
                        role: SmartBazarRole.shopkeeper,
                        label: context.tr(
                          bn: 'à¦¦à§‹à¦•à¦¾à¦¨à¦¦à¦¾à¦°',
                          en: 'Shopkeeper',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Full Name field
              Text(
                context.tr(bn: 'à¦†à¦ªà¦¨à¦¾à¦° à¦¨à¦¾à¦®', en: 'Full Name'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  hintText: context.tr(
                    bn: 'à¦†à¦ªà¦¨à¦¾à¦° à¦ªà§à¦°à§‹ à¦¨à¦¾à¦® à¦²à¦¿à¦–à§à¦¨',
                    en: 'Enter your full name',
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFFEC4899),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFEC4899),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Phone Number field
              Text(
                context.tr(bn: 'à¦«à§‹à¦¨ à¦¨à¦®à§à¦¬à¦°', en: 'Phone Number'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: context.tr(
                    bn: 'à¦†à¦ªà¦¨à¦¾à¦° à¦«à§‹à¦¨ à¦¨à¦®à§à¦¬à¦° à¦²à¦¿à¦–à§à¦¨',
                    en: 'Enter your phone number',
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_android_rounded,
                    color: Color(0xFFEC4899),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFEC4899),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Email field (Optional)
              Text(
                context.tr(
                  bn: 'à¦‡à¦®à§‡à¦‡à¦² (à¦à¦šà§à¦›à¦¿à¦•)',
                  en: 'Email (Optional)',
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: context.tr(
                    bn: 'à¦†à¦ªà¦¨à¦¾à¦° à¦‡à¦®à§‡à¦‡à¦² à¦à¦¡à§à¦°à§‡à¦¸ à¦²à¦¿à¦–à§à¦¨',
                    en: 'Enter your email address',
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFFEC4899),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFEC4899),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Password field
              Text(
                context.tr(bn: 'à¦ªà¦¾à¦¸à¦“à§Ÿà¦¾à¦°à§à¦¡', en: 'Password'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: context.tr(
                    bn: 'à¦ªà¦¾à¦¸à¦“à§Ÿà¦¾à¦°à§à¦¡ à¦¸à§‡à¦Ÿ à¦•à¦°à§à¦¨',
                    en: 'Set a password',
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFFEC4899),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFEC4899),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Confirm Password field
              Text(
                context.tr(
                  bn: 'à¦ªà¦¾à¦¸à¦“à§Ÿà¦¾à¦°à§à¦¡ à¦¨à¦¿à¦¶à§à¦šà¦¿à¦¤ à¦•à¦°à§à¦¨',
                  en: 'Confirm Password',
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: context.tr(
                    bn: 'à¦ªà¦¾à¦¸à¦“à§Ÿà¦¾à¦°à§à¦¡à¦Ÿà¦¿ à¦†à¦¬à¦¾à¦° à¦²à¦¿à¦–à§à¦¨',
                    en: 'Re-enter your password',
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFFEC4899),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFEC4899),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Register Button
              FilledButton(
                onPressed: _isSubmitting ? null : _register,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        context.tr(bn: 'à¦¨à¦¿à¦¬à¦¨à§à¦§à¦¨', en: 'Register'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Switch to Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr(
                      bn: 'à¦‡à¦¤à¦¿à¦®à¦§à§à¦¯à§‡ à¦…à§à¦¯à¦¾à¦•à¦¾à¦‰à¦¨à§à¦Ÿ à¦†à¦›à§‡?',
                      en: "Already have an account?",
                    ),
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const SmartBazarLoginPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEC4899),
                    ),
                    child: Text(
                      context.tr(bn: 'à¦²à¦—à¦‡à¦¨ à¦•à¦°à§à¦¨', en: 'Log In'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectorTab({
    required SmartBazarRole role,
    required String label,
  }) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEC4899) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  static String _roleApiValue(SmartBazarRole role) {
    return switch (role) {
      SmartBazarRole.customer => 'customer',
      SmartBazarRole.shopkeeper => 'shopkeeper',
      SmartBazarRole.fieldOfficer => 'fieldOfficer',
    };
  }
}
