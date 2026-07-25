import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

const _profileGreen = Color(0xFF079455);
const _profileBorder = Color(0xFFE5EAF2);
const _profileDark = Color(0xFF101828);

class AmarElakaProfilePage extends StatefulWidget {
  const AmarElakaProfilePage({
    super.key,
    required this.wardName,
    required this.location,
  });

  final String wardName;
  final String location;

  @override
  State<AmarElakaProfilePage> createState() => _AmarElakaProfilePageState();
}

class _AmarElakaProfilePageState extends State<AmarElakaProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _aboutController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'রফিকুল ইসলাম');
    _mobileController = TextEditingController(text: '017XXXXXXXX');
    _emailController = TextEditingController(text: 'rafikul@email.com');
    _aboutController = TextEditingController(
      text: 'আমি আমার এলাকার জন্য কাজ করতে চাই।',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'ফিরুন',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'এডিট প্রোফাইল',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'সংরক্ষণ',
              style: TextStyle(
                color: _profileGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          children: [
            const Center(child: _ProfilePhotoPicker()),
            const SizedBox(height: 28),
            _ProfileTextField(
              label: 'নাম',
              controller: _nameController,
              textInputAction: TextInputAction.next,
            ),
            _ProfileTextField(
              label: 'মোবাইল নম্বর',
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            _ProfileTextField(
              label: 'ইমেইল',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            _SelectionRow(
              label: 'ওয়ার্ড',
              value: widget.wardName.isEmpty ? 'ওয়ার্ড-০৭' : widget.wardName,
              onTap: () => _showMessage('ওয়ার্ড নির্বাচন'),
            ),
            _SelectionRow(
              label: 'ব্লক',
              value: 'ব্লক-A',
              onTap: () => _showMessage('ব্লক নির্বাচন'),
            ),
            _LocationRow(
              label: 'লোকেশন (অটো সেট)',
              value: widget.location.isEmpty ? 'উত্তরা, ঢাকা' : widget.location,
              onTap: () => _showMessage('লোকেশন আপডেট'),
            ),
            _ProfileTextField(
              label: 'নিজ সম্পর্কে',
              controller: _aboutController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('প্রোফাইল সংরক্ষণ হয়েছে')));
    Navigator.of(context).maybePop();
  }

  void _showMessage(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title চালু হচ্ছে')));
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 104,
          width: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: AppShadows.card,
            gradient: const LinearGradient(
              colors: [Color(0xFFEFFAF3), Color(0xFFBFE7D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: _profileGreen,
            size: 62,
          ),
        ),
        Positioned(
          right: 1,
          bottom: 8,
          child: Material(
            color: _profileDark,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ছবি আপলোড চালু হচ্ছে')),
                );
              },
              child: const SizedBox(
                height: 30,
                width: 30,
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return _ProfileFieldShell(
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLines: maxLines,
        cursorColor: _profileGreen,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: _profileDark,
        ),
        decoration: const InputDecoration(
          isDense: true,
          filled: false,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _SelectionRow extends StatelessWidget {
  const _SelectionRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ProfileFieldShell(
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _profileDark,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF98A2B3),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ProfileFieldShell(
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _profileGreen,
                ),
              ),
            ),
            const Icon(Icons.location_on_rounded, color: _profileGreen),
          ],
        ),
      ),
    );
  }
}

class _ProfileFieldShell extends StatelessWidget {
  const _ProfileFieldShell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 9),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _profileBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _profileDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
