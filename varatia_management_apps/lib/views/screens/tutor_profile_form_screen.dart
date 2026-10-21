import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_context.dart';
import '../../data/models/tutor_bdjobs_profile.dart';
import '../../data/services/tutor_profile_storage_service.dart';

class TutorProfileFormScreen extends StatefulWidget {
  const TutorProfileFormScreen({super.key});

  @override
  State<TutorProfileFormScreen> createState() => _TutorProfileFormScreenState();
}

class _TutorProfileFormScreenState extends State<TutorProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TutorProfileStorageService _storageService =
      TutorProfileStorageService();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _universityController;
  late final TextEditingController _departmentController;
  late final TextEditingController _customFeeController;

  String _gender = 'পুরুষ';
  String _city = 'Dhaka';
  String _currentLocation = '';
  String _universityType = '';
  String _sscMedium = '';
  final Set<String> _preferredLocations = <String>{};
  final Set<String> _preferredSubjects = <String>{};
  final Set<String> _classesToTeach = <String>{};
  String _expectedFee = '';
  String _daysPerWeek = '';

  bool _isLoading = true;
  bool _isSaving = false;

  // Options from TuitionHome screenshots & Dhaka datasets
  static const List<String> _universityTypes = [
    'National University',
    'Private University',
    'Public University',
    '7 College',
    'Public medical',
    'Private medical',
    'Madrasah',
    'Polytechnic Institute',
    'Other',
  ];

  static const List<String> _sscMediums = [
    'বাংলা মাধ্যম (Bangla Medium)',
    'ইংলিশ ভার্সন (English Version)',
    'ইংলিশ মিডিয়াম (English Medium)',
    'মাদ্রাসা (Madrasah)',
    'কারিগরি / ভোকেশনাল (Vocational)',
    'অন্যান্য (Other)',
  ];

  static const List<String> _cities = [
    'Dhaka',
    'Chattogram',
    'Rajshahi',
    'Sylhet',
    'Khulna',
    'Barishal',
    'Rangpur',
    'Mymensingh',
  ];

  static const List<String> _dhakaAreas = [
    'Airport Area',
    'Abdullahpur',
    'Adabor',
    'Adarsha Nagar',
    'Aftab Nagar',
    'Agargaon',
    'Agargaon Taltola',
    'Azimpur',
    'Badda',
    'Banani',
    'Banasree',
    'Baridhara',
    'Baridhara DOHS',
    'Bashundhara',
    'Cantonment',
    'Chawkbazar',
    'Dhanmondi',
    'Diabari',
    'ECB Chattar',
    'Farmgate',
    'Gendaria',
    'Gopibagh',
    'Gulshan 1',
    'Gulshan 2',
    'Hazaribagh',
    'Jatrabari',
    'Kafrul',
    'Kallyanpur',
    'Kamalapur',
    'Kamrangirchar',
    'Karwan Bazar',
    'Khilgaon',
    'Khilkhet',
    'Lalbagh',
    'Malibagh',
    'Mirpur 1',
    'Mirpur 2',
    'Mirpur 6',
    'Mirpur 10',
    'Mirpur 11',
    'Mirpur 12',
    'Mirpur 14',
    'Moghbazar',
    'Mohakhali',
    'Mohakhali DOHS',
    'Mohammadpur',
    'Motijheel',
    'New Market',
    'Niketon',
    'Nikunja 1',
    'Nikunja 2',
    'Pallabi',
    'Paltan',
    'Panthapath',
    'Ramna',
    'Rampura',
    'Rupnagar',
    'Sabujbagh',
    'Shahbagh',
    'Shah Ali',
    'Shantinagar',
    'Sherebangla Nagar',
    'Shyampur',
    'Sutrapur',
    'Tejgaon',
    'Tongi',
    'Uttara Sector 1',
    'Uttara Sector 3',
    'Uttara Sector 5',
    'Uttara Sector 7',
    'Uttara Sector 9',
    'Uttara Sector 10',
    'Uttara Sector 11',
    'Uttara Sector 13',
    'Uttara Sector 14',
    'Uttara Sector 17',
    'Wari',
  ];

  static const List<String> _popularUniversities = [
    'ঢাকা বিশ্ববিদ্যালয় (DU)',
    'বাংলাদেশ প্রকৌশল বিশ্ববিদ্যালয় (BUET)',
    'জাহাঙ্গীরনগর বিশ্ববিদ্যালয় (JU)',
    'রাজশাহী বিশ্ববিদ্যালয় (RU)',
    'চট্টগ্রাম বিশ্ববিদ্যালয় (CU)',
    'নর্থ সাউথ ইউনিভার্সিটি (NSU)',
    'ব্র্যাক ইউনিভার্সিটি (BRACU)',
    'আহছানউল্লাহ বিজ্ঞান ও প্রযুক্তি বিশ্ববিদ্যালয় (AUST)',
    'ইস্ট ওয়েস্ট ইউনিভার্সিটি (EWU)',
    'ঢাকা মেডিকেল কলেজ (DMC)',
    'ঢাকা কলেজ (৭ কলেজ)',
    'ইডেন মহিলা কলেজ (৭ কলেজ)',
    'সরকারি তিতুমীর কলেজ (৭ কলেজ)',
    'ড্যাফোডিল ইন্টারন্যাশনাল ইউনিভার্সিটি (DIU)',
    'আমেরিকান ইন্টারন্যাশনাল ইউনিভার্সিটি (AIUB)',
    'ঢাকা পলিটেকনিক ইনস্টিটিউট',
  ];

  static const List<String> _popularDepartments = [
    'কম্পিউটার সায়েন্স অ্যান্ড ইঞ্জিনিয়ারিং (CSE)',
    'ইলেকট্রিক্যাল অ্যান্ড ইলেকট্রনিক ইঞ্জিনিয়ারিং (EEE)',
    'মেকানিক্যাল ইঞ্জিনিয়ারিং (ME)',
    'সিভিল ইঞ্জিনিয়ারিং (CE)',
    'ব্যবসা প্রশাসন (BBA) / ফিন্যান্স',
    'অর্থনীতি (Economics)',
    'ইংরেজি (English)',
    'বাংলা (Bangla)',
    'গণিত (Mathematics)',
    'পদার্থবিজ্ঞান (Physics)',
    'রসায়ন (Chemistry)',
    'ফার্মেসি (Pharmacy)',
    'এমবিবিএস (MBBS)',
    'আইন (Law)',
  ];

  static const List<String> _subjectOptions = [
    'সকল বিষয়',
    'গণিত',
    'ইংরেজি',
    'বাংলা',
    'পদার্থবিজ্ঞান',
    'রসায়ন',
    'জীববিজ্ঞান',
    'উচ্চতর গণিত',
    'আইসিটি (ICT)',
    'হিসাববিজ্ঞান',
    'সাধারণ বিজ্ঞান',
    'কুরআন ও ইসলাম শিক্ষা',
  ];

  static const List<String> _classOptions = [
    'ক্লাস ১-৫',
    'ক্লাস ৬-৮',
    '৯ম-১০ম (SSC)',
    'একাদশ-দ্বাদশ (HSC)',
    'মাদ্রাসা / হিফজ',
    'বিশ্ববিদ্যালয় ভর্তি',
    'ইংলিশ মিডিয়াম',
  ];

  static const List<String> _feeOptions = [
    '৳ ৩,০০০ - ৫,০০০',
    '৳ ৫,০০০ - ৮,০০০',
    '৳ ৮,০০০ - ১২,০০০',
    '৳ ১২,০০০ - ১৫,০০০+',
    'আলোচনা সাপেক্ষে',
  ];

  static const List<String> _daysOptions = [
    '২ দিন / সপ্তাহ',
    '৩ দিন / সপ্তাহ',
    '৪ দিন / সপ্তাহ',
    '৫ দিন / সপ্তাহ',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _universityController = TextEditingController();
    _departmentController = TextEditingController();
    _customFeeController = TextEditingController();

    _nameController.addListener(_recomputeScore);
    _phoneController.addListener(_recomputeScore);
    _universityController.addListener(_recomputeScore);
    _departmentController.addListener(_recomputeScore);
    _customFeeController.addListener(_recomputeScore);

    _loadExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    _customFeeController.dispose();
    super.dispose();
  }

  void _recomputeScore() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadExistingProfile() async {
    final profile = await _storageService.loadProfile();
    if (!mounted) return;

    setState(() {
      _nameController.text = profile.fullName;
      _phoneController.text = profile.phoneNumber;
      _universityController.text = profile.universityName;
      _departmentController.text = profile.department;
      _gender = profile.gender.isNotEmpty ? profile.gender : 'পুরুষ';
      _city = profile.city.isNotEmpty ? profile.city : 'Dhaka';
      _currentLocation = profile.currentLocation;
      _universityType = profile.universityType;
      _sscMedium = profile.sscMedium;
      _preferredLocations.addAll(profile.preferredLocations);
      _preferredSubjects.addAll(profile.preferredSubjects);
      _classesToTeach.addAll(profile.classesToTeach);
      _expectedFee = profile.expectedFee;
      _daysPerWeek = profile.daysPerWeek;
      _customFeeController.text =
          _feeOptions.contains(_expectedFee) ? '' : _expectedFee;
      _isLoading = false;
    });
  }

  TutorBdjobsProfile _buildCurrentProfile() {
    final effectiveFee = _customFeeController.text.trim().isNotEmpty
        ? _customFeeController.text.trim()
        : _expectedFee;

    return TutorBdjobsProfile(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      gender: _gender,
      city: _city,
      currentLocation: _currentLocation,
      universityType: _universityType,
      universityName: _universityController.text.trim(),
      department: _departmentController.text.trim(),
      sscMedium: _sscMedium,
      preferredLocations: _preferredLocations.toList(),
      preferredSubjects: _preferredSubjects.toList(),
      classesToTeach: _classesToTeach.toList(),
      expectedFee: effectiveFee,
      daysPerWeek: _daysPerWeek,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveAndSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              bn: 'অনুগ্রহ করে আবশ্যকীয় ক্ষেত্রগুলো পূরণ করুন।',
              en: 'Please fill in all mandatory fields.',
            ),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_universityType.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              bn: 'বিশ্ববিদ্যালয়ের ধরন নির্বাচন করুন।',
              en: 'Please select your university type.',
            ),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_preferredLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              bn: 'কমপক্ষে ১টি পছন্দের টিউশন লোকেশন নির্বাচন করুন।',
              en: 'Please select at least 1 preferred tuition location.',
            ),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedProfile = _buildCurrentProfile();
      await _storageService.saveProfile(updatedProfile);

      if (!mounted) return;

      setState(() => _isSaving = false);
      _showSuccessDialog(updatedProfile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessDialog(TutorBdjobsProfile profile) {
    final score = profile.completionScore;

    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: profile.scoreGradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: profile.scoreColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    score >= 90 ? Icons.workspace_premium_rounded : Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr(
                  bn: 'আবেদন সফলভাবে সংরক্ষিত হয়েছে!',
                  en: 'Application Saved Successfully!',
                ),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  bn: 'আপনার বিডিজবস স্টাইল প্রোফাইল স্কোর: ${context.digitsText(score)}%',
                  en: 'Your BDJobs Style Profile Score: $score%',
                ),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: profile.scoreColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  bn: score >= 90
                      ? 'চমৎকার! আপনার প্রোফাইল সম্পূর্ণ প্রস্তুত। অভিভাবক ও শিক্ষার্থীরা আপনার সাথে দ্রুত যোগাযোগ করতে পারবে।'
                      : 'আপনার প্রোফাইল সংরক্ষিত হয়েছে। স্কোর আরও বাড়াতে পরবর্তীতে বাকি তথ্যগুলো যোগ করতে পারেন।',
                  en: score >= 90
                      ? 'Excellent! Your profile is complete and visible to guardians.'
                      : 'Profile saved! You can complete remaining fields later to reach 100%.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    context.tr(
                      bn: 'প্রোফাইলে ফিরে যান',
                      en: 'Back to Profile',
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Dropdown dialogs matching screenshots
  void _openUniversityTypeSelector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(
                          bn: 'বিশ্ববিদ্যালয়ের ধরন নির্বাচন করুন',
                          en: 'Select University Type',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: ListView.separated(
                  itemCount: _universityTypes.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, index) {
                    final type = _universityTypes[index];
                    final isSelected = _universityType == type;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      title: Text(
                        type,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF0D9488)
                              : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.radio_button_checked,
                              color: Color(0xFF0D9488),
                              size: 22,
                            )
                          : const Icon(
                              Icons.radio_button_off,
                              color: Color(0xFFCBD5E1),
                              size: 22,
                            ),
                      onTap: () {
                        setState(() => _universityType = type);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMediumSelector() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(
                            bn: 'এসএসসি / ও-লেভেল মাধ্যম নির্বাচন করুন',
                            en: 'Select SSC / O-Level Medium',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                ..._sscMediums.map((medium) {
                  final isSelected = _sscMedium == medium;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 2,
                    ),
                    title: Text(
                      medium,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF0D9488)
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF0D9488),
                            size: 22,
                          )
                        : null,
                    onTap: () {
                      setState(() => _sscMedium = medium);
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // Location selector matching Screenshot 4
  void _openLocationSearchSheet({
    required bool isMultiSelect,
    required String title,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final filteredAreas = _dhakaAreas.where((area) {
              if (searchQuery.trim().isEmpty) return true;
              return area.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Title & Close
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Search Box matching Screenshot 4
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        autofocus: false,
                        onChanged: (val) {
                          setSheetState(() => searchQuery = val);
                        },
                        decoration: InputDecoration(
                          hintText: context.tr(
                            bn: 'লোকেশন খুঁজুন (যেমন: Airport Area, Mirpur)...',
                            en: 'Search location (e.g. Airport Area)...',
                          ),
                          hintStyle: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setSheetState(() => searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Multi-select info note
                  if (isMultiSelect)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFFEA580C),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr(
                                bn: 'যত বেশি এলাকা নির্বাচন করবেন, তত বেশি টিউশনের প্রস্তাব পাবেন।',
                                en: 'Select multiple areas to get more tuition alerts.',
                              ),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9A3412),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // List of areas
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filteredAreas.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, index) {
                        final area = filteredAreas[index];
                        final isSelected = isMultiSelect
                            ? _preferredLocations.contains(area)
                            : _currentLocation == area;

                        return InkWell(
                          onTap: () {
                            if (isMultiSelect) {
                              setSheetState(() {
                                if (isSelected) {
                                  _preferredLocations.remove(area);
                                } else {
                                  _preferredLocations.add(area);
                                }
                              });
                              setState(() {});
                            } else {
                              setState(() => _currentLocation = area);
                              Navigator.of(ctx).pop();
                            }
                          },
                          child: Container(
                            color: isSelected
                                ? const Color(0xFFFFF7ED)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.place_rounded,
                                  size: 18,
                                  color: isSelected
                                      ? const Color(0xFFEA580C)
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    area,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFFEA580C)
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEA580C),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Multi-select Done button
                  if (isMultiSelect)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            context.tr(
                              bn: 'সম্পন্ন (${context.digitsText(_preferredLocations.length)}টি এলাকা)',
                              en: 'Done (${_preferredLocations.length} areas)',
                            ),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFieldLabel(String text, {bool isRequired = true, String? subtext}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (subtext != null)
              TextSpan(
                text: ' $subtext',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownCard({
    required String value,
    required String placeholder,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final hasValue = value.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasValue ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? value : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    color: hasValue
                        ? AppColors.textPrimary
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              if (hasValue && onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = _buildCurrentProfile();
    final score = currentProfile.completionScore;
    final scoreColor = currentProfile.scoreColor;
    final gradientColors = currentProfile.scoreGradientColors;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          context.tr(
            bn: 'টিউশন ও ক্যারিয়ার প্রোফাইল',
            en: 'Tutor Profile Setup',
          ),
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  context.tr(
                    bn: '${context.digitsText(score)}% পূর্ণ',
                    en: '$score% Done',
                  ),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  // TuitionHome Banner Header matching Screenshot 1 & 2
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.tr(
                                  bn: 'নতুন টিউশনের শুরু হোক আজই, এখান থেকেই।',
                                  en: 'Start your new tuition journey today, right here.',
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E3A8A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.tr(
                            bn: 'মাত্র ২ মিনিটে আপনার "Preferred Location" সহ অন্যান্য তথ্য দিন, ব্যস এইটুকুই!',
                            en: 'Give your "Preferred Location" and details in just 2 minutes, that\'s all!',
                          ),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // BDJobs-style live score bar inside form
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.verified_user_rounded,
                                    size: 16, color: scoreColor),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr(
                                    bn: 'বিডিজবস স্কোর: ${context.digitsText(score)}%',
                                    en: 'BDJobs Score: $score%',
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: scoreColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              context.tr(
                                bn: currentProfile.scoreLevelBn,
                                en: currentProfile.scoreLevelEn,
                              ),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 300),
                              widthFactor: currentProfile.progressRatio.clamp(0.04, 1.0),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradientColors,
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section 1: Personal Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name
                        _buildFieldLabel(
                          context.tr(bn: 'পূর্ণ নাম', en: 'Full Name'),
                        ),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: context.tr(
                              bn: 'আপনার পুরো নাম',
                              en: 'Your full name',
                            ),
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return context.tr(
                                bn: 'আপনার পুরো নাম লিখুন',
                                en: 'Please enter your full name',
                              );
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Phone Number
                        _buildFieldLabel(
                          context.tr(bn: 'ফোন নম্বর', en: 'Phone Number'),
                        ),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '01XXXXXXXXX',
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return context.tr(
                                bn: 'ফোন নম্বর লিখুন',
                                en: 'Please enter phone number',
                              );
                            }
                            if (val.trim().length < 11) {
                              return context.tr(
                                bn: 'সঠিক ১১ ডিজিটের ফোন নম্বর দিন',
                                en: 'Enter valid 11 digit phone number',
                              );
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Gender Selection matching Screenshot 2
                        _buildFieldLabel(
                          context.tr(bn: 'আপনার জেন্ডার', en: 'Your Gender'),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _gender = 'পুরুষ'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _gender == 'পুরুষ'
                                        ? const Color(0xFFEEF2FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _gender == 'পুরুষ'
                                          ? const Color(0xFF4F46E5)
                                          : const Color(0xFFE2E8F0),
                                      width: _gender == 'পুরুষ' ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      context.tr(bn: 'পুরুষ', en: 'Male'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _gender == 'পুরুষ'
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: _gender == 'পুরুষ'
                                            ? const Color(0xFF4F46E5)
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _gender = 'নারী'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _gender == 'নারী'
                                        ? const Color(0xFFFDF2F8)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _gender == 'নারী'
                                          ? const Color(0xFFDB2777)
                                          : const Color(0xFFE2E8F0),
                                      width: _gender == 'নারী' ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      context.tr(bn: 'নারী', en: 'Female'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _gender == 'নারী'
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: _gender == 'নারী'
                                            ? const Color(0xFFDB2777)
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // City Selection matching Screenshot 2
                        _buildFieldLabel(
                          context.tr(bn: 'আপনার শহর', en: 'Your City'),
                        ),
                        _buildDropdownCard(
                          value: _city,
                          placeholder: context.tr(bn: 'শহর নির্বাচন করুন', en: 'Select City'),
                          onTap: () {
                            showModalBottomSheet<void>(
                              context: context,
                              builder: (ctx) => ListView(
                                shrinkWrap: true,
                                children: _cities.map((city) {
                                  return ListTile(
                                    title: Text(city),
                                    trailing: _city == city
                                        ? const Icon(Icons.check, color: Color(0xFF0D9488))
                                        : null,
                                    onTap: () {
                                      setState(() => _city = city);
                                      Navigator.of(ctx).pop();
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        // Current Location matching Screenshot 4
                        _buildFieldLabel(
                          context.tr(bn: 'বর্তমান লোকেশন', en: 'Current Location'),
                        ),
                        _buildDropdownCard(
                          value: _currentLocation,
                          placeholder: context.tr(
                            bn: 'বর্তমান লোকেশন নির্বাচন করুন',
                            en: 'Select Current Location',
                          ),
                          onTap: () => _openLocationSearchSheet(
                            isMultiSelect: false,
                            title: context.tr(
                              bn: 'বর্তমান লোকেশন নির্বাচন করুন',
                              en: 'Select Current Location',
                            ),
                          ),
                          onClear: _currentLocation.isNotEmpty
                              ? () => setState(() => _currentLocation = '')
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section 2: University & Higher Education
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // University Type matching Screenshot 3
                        _buildFieldLabel(
                          context.tr(bn: 'বিশ্ববিদ্যালয়ের ধরন', en: 'University Type'),
                        ),
                        _buildDropdownCard(
                          value: _universityType,
                          placeholder: context.tr(
                            bn: 'ধরন নির্বাচন করুন',
                            en: 'Select Type',
                          ),
                          onTap: _openUniversityTypeSelector,
                          onClear: _universityType.isNotEmpty
                              ? () => setState(() => _universityType = '')
                              : null,
                        ),

                        const SizedBox(height: 14),

                        // University Name
                        _buildFieldLabel(
                          context.tr(bn: 'আপনার বিশ্ববিদ্যালয়', en: 'Your University'),
                        ),
                        TextFormField(
                          controller: _universityController,
                          decoration: InputDecoration(
                            hintText: context.tr(
                              bn: 'বিশ্ববিদ্যালয় নির্বাচন / লিখুন',
                              en: 'Select / type university name',
                            ),
                            prefixIcon: const Icon(Icons.account_balance_outlined, size: 20),
                            suffixIcon: _popularUniversities.isNotEmpty
                                ? PopupMenuButton<String>(
                                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                                    onSelected: (val) {
                                      _universityController.text = val;
                                      setState(() {});
                                    },
                                    itemBuilder: (ctx) => _popularUniversities
                                        .map((u) => PopupMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13))))
                                        .toList(),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Department
                        _buildFieldLabel(
                          context.tr(bn: 'আপনার ডিপার্টমেন্ট', en: 'Your Department'),
                        ),
                        TextFormField(
                          controller: _departmentController,
                          decoration: InputDecoration(
                            hintText: context.tr(
                              bn: 'ডিপার্টমেন্ট নির্বাচন / লিখুন',
                              en: 'Select / type department name',
                            ),
                            prefixIcon: const Icon(Icons.menu_book_outlined, size: 20),
                            suffixIcon: _popularDepartments.isNotEmpty
                                ? PopupMenuButton<String>(
                                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                                    onSelected: (val) {
                                      _departmentController.text = val;
                                      setState(() {});
                                    },
                                    itemBuilder: (ctx) => _popularDepartments
                                        .map((d) => PopupMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13))))
                                        .toList(),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // SSC / O-Level Medium matching Screenshot 1
                        _buildFieldLabel(
                          context.tr(bn: 'এসএসসি / ও-লেভেল মাধ্যম', en: 'SSC / O-Level Medium'),
                        ),
                        _buildDropdownCard(
                          value: _sscMedium,
                          placeholder: context.tr(
                            bn: 'মাধ্যম নির্বাচন করুন',
                            en: 'Select Medium',
                          ),
                          onTap: _openMediumSelector,
                          onClear: _sscMedium.isNotEmpty
                              ? () => setState(() => _sscMedium = '')
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section 3: Preferred Location (Multi-select) matching Screenshot 1
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(
                          context.tr(bn: 'পছন্দের লোকেশন (Preferred Location)', en: 'Preferred Location'),
                          subtext: context.tr(
                            bn: '(যত বেশি "Preferred Location" তত বেশি টিউশন।)',
                            en: '(More locations = More tuition)',
                          ),
                        ),
                        InkWell(
                          onTap: () => _openLocationSearchSheet(
                            isMultiSelect: true,
                            title: context.tr(
                              bn: 'পছন্দের টিউশন লোকেশনসমূহ',
                              en: 'Preferred Tuition Locations',
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _preferredLocations.isNotEmpty
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _preferredLocations.isEmpty
                                        ? context.tr(
                                            bn: 'পছন্দের লোকেশন সিলেক্ট করুন',
                                            en: 'Select Preferred Locations',
                                          )
                                        : context.tr(
                                            bn: '${context.digitsText(_preferredLocations.length)}টি এলাকা নির্বাচিত',
                                            en: '${_preferredLocations.length} areas selected',
                                          ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: _preferredLocations.isNotEmpty
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: _preferredLocations.isNotEmpty
                                          ? const Color(0xFFEA580C)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.add_location_alt_outlined,
                                  size: 20,
                                  color: Color(0xFFEA580C),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Selected Chips Display
                        if (_preferredLocations.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _preferredLocations.map((loc) {
                              return Chip(
                                label: Text(
                                  loc,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF9A3412),
                                  ),
                                ),
                                backgroundColor: const Color(0xFFFFF7ED),
                                side: const BorderSide(color: Color(0xFFFFEDD5)),
                                deleteIcon: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Color(0xFFEA580C),
                                ),
                                onDeleted: () {
                                  setState(() => _preferredLocations.remove(loc));
                                },
                              );
                            }).toList(),
                          ),
                        ],

                        // Quick Add Popular Areas Chips
                        const SizedBox(height: 10),
                        Text(
                          context.tr(
                            bn: 'জনপ্রিয় এলাকা থেকে দ্রুত যোগ করুন:',
                            en: 'Quick add popular areas:',
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            'Airport Area',
                            'Mirpur 10',
                            'Dhanmondi',
                            'Uttara Sector 7',
                            'Gulshan 2',
                            'Mohammadpur',
                          ].map((quickArea) {
                            final isAdded = _preferredLocations.contains(quickArea);
                            return ActionChip(
                              label: Text(
                                quickArea,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isAdded
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF475569),
                                ),
                              ),
                              avatar: isAdded
                                  ? const Icon(Icons.check, size: 14, color: Color(0xFF059669))
                                  : const Icon(Icons.add, size: 14, color: Color(0xFF64748B)),
                              backgroundColor: isAdded
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF1F5F9),
                              side: BorderSide(
                                color: isAdded
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFE2E8F0),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isAdded) {
                                    _preferredLocations.remove(quickArea);
                                  } else {
                                    _preferredLocations.add(quickArea);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section 4: Tuition Preferences
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(
                          context.tr(bn: 'পড়ানোর বিষয়সমূহ', en: 'Preferred Subjects'),
                          isRequired: false,
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _subjectOptions.map((sub) {
                            final isSelected = _preferredSubjects.contains(sub);
                            return FilterChip(
                              label: Text(
                                sub,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF4F46E5)
                                      : AppColors.textPrimary,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFFEEF2FF),
                              backgroundColor: const Color(0xFFF8FAFC),
                              checkmarkColor: const Color(0xFF4F46E5),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF818CF8)
                                    : const Color(0xFFE2E8F0),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (sub == 'সকল বিষয়') {
                                    _preferredSubjects.clear();
                                    if (selected) _preferredSubjects.add(sub);
                                    return;
                                  }
                                  _preferredSubjects.remove('সকল বিষয়');
                                  if (selected) {
                                    _preferredSubjects.add(sub);
                                  } else {
                                    _preferredSubjects.remove(sub);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 14),

                        // Classes
                        _buildFieldLabel(
                          context.tr(bn: 'পড়ানোর ক্লাস / লেভেল', en: 'Classes to Teach'),
                          isRequired: false,
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _classOptions.map((cls) {
                            final isSelected = _classesToTeach.contains(cls);
                            return FilterChip(
                              label: Text(
                                cls,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF0D9488)
                                      : AppColors.textPrimary,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFFCCFBF1),
                              backgroundColor: const Color(0xFFF8FAFC),
                              checkmarkColor: const Color(0xFF0D9488),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF2DD4BF)
                                    : const Color(0xFFE2E8F0),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _classesToTeach.add(cls);
                                  } else {
                                    _classesToTeach.remove(cls);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 14),

                        // Expected Fee
                        _buildFieldLabel(
                          context.tr(bn: 'প্রত্যাশিত পারিশ্রমিক (মাসিক)', en: 'Expected Fee (Monthly)'),
                          isRequired: false,
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _feeOptions.map((fee) {
                            final isSelected = _expectedFee == fee;
                            return ChoiceChip(
                              label: Text(
                                fee,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFFEA580C)
                                      : AppColors.textPrimary,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFFFFF7ED),
                              backgroundColor: const Color(0xFFF8FAFC),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFFFB923C)
                                    : const Color(0xFFE2E8F0),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _expectedFee = selected ? fee : '';
                                  if (selected) _customFeeController.clear();
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 14),

                        // Days per week
                        _buildFieldLabel(
                          context.tr(bn: 'সপ্তাহে পড়ানোর দিন', en: 'Days per Week'),
                          isRequired: false,
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _daysOptions.map((days) {
                            final isSelected = _daysPerWeek == days;
                            return ChoiceChip(
                              label: Text(
                                days,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF7C3AED)
                                      : AppColors.textPrimary,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFFF5F3FF),
                              backgroundColor: const Color(0xFFF8FAFC),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFFA78BFA)
                                    : const Color(0xFFE2E8F0),
                              ),
                              onSelected: (selected) {
                                setState(() => _daysPerWeek = selected ? days : '');
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submit Button matching Screenshot 1
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAndSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316), // Match orange button in screenshot
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFF1E293B),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  context.tr(
                                    bn: 'টিউশনের জন্য আবেদন জমা দিন',
                                    en: 'Submit Tuition Application',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Security & Trust text matching Screenshot 1
                  Center(
                    child: Text(
                      context.tr(
                        bn: 'আপনার তথ্য সম্পূর্ণ গোপন ও নিরাপদ থাকবে। আবেদন সম্পূর্ণ ফ্রি।',
                        en: 'Your information remains confidential and secure. Application is completely free.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
