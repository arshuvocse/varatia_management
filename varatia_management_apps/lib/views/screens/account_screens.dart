import 'package:flutter/material.dart';

import '../../core/utils/app_context.dart';
import '../../data/services/account_api_service.dart';
import '../widgets/app_widgets.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final AccountApiService _accountApiService = AccountApiService();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _userId;
  String? _role;
  String? _firebaseDeviceToken;
  String? _imei;
  bool _isPhoneVerified = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _accountApiService.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _accountApiService.getProfile();
      if (!mounted) {
        return;
      }

      _fullNameController.text = profile.fullName;
      _phoneController.text = profile.phoneNumber;
      setState(() {
        _userId = profile.userId;
        _role = profile.role;
        _firebaseDeviceToken = profile.firebaseDeviceToken;
        _imei = profile.imei;
        _isPhoneVerified = profile.isPhoneVerified;
        _isLoading = false;
      });
    } on AccountApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_fullNameController.text.trim().length < 3 ||
        _phoneController.text.trim().length < 10) {
      _showMessage('Enter a valid name and phone number.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _accountApiService.updateProfile(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);
      Navigator.of(context).pop();
    } on AccountApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr(bn: 'Profile', en: 'Profile')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr(bn: 'Profile', en: 'Profile')),
        ),
        body: ListView(
          padding: screenPadding,
          children: [
            SectionCard(
              title: context.tr(bn: 'Unable to Load', en: 'Unable to Load'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadProfile,
                    child: Text(context.tr(bn: 'Retry', en: 'Retry')),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final roleLabel = (_role == null || _role!.trim().isEmpty) ? '-' : _role!;
    final userIdLabel = (_userId == null || _userId!.trim().isEmpty)
        ? '-'
        : _userId!;
    final firebaseTokenLabel =
        (_firebaseDeviceToken == null || _firebaseDeviceToken!.trim().isEmpty)
        ? '-'
        : _firebaseDeviceToken!;
    final imeiLabel = (_imei == null || _imei!.trim().isEmpty) ? '-' : _imei!;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'Profile', en: 'Profile')),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          SectionCard(
            title: context.tr(bn: 'Account Status', en: 'Account Status'),
            child: Column(
              children: [
                InfoLine(
                  label: context.tr(bn: 'Role', en: 'Role'),
                  value: roleLabel,
                ),
                InfoLine(
                  label: context.tr(bn: 'User Id', en: 'User Id'),
                  value: userIdLabel,
                ),
                InfoLine(
                  label: context.tr(bn: 'Phone Verified', en: 'Phone Verified'),
                  value: _isPhoneVerified ? 'Yes' : 'No',
                ),
                InfoLine(
                  label: context.tr(
                    bn: 'Firebase Device Token',
                    en: 'Firebase Device Token',
                  ),
                  value: firebaseTokenLabel,
                ),
                InfoLine(
                  label: context.tr(bn: 'IMEI', en: 'IMEI'),
                  value: imeiLabel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          EntryTextField(
            controller: _fullNameController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Full Name', en: 'Full Name'),
            hint: context.tr(bn: 'Enter full name', en: 'Enter full name'),
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _phoneController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Phone Number', en: 'Phone Number'),
            hint: context.tr(
              bn: 'Enter mobile number',
              en: 'Enter mobile number',
            ),
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(context.tr(bn: 'Save Profile', en: 'Save Profile')),
          ),
        ],
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AccountApiService _accountApiService = AccountApiService();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _accountApiService.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.length < 6 ||
        _confirmPasswordController.text.isEmpty) {
      _showMessage('Enter valid password details.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _accountApiService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);
      Navigator.of(context).pop();
    } on AccountApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(bn: 'Change Password', en: 'Change Password')),
      ),
      body: ListView(
        padding: screenPadding,
        children: [
          EntryTextField(
            controller: _currentPasswordController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Current Password', en: 'Current Password'),
            hint: context.tr(
              bn: 'Enter current password',
              en: 'Enter current password',
            ),
            icon: Icons.lock_outline_rounded,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _newPasswordController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'New Password', en: 'New Password'),
            hint: context.tr(
              bn: 'Enter new password',
              en: 'Enter new password',
            ),
            icon: Icons.password_rounded,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          EntryTextField(
            controller: _confirmPasswordController,
            enabled: !_isSubmitting,
            label: context.tr(bn: 'Confirm Password', en: 'Confirm Password'),
            hint: context.tr(
              bn: 'Confirm new password',
              en: 'Confirm new password',
            ),
            icon: Icons.verified_user_outlined,
            obscureText: true,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(
              context.tr(bn: 'Update Password', en: 'Update Password'),
            ),
          ),
        ],
      ),
    );
  }
}
