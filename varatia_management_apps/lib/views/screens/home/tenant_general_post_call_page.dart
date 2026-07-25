import 'package:flutter/material.dart';
import 'package:varatia_management_apps/core/utils/app_context.dart';
import 'package:varatia_management_apps/data/services/admin_chat_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TenantGeneralPostCallPage extends StatefulWidget {
  const TenantGeneralPostCallPage({
    super.key,
    this.displayName,
    this.phoneNumber,
  });

  final String? displayName;
  final String? phoneNumber;

  @override
  State<TenantGeneralPostCallPage> createState() =>
      _TenantGeneralPostCallPageState();
}

class _TenantGeneralPostCallPageState extends State<TenantGeneralPostCallPage> {
  final AdminChatApiService _adminChatApiService = AdminChatApiService();
  String? _displayName;
  String? _phoneNumber;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCall());
  }

  Future<void> _startCall() async {
    try {
      var displayName = widget.displayName?.trim();
      var phoneNumber = widget.phoneNumber?.trim();

      if (phoneNumber == null || phoneNumber.isEmpty) {
        final admin = await _adminChatApiService.getDefaultAdmin();
        displayName = admin.fullName;
        phoneNumber = admin.phoneNumber;
      }

      if (phoneNumber.trim().isEmpty) {
        throw Exception('Admin phone number was not found.');
      }

      if (mounted) {
        setState(() {
          _displayName = displayName?.isNotEmpty == true
              ? displayName
              : 'Admin';
          _phoneNumber = phoneNumber;
        });
      }

      final uri = Uri(scheme: 'tel', path: phoneNumber);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Could not open phone dialer.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _displayName ?? context.tr(bn: 'অ্যাডমিন', en: 'Admin'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _errorMessage ??
                          (_phoneNumber ??
                              context.tr(bn: 'কলিং...', en: 'Calling...')),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CallButton(
                    icon: Icons.mic_off,
                    backgroundColor: Colors.white24,
                    onTap: () {},
                  ),
                  const SizedBox(width: 32),
                  _CallButton(
                    icon: Icons.call_end,
                    backgroundColor: Colors.red,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 32),
                  _CallButton(
                    icon: Icons.volume_up,
                    backgroundColor: Colors.white24,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 32,
        backgroundColor: backgroundColor,
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
