import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_context.dart';
import '../../../../data/services/auth_session_service.dart';
import '../../../../data/services/dhaka_location_api_service.dart';
import '../../../../data/services/general_post_api_service.dart';
import '../../../../data/services/service_charge_payment_api_service.dart';
import '../../../../data/services/tenant_area_api_service.dart';
import '../../../../data/services/posting_entitlement_service.dart';
import '../../widgets/app_widgets.dart';
import '../payment/ssl_commerz_payment_screen.dart';

enum PostCategory {
  rent, // ফ্ল্যাট ভাড়া
  flatWanted, // বাসা চাই
  roomRent, // রুম ভাড়া
  roomWanted, // রুম চাই
  sublet, // সাবলেট
  subletWanted, // সাবলেট চাই
  bachelor, // ব্যাচেলর মেস
  seatRent, // সিট ভাড়া
  tutorAvailable, // শিক্ষক দিতে চাই
  lookingTutor, // শিক্ষক চাই
  sale, // বিক্রি
}

class GeneralPostComposerPage extends StatefulWidget {
  const GeneralPostComposerPage({super.key});

  @override
  State<GeneralPostComposerPage> createState() =>
      _GeneralPostComposerPageState();
}

class _GeneralPostComposerPageState extends State<GeneralPostComposerPage> {
  static const int _maxMediaFileBytes = 100 * 1024 * 1024;
  static const Set<String> _allowedMediaExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'mp4',
    'mov',
    'webm',
  };

  final DhakaLocationApiService _locationApiService = DhakaLocationApiService();
  final TenantAreaApiService _areaApiService = TenantAreaApiService();
  final GeneralPostApiService _generalPostApiService = GeneralPostApiService();
  final PostingEntitlementService _entitlementService =
      PostingEntitlementService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _advanceController = TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  PostCategory _selectedCategory = PostCategory.rent;
  String _selectedTenantType =
      'family'; // 'family', 'bachelor_male', 'bachelor_female'
  bool _utilityIncluded = false;

  List<DhakaDivisionOption> _divisions = const [];
  List<DhakaAreaOption> _areas = const [];
  String? _selectedDivisionId;
  String? _selectedAreaId;

  bool _isLoadingDivisions = true;
  bool _isLoadingAreas = false;
  bool _isSubmitting = false;

  // Posting Entitlement State
  PostingEntitlement? _postingEntitlement;
  bool _isLoadingEntitlement = true;

  String? _locationError;
  final List<PlatformFile> _selectedMedia = [];

  int _bedrooms = 1;
  int _bathrooms = 1;
  int _kitchens = 1;
  int _balconies = 0;

  bool _hasGas = false;
  bool _hasLift = false;
  bool _hasGenerator = false;
  bool _hasParking = false;

  bool get _isRentalCategory =>
      _selectedCategory == PostCategory.rent ||
      _selectedCategory == PostCategory.roomRent ||
      _selectedCategory == PostCategory.sublet ||
      _selectedCategory == PostCategory.bachelor ||
      _selectedCategory == PostCategory.seatRent;

  bool get _isTutorCategory =>
      _selectedCategory == PostCategory.tutorAvailable ||
      _selectedCategory == PostCategory.lookingTutor;

  String get _categoryBackendString => switch (_selectedCategory) {
    PostCategory.rent => 'rent',
    PostCategory.flatWanted => 'flat_wanted',
    PostCategory.roomRent => 'room_rent',
    PostCategory.roomWanted => 'room_wanted',
    PostCategory.sublet => 'sublet',
    PostCategory.subletWanted => 'sublet_wanted',
    PostCategory.bachelor => 'bachelor',
    PostCategory.seatRent => 'seat_rent',
    PostCategory.tutorAvailable => 'tutor_available',
    PostCategory.lookingTutor => 'looking_tutor',
    PostCategory.sale => 'sale',
  };

  @override
  void initState() {
    super.initState();
    unawaited(_loadDivisions());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadPostingEntitlement());
    });
  }

  @override
  void dispose() {
    _locationApiService.dispose();
    _areaApiService.dispose();
    _generalPostApiService.dispose();
    _entitlementService.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _advanceController.dispose();
    _fullAddressController.dispose();
    _streetController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDivisions() async {
    setState(() {
      _isLoadingDivisions = true;
      _locationError = null;
    });

    try {
      final divisions = await _locationApiService.getDivisions();
      if (mounted) {
        setState(() => _divisions = divisions);
      }
    } on DhakaLocationApiException catch (error) {
      if (mounted) {
        setState(() => _locationError = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationError = 'Unable to load location options.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDivisions = false);
      }
    }
  }

  Future<void> _loadAreas(String divisionId) async {
    setState(() {
      _selectedDivisionId = divisionId;
      _selectedAreaId = null;
      _areas = const [];
      _isLoadingAreas = true;
      _locationError = null;
    });

    try {
      final areas = await _locationApiService.getAreas(divisionId: divisionId);
      if (mounted && _selectedDivisionId == divisionId) {
        setState(() => _areas = areas);
      }
    } on DhakaLocationApiException catch (error) {
      if (mounted) {
        setState(() => _locationError = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationError = 'Unable to load area options.');
      }
    } finally {
      if (mounted && _selectedDivisionId == divisionId) {
        setState(() => _isLoadingAreas = false);
      }
    }
  }

  DhakaDivisionOption? get _selectedDivision {
    final id = _selectedDivisionId;
    if (id == null) return null;
    for (final division in _divisions) {
      if (division.id == id) return division;
    }
    return null;
  }

  DhakaAreaOption? get _selectedArea {
    final id = _selectedAreaId;
    if (id == null) return null;
    for (final area in _areas) {
      if (area.id == id) return area;
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String> _readCurrentUserId() async {
    final userId = await AuthSessionService().readUserId();
    if (userId == null || userId.isEmpty) {
      throw const ServiceChargePaymentApiException(
        'ইউজার সেশন পাওয়া যায়নি। অনুগ্রহ করে আবার লগইন করুন।',
      );
    }
    return userId;
  }

  Future<void> _loadPostingEntitlement() async {
    setState(() => _isLoadingEntitlement = true);
    try {
      final userId = await _readCurrentUserId();
      final entitlement = await _entitlementService.getEntitlement(userId);
      if (mounted) {
        setState(() {
          _postingEntitlement = entitlement;
          _isLoadingEntitlement = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingEntitlement = false);
      }
    }
  }

  Future<bool> _handleEntitlementCheckBeforeSubmit(String userId) async {
    setState(() => _isLoadingEntitlement = true);
    PostingEntitlement entitlement;
    try {
      entitlement = await _entitlementService.getEntitlement(userId);
      if (mounted) {
        setState(() {
          _postingEntitlement = entitlement;
          _isLoadingEntitlement = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingEntitlement = false);
      }
      return true; // Fallback to let backend enforce authoritative check
    }

    if (!mounted) return false;

    if (entitlement.canPost) {
      return true;
    }

    // Quota exhausted! Initiate paid posting flow (min 100 BDT)
    final payConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'পোস্টিং কোটা সমাপ্ত',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'আপনার অ্যাকাউন্টের ৪টি ফ্রি পোস্টের কোটা পূর্ণ হয়ে গেছে।',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'পরবর্তী বিজ্ঞাপন প্রকাশ করতে SSLCommerz গেটওয়ের মাধ্যমে ন্যূনতম ১০০ টাকা ফি প্রদান করুন। প্রতিটি ১০০ টাকায় ১টি নতুন পোস্ট ক্রেডিট যুক্ত হবে।',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'প্রদেয় ফি:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '৳ ১০০.০০',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('SSLCommerz এ পেমেন্ট করুন'),
          ),
        ],
      ),
    );

    if (payConfirmed != true || !mounted) return false;

    // Initiate payment
    try {
      final session = await _entitlementService.initiatePayment(
        userId: userId,
        amount: 100.0,
      );

      if (!mounted) return false;

      final paymentSuccess = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              SslCommerzPaymentScreen(paymentUrl: session.gatewayUrl),
        ),
      );

      if (paymentSuccess == true) {
        // Refresh entitlement
        final updated = await _entitlementService.getEntitlement(userId);
        if (mounted) {
          setState(() => _postingEntitlement = updated);
          _showMessage('পেমেন্ট সফল হয়েছে! পোস্টিং ক্রেডিট যুক্ত হয়েছে।');
        }
        return updated.canPost;
      } else {
        _showMessage('পেমেন্ট সম্পন্ন হয়নি বা বাতিল করা হয়েছে।');
        return false;
      }
    } catch (e) {
      _showMessage('পেমেন্ট শুরু করতে ব্যর্থ: $e');
      return false;
    }
  }

  Widget _buildPostingEntitlementBanner() {
    if (_isLoadingEntitlement) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: const [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'পোস্টিং কোটা যাচাই হচ্ছে...',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final entitlement = _postingEntitlement;
    if (entitlement == null) return const SizedBox.shrink();

    if (entitlement.canPost) {
      final isFree = entitlement.remainingFreePosts > 0;
      final progress = isFree ? (entitlement.remainingFreePosts / 4.0).clamp(0.0, 1.0) : 1.0;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isFree
                ? [
                    const Color(0xFFF0FDF4),
                    const Color(0xFFF8FAFC),
                    const Color(0xFFEFF6FF),
                  ]
                : [
                    const Color(0xFFFAF5FF),
                    const Color(0xFFFDF4FF),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isFree ? const Color(0xFFBFDBFE) : const Color(0xFFE9D5FF),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isFree ? const Color(0xFF2563EB) : const Color(0xFF9333EA))
                  .withValues(alpha: 0.08),
              blurRadius: 14,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isFree
                          ? [const Color(0xFF2563EB), const Color(0xFF4F46E5)]
                          : [const Color(0xFF9333EA), const Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isFree
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF9333EA))
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFree ? Icons.card_giftcard_rounded : Icons.stars_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isFree
                                  ? context.tr(
                                      bn: 'ফ্রি পোস্টিং কোটা সক্রিয়',
                                      en: 'Free Posting Quota Active',
                                    )
                                  : context.tr(
                                      bn: 'পেইড ক্রেডিট ব্যালেন্স',
                                      en: 'Paid Credit Balance',
                                    ),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isFree
                                    ? const Color(0xFF1E40AF)
                                    : const Color(0xFF6B21A8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isFree
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isFree
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFD8B4FE),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isFree
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF9333EA),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isFree ? 'সক্রিয়' : 'পেইড',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isFree
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF6B21A8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isFree
                            ? 'আপনার ৪টি ফ্রি পোস্টের মধ্যে ${entitlement.remainingFreePosts}টি বাকি আছে।'
                            : 'আপনার অ্যাকাউন্টে ${entitlement.paidCreditsBalance}টি পেইড পোস্ট ক্রেডিট আছে।',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isFree
                              ? const Color(0xFF334155)
                              : const Color(0xFF581C87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isFree) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${entitlement.remainingFreePosts}/৪ বাকি',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    // Exhausted
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFB45309)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    bn: 'ফ্রি পোস্টের কোটা পূর্ণ (৪/৪)',
                    en: 'Free Quota Reached (4/4)',
                  ),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr(
                    bn: 'পরবর্তী পোস্ট করতে ১০০ টাকা ফি প্রয়োজন।',
                    en: '৳100 fee required for subsequent posts.',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final userId = await _readCurrentUserId();
              await _handleEntitlementCheckBeforeSubmit(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              context.tr(bn: 'পেমেন্ট', en: 'Pay'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final userId = await _readCurrentUserId();
    final canProceed = await _handleEntitlementCheckBeforeSubmit(userId);
    if (!canProceed || !mounted) return;

    final mediaValidationMessage = _validateMediaFiles(_selectedMedia);
    if (mediaValidationMessage != null) {
      _showMessage(mediaValidationMessage);
      return;
    }

    final title = _titleController.text.trim();
    final price = _priceController.text.trim();
    final division = _selectedDivision;
    final area = _selectedArea;

    if (title.isEmpty) {
      _showMessage('পোস্টের শিরোনাম লিখুন।');
      return;
    }
    if (price.isEmpty) {
      final label = _isTutorCategory
          ? 'বেতন / ফি'
          : (_selectedCategory == PostCategory.sale ? 'মূল্য' : 'ভাড়া');
      _showMessage('মাসিক $label উল্লেখ করুন।');
      return;
    }
    if (division == null) {
      _showMessage('বিভাগ (Division) সিলেক্ট করুন।');
      return;
    }
    if (area == null) {
      _showMessage('এলাকা (District/Area) সিলেক্ট করুন।');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      final locationLabel = '${area.nameBn}, ${division.nameBn}';

      await _generalPostApiService.createPost(
        category: _categoryBackendString,
        title: title,
        price: double.tryParse(price) ?? 0.0,
        divisionId: division.id,
        areaId: area.id,
        tenantType: _isRentalCategory ? _selectedTenantType : null,
        advance: _isRentalCategory
            ? double.tryParse(_advanceController.text.trim())
            : null,
        utilityIncluded: _isRentalCategory && _utilityIncluded,
        fullAddress: _fullAddressController.text.trim().isNotEmpty
            ? _fullAddressController.text.trim()
            : null,
        street: _streetController.text.trim().isNotEmpty
            ? _streetController.text.trim()
            : null,
        latitude: double.tryParse(_latController.text.trim()),
        longitude: double.tryParse(_lngController.text.trim()),
        bedrooms: _isRentalCategory ? _bedrooms : 0,
        bathrooms: _isRentalCategory ? _bathrooms : 0,
        kitchens: _isRentalCategory ? _kitchens : 0,
        balconies: _isRentalCategory ? _balconies : 0,
        hasGas: _isRentalCategory && _hasGas,
        hasLift: _isRentalCategory && _hasLift,
        hasGenerator: _isRentalCategory && _hasGenerator,
        hasParking: _isRentalCategory && _hasParking,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        mediaFiles: _selectedMedia,
      );

      // Refresh entitlement after post creation
      unawaited(_loadPostingEntitlement());

      if (!mounted) return;

      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(context.tr(bn: 'সফল হয়েছে', en: 'Successful')),
            ],
          ),
          content: Text(
            context.tr(
              bn: 'আপনার বিজ্ঞাপনটি সফলভাবে পাবলিশ করা হয়েছে।\n\nলোকেশন: $locationLabel',
              en: 'Your advertisement was successfully published.\n\nLocation: $locationLabel',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (shouldClose == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } on GeneralPostApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } on ServiceChargePaymentApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to create post right now.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _fetchGPSLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        _showMessage(
          context.tr(
            bn: 'অনুগ্রহ করে আপনার ডিভাইসের লোকেশন সার্ভিস (GPS) চালু করুন।',
            en: 'Please enable your device location services (GPS).',
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          _showMessage(
            context.tr(
              bn: 'লোকেশন পারমিশন ছাড়া জিপিএস তথ্য পাওয়া সম্ভব নয়।',
              en: 'Location permission is required to fetch GPS coordinates.',
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          context.tr(
            bn: 'লোকেশন পারমিশন চিরতরে প্রত্যাখ্যান করা হয়েছে। সেটিংস থেকে পারমিশন দিন।',
            en: 'Location permissions are permanently denied. Please enable them in settings.',
          ),
        );
        return;
      }

      _showMessage(
        context.tr(
          bn: 'জিপিএস থেকে অবস্থান নেওয়া হচ্ছে...',
          en: 'Fetching location from GPS...',
        ),
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
        _fullAddressController.text = 'লোকেশন খোঁজা হচ্ছে...';
        _streetController.text = 'লোকেশন খোঁজা হচ্ছে...';
      });

      // Reverse Geocode to get street address
      try {
        final response = await http
            .get(
              Uri.parse(
                'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&accept-language=bn,en',
              ),
              headers: {'User-Agent': 'varatia_management_apps'},
            )
            .timeout(const Duration(seconds: 8));
        if (!mounted) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final displayName = data['display_name'] as String?;
          final address = data['address'] as Map<String, dynamic>?;

          setState(() {
            if (displayName != null && displayName.isNotEmpty) {
              _fullAddressController.text = displayName;
            } else {
              _fullAddressController.text =
                  'জিপিএস অবস্থান (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
            }

            if (address != null) {
              final road = address['road'] ?? '';
              final house = address['house_number'] ?? '';
              if (road.isNotEmpty && house.isNotEmpty) {
                _streetController.text = '$road, $house';
              } else if (road.isNotEmpty) {
                _streetController.text = road;
              } else {
                _streetController.text = '';
              }
            } else {
              _streetController.text = '';
            }
          });
        } else {
          setState(() {
            _fullAddressController.text =
                'জিপিএস অবস্থান (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
            _streetController.text = '';
          });
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _fullAddressController.text =
              'জিপিএস অবস্থান (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
          _streetController.text = '';
        });
      }

      _showMessage(
        context.tr(
          bn: 'আপনার অবস্থান জিপিএস থেকে সফলভাবে নেওয়া হয়েছে।',
          en: 'Current location successfully fetched from device GPS.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        context.tr(
          bn: 'জিপিএস তথ্য পাওয়া যায়নি। অনুগ্রহ করে ম্যানুয়ালি টাইপ করুন।',
          en: 'Could not fetch GPS information. Please type manually.',
        ),
      );
    }
  }

  bool _isVideo(PlatformFile file) {
    final ext = _mediaExtension(file);
    return ext == 'mp4' || ext == 'mov' || ext == 'webm';
  }

  String _mediaExtension(PlatformFile file) {
    final extension = file.extension;
    if (extension != null && extension.trim().isNotEmpty) {
      return extension.trim().toLowerCase();
    }

    final name = file.name.trim();
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  String? _validateMediaFiles(List<PlatformFile> files) {
    final hasInvalidType = files.any(
      (file) => !_allowedMediaExtensions.contains(_mediaExtension(file)),
    );
    if (hasInvalidType) {
      return 'শুধু JPG, PNG, WebP, GIF, MP4, MOV এবং WebM ফাইল আপলোড করা যাবে।';
    }

    final hasOversizeFile = files.any((file) => file.size > _maxMediaFileBytes);
    if (hasOversizeFile) {
      return 'প্রতিটি ছবি/ভিডিও সর্বোচ্চ 100 MB হতে পারবে।';
    }

    return null;
  }

  Future<void> _pickMedia() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _allowedMediaExtensions.toList(),
      );
      if (!mounted) return;

      if (result != null && result.files.isNotEmpty) {
        final validationMessage = _validateMediaFiles(result.files);
        if (validationMessage != null) {
          _showMessage(validationMessage);
          return;
        }

        setState(() {
          _selectedMedia.addAll(result.files);
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        context.tr(
          bn: 'মিডিয়া ফাইল সিলেক্ট করতে সমস্যা হয়েছে।',
          en: 'Failed to pick media files.',
        ),
      );
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  String _getCategoryName(PostCategory cat) => switch (cat) {
    PostCategory.rent => 'ফ্ল্যাট ভাড়া',
    PostCategory.flatWanted => 'বাসা চাই',
    PostCategory.roomRent => 'রুম ভাড়া',
    PostCategory.roomWanted => 'রুম চাই',
    PostCategory.sublet => 'সাবলেট',
    PostCategory.subletWanted => 'সাবলেট চাই',
    PostCategory.bachelor => 'ব্যাচেলর মেস',
    PostCategory.seatRent => 'সিট ভাড়া',
    PostCategory.tutorAvailable => 'শিক্ষক দিচ্ছি',
    PostCategory.lookingTutor => 'শিক্ষক চাই',
    PostCategory.sale => 'বিক্রি',
  };

  Widget _buildHeroPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGroup({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String countBadge,
    required List<Widget> chips,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  countBadge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceLabel = switch (_selectedCategory) {
      PostCategory.sale => context.tr(bn: 'বিক্রয় মূল্য (৳)', en: 'Price (৳)'),
      PostCategory.tutorAvailable || PostCategory.lookingTutor => context.tr(
        bn: 'মাসিক বেতন / ফি (৳)',
        en: 'Monthly Fee / Salary (৳)',
      ),
      PostCategory.flatWanted ||
      PostCategory.roomWanted ||
      PostCategory.subletWanted => context.tr(
        bn: 'প্রত্যাশিত বাজেট বা ভাড়া (৳)',
        en: 'Expected Budget / Rent (৳)',
      ),
      _ => context.tr(bn: 'মাসিক ভাড়া (৳)', en: 'Monthly Rent (৳)'),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(bn: 'নতুন বিজ্ঞাপন তৈরি করুন', en: 'Create New Ad'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              context.tr(
                bn: 'বাসা ভাড়া, মেস ও শিক্ষক লিস্টিং',
                en: 'Rent, Mess & Tutor Listings',
              ),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F5F9), Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              // Intro Hero Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.campaign_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  bn: 'বিজ্ঞাপন তৈরি করুন',
                                  en: 'Create New Ad',
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr(
                                  bn: 'বাসা ভাড়া বা বিক্রির জন্য প্রয়োজনীয় বিবরণ দিয়ে পোস্ট করুন।',
                                  en: 'Post with essential details for rent, flat, or sale.',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildHeroPill(
                          icon: Icons.check_circle_rounded,
                          label: context.tr(bn: 'তাৎক্ষণিক প্রকাশ', en: 'Instant Live'),
                        ),
                        _buildHeroPill(
                          icon: Icons.stars_rounded,
                          label: context.tr(bn: '১০০% ফ্রি কোটা', en: 'Free Quota'),
                        ),
                        _buildHeroPill(
                          icon: Icons.verified_user_rounded,
                          label: context.tr(bn: 'যাচাইকৃত লিস্টিং', en: 'Verified'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Entitlement Status Banner
              _buildPostingEntitlementBanner(),
              const SizedBox(height: 16),

              // Organized Post Category Selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.category_rounded,
                            color: Color(0xFF4F46E5),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  bn: 'বিজ্ঞাপনের ক্যাটাগরি',
                                  en: 'Post Category',
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                context.tr(
                                  bn: 'সঠিক ক্যাটাগরি বেছে নিন',
                                  en: 'Choose category',
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: Color(0xFF4F46E5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getCategoryName(_selectedCategory),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4338CA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Group 1: বাসা ও ফ্ল্যাট
                    _buildCategoryGroup(
                      context: context,
                      title: context.tr(bn: 'বাসা ও ফ্ল্যাট', en: 'Flats & Apartments'),
                      subtitle: context.tr(
                        bn: 'সম্পূর্ণ ফ্ল্যাট ভাড়া, বাসা খোঁজা বা বিক্রি',
                        en: 'Full flat rent, search or sale',
                      ),
                      icon: Icons.apartment_rounded,
                      accentColor: const Color(0xFF4F46E5),
                      countBadge: '৩টি অপশন',
                      chips: [
                        _CategoryChip(
                          label: 'ফ্ল্যাট ভাড়া',
                          isSelected: _selectedCategory == PostCategory.rent,
                          icon: Icons.apartment_rounded,
                          accentColor: const Color(0xFF4F46E5),
                          onTap: () => setState(() => _selectedCategory = PostCategory.rent),
                        ),
                        _CategoryChip(
                          label: 'বাসা চাই',
                          isSelected: _selectedCategory == PostCategory.flatWanted,
                          icon: Icons.search_rounded,
                          accentColor: const Color(0xFF4F46E5),
                          onTap: () => setState(() => _selectedCategory = PostCategory.flatWanted),
                        ),
                        _CategoryChip(
                          label: 'বিক্রি',
                          isSelected: _selectedCategory == PostCategory.sale,
                          icon: Icons.sell_rounded,
                          accentColor: const Color(0xFF4F46E5),
                          onTap: () => setState(() => _selectedCategory = PostCategory.sale),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Group 2: রুম, সাবলেট ও মেস
                    _buildCategoryGroup(
                      context: context,
                      title: context.tr(bn: 'রুম, সাবলেট ও মেস', en: 'Rooms, Sublet & Mess'),
                      subtitle: context.tr(
                        bn: 'সিঙ্গেল রুম, সাবলেট অথবা ব্যাচেলর সিট',
                        en: 'Single room, sublet or bachelor seat',
                      ),
                      icon: Icons.meeting_room_rounded,
                      accentColor: const Color(0xFF0284C7),
                      countBadge: '৬টি অপশন',
                      chips: [
                        _CategoryChip(
                          label: 'রুম ভাড়া',
                          isSelected: _selectedCategory == PostCategory.roomRent,
                          icon: Icons.door_front_door_outlined,
                          accentColor: const Color(0xFF0284C7),
                          onTap: () => setState(() => _selectedCategory = PostCategory.roomRent),
                        ),
                        _CategoryChip(
                          label: 'রুম চাই',
                          isSelected: _selectedCategory == PostCategory.roomWanted,
                          icon: Icons.person_search_rounded,
                          accentColor: const Color(0xFF0284C7),
                          onTap: () => setState(() => _selectedCategory = PostCategory.roomWanted),
                        ),
                        _CategoryChip(
                          label: 'সাবলেট',
                          isSelected: _selectedCategory == PostCategory.sublet,
                          icon: Icons.holiday_village_rounded,
                          accentColor: const Color(0xFF0284C7),
                          onTap: () => setState(() => _selectedCategory = PostCategory.sublet),
                        ),
                        _CategoryChip(
                          label: 'সাবলেট চাই',
                          isSelected: _selectedCategory == PostCategory.subletWanted,
                          icon: Icons.home_work_rounded,
                          accentColor: const Color(0xFF0284C7),
                          onTap: () => setState(() => _selectedCategory = PostCategory.subletWanted),
                        ),
                        _CategoryChip(
                          label: 'ব্যাচেলর মেস',
                          isSelected: _selectedCategory == PostCategory.bachelor,
                          icon: Icons.groups_rounded,
                          accentColor: const Color(0xFF0284C7),
                          onTap: () => setState(() => _selectedCategory = PostCategory.bachelor),
                        ),
                        _CategoryChip(
                          label: 'সিট ভাড়া',
                          isSelected: _selectedCategory == PostCategory.seatRent,
                          icon: Icons.single_bed_rounded,
                          accentColor: const Color(0xFF0284C7),
                          onTap: () => setState(() => _selectedCategory = PostCategory.seatRent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Group 3: গৃহশিক্ষক ও টিউটর
                    _buildCategoryGroup(
                      context: context,
                      title: context.tr(bn: 'গৃহশিক্ষক ও টিউশন', en: 'Tutors & Tuition'),
                      subtitle: context.tr(
                        bn: 'অভিজ্ঞ শিক্ষক খুঁজুন বা নিজে পড়াতে চান',
                        en: 'Find tutor or teach students',
                      ),
                      icon: Icons.school_rounded,
                      accentColor: const Color(0xFF7C3AED),
                      countBadge: '২টি অপশন',
                      chips: [
                        _CategoryChip(
                          label: 'শিক্ষক দিচ্ছি',
                          isSelected: _selectedCategory == PostCategory.tutorAvailable,
                          icon: Icons.school_rounded,
                          accentColor: const Color(0xFF7C3AED),
                          onTap: () => setState(() => _selectedCategory = PostCategory.tutorAvailable),
                        ),
                        _CategoryChip(
                          label: 'শিক্ষক চাই',
                          isSelected: _selectedCategory == PostCategory.lookingTutor,
                          icon: Icons.menu_book_rounded,
                          accentColor: const Color(0xFF7C3AED),
                          onTap: () => setState(() => _selectedCategory = PostCategory.lookingTutor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Tenant Type (Only for Rent Out)
            if (_selectedCategory == PostCategory.rent) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: context.tr(
                  bn: 'ভাড়াটিয়ার ধরন (Tenant Category)',
                  en: 'Tenant Type',
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TenantTypeChip(
                      label: context.tr(bn: 'ফ্যামিলি', en: 'Family'),
                      isSelected: _selectedTenantType == 'family',
                      onTap: () =>
                          setState(() => _selectedTenantType = 'family'),
                    ),
                    _TenantTypeChip(
                      label: context.tr(
                        bn: 'ব্যাচেলর (ছেলে)',
                        en: 'Bachelor (Male)',
                      ),
                      isSelected: _selectedTenantType == 'bachelor_male',
                      onTap: () =>
                          setState(() => _selectedTenantType = 'bachelor_male'),
                    ),
                    _TenantTypeChip(
                      label: context.tr(
                        bn: 'ব্যাচেলর (মেয়ে)',
                        en: 'Bachelor (Female)',
                      ),
                      isSelected: _selectedTenantType == 'bachelor_female',
                      onTap: () => setState(
                        () => _selectedTenantType = 'bachelor_female',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Main Info
            SectionCard(
              title: context.tr(bn: 'মূল তথ্য', en: 'Primary Info'),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        bn: 'বিজ্ঞাপনের শিরোনাম',
                        en: 'Ad Title',
                      ),
                      hintText: context.tr(
                        bn: 'যেমন: ৩ বেডের সুন্দর ফ্ল্যাট ভাড়া হবে',
                        en: 'e.g. Beautiful 3 Bed Flat for Rent',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: priceLabel,
                      hintText: '৳ ০,০০০',
                    ),
                  ),
                  if (_selectedCategory == PostCategory.rent) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _advanceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.tr(
                          bn: 'অগ্রিম / সিকিউরিটি ডিপোজিট (৳)',
                          en: 'Security Deposit (৳)',
                        ),
                        hintText: '৳ ০,০০০',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(
                        context.tr(
                          bn: 'ইউটিলিটি বিল ভাড়ার সাথে অন্তর্ভুক্ত',
                          en: 'Utility Bills Included in Rent',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      value: _utilityIncluded,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) =>
                          setState(() => _utilityIncluded = val),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location Selector
            SectionCard(
              title: context.tr(bn: 'অবস্থান (Location)', en: 'Location'),
              icon: Icons.location_on_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_locationError != null) ...[
                    Text(
                      _locationError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  DropdownButtonFormField<String>(
                    value: _selectedDivisionId,
                    isExpanded: true,
                    items: _divisions
                        .map(
                          (division) => DropdownMenuItem<String>(
                            value: division.id,
                            child: Text(division.nameBn),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _isLoadingDivisions
                        ? null
                        : (value) {
                            if (value != null) {
                              unawaited(_loadAreas(value));
                            }
                          },
                    decoration: InputDecoration(
                      labelText: context.tr(
                        bn: 'বিভাগ (Division)',
                        en: 'Division',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedAreaId,
                    isExpanded: true,
                    items: _areas
                        .map(
                          (area) => DropdownMenuItem<String>(
                            value: area.id,
                            child: Text(area.nameBn),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _isLoadingAreas
                        ? null
                        : (value) => setState(() => _selectedAreaId = value),
                    decoration: InputDecoration(
                      labelText: context.tr(
                        bn: 'এলাকা (District/Area)',
                        en: 'District/Area',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullAddressController,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        bn: 'পূর্ণ ঠিকানা (Full Address)',
                        en: 'Full Address',
                      ),
                      hintText: context.tr(
                        bn: 'যেমন: বাড়ি ১২, রোড ৭, সেক্টর ৩, উত্তরা, ঢাকা',
                        en: 'e.g. House 12, Road 7, Sector 3, Uttara, Dhaka',
                      ),
                      prefixIcon: const Icon(Icons.home_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _streetController,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        bn: 'সড়ক ও বাসার নম্বর (Street Address)',
                        en: 'Street & House No.',
                      ),
                      hintText: context.tr(
                        bn: 'যেমন: রোড ১০, বাসা ৪/এ, উত্তরা',
                        en: 'e.g. Road 10, House 4/A, Uttara',
                      ),
                      prefixIcon: const Icon(
                        Icons.streetview_rounded,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: context.tr(
                              bn: 'অক্ষাংশ (Latitude)',
                              en: 'Latitude',
                            ),
                            hintText: '23.8103',
                            prefixIcon: const Icon(
                              Icons.navigation_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: context.tr(
                              bn: 'দ্রাঘিমাংশ (Longitude)',
                              en: 'Longitude',
                            ),
                            hintText: '90.4125',
                            prefixIcon: const Icon(
                              Icons.navigation_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _fetchGPSLocation,
                      icon: const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(
                        context.tr(
                          bn: 'ডিভাইস জিপিএস ব্যবহার করুন',
                          en: 'Use Device GPS',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Flat Specification
            SectionCard(
              title: context.tr(bn: 'রুমের বিবরণ', en: 'Room Details'),
              child: Column(
                children: [
                  _CounterField(
                    label: context.tr(bn: 'বেডরুম (Bedrooms)', en: 'Bedrooms'),
                    value: _bedrooms,
                    onChanged: (val) => setState(() => _bedrooms = val),
                    min: 1,
                  ),
                  const Divider(color: Color(0xFFE8ECF3), height: 16),
                  _CounterField(
                    label: context.tr(
                      bn: 'বাথরুম (Bathrooms)',
                      en: 'Bathrooms',
                    ),
                    value: _bathrooms,
                    onChanged: (val) => setState(() => _bathrooms = val),
                    min: 1,
                  ),
                  const Divider(color: Color(0xFFE8ECF3), height: 16),
                  _CounterField(
                    label: context.tr(
                      bn: 'রান্নাঘর (Kitchens)',
                      en: 'Kitchens',
                    ),
                    value: _kitchens,
                    onChanged: (val) => setState(() => _kitchens = val),
                    min: 1,
                  ),
                  const Divider(color: Color(0xFFE8ECF3), height: 16),
                  _CounterField(
                    label: context.tr(
                      bn: 'বারান্দা (Balcony)',
                      en: 'Balconies',
                    ),
                    value: _balconies,
                    onChanged: (val) => setState(() => _balconies = val),
                    min: 0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amenities
            SectionCard(
              title: context.tr(
                bn: 'অন্যান্য সুবিধাসমূহ',
                en: 'Additional Amenities',
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    avatar: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                    ),
                    label: Text(
                      context.tr(bn: 'গ্যাস কানেকশন', en: 'Gas Connection'),
                    ),
                    selected: _hasGas,
                    onSelected: (val) => setState(() => _hasGas = val),
                  ),
                  FilterChip(
                    avatar: const Icon(Icons.elevator_rounded, size: 16),
                    label: Text(context.tr(bn: 'লিফট সুবিধা', en: 'Lift')),
                    selected: _hasLift,
                    onSelected: (val) => setState(() => _hasLift = val),
                  ),
                  FilterChip(
                    avatar: const Icon(Icons.bolt_rounded, size: 16),
                    label: Text(context.tr(bn: 'জেনারেটর', en: 'Generator')),
                    selected: _hasGenerator,
                    onSelected: (val) => setState(() => _hasGenerator = val),
                  ),
                  FilterChip(
                    avatar: const Icon(Icons.local_parking_rounded, size: 16),
                    label: Text(
                      context.tr(bn: 'পার্কিং ব্যবস্থা', en: 'Parking'),
                    ),
                    selected: _hasParking,
                    onSelected: (val) => setState(() => _hasParking = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Description
            SectionCard(
              title: context.tr(bn: 'বিস্তারিত বিবরণ', en: 'Description'),
              child: TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: context.tr(
                    bn: 'বিস্তারিত লিখুন',
                    en: 'Write details',
                  ),
                  alignLabelWithHint: true,
                  hintText: context.tr(
                    bn: 'ফ্ল্যাটের অতিরিক্ত কোনো সুবিধা বা শর্তাবলী এখানে লিখুন...',
                    en: 'Enter any additional features, terms, or conditions here...',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Upload Section
            SectionCard(
              title: context.tr(
                bn: 'ছবি ও ভিডিও আপলোড',
                en: 'Upload Photos & Videos',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedMedia.isNotEmpty) ...[
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedMedia.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _selectedMedia.length) {
                            // Add more button
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: _pickMedia,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFCBD5E1),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_rounded,
                                    color: Color(0xFF64748B),
                                    size: 30,
                                  ),
                                ),
                              ),
                            );
                          }

                          final file = _selectedMedia[index];
                          final isVideo = _isVideo(file);

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    color: const Color(0xFFE2E8F0),
                                    child: isVideo
                                        ? const Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .play_circle_filled_rounded,
                                                  color: AppColors.primary,
                                                  size: 40,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Video',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF475569),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : (file.path != null
                                              ? Image.file(
                                                  File(file.path!),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(
                                                        Icons
                                                            .image_not_supported_rounded,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons
                                                      .insert_drive_file_rounded,
                                                )),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () => _removeMedia(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr(
                        bn: 'মোট ${_selectedMedia.length}টি ফাইল সিলেক্ট করা হয়েছে',
                        en: 'Total ${_selectedMedia.length} files selected',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ] else ...[
                    InkWell(
                      onTap: _pickMedia,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD8DEE8),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_rounded,
                              color: Color(0xFF94A3B8),
                              size: 36,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr(
                                bn: 'ছবি ও ভিডিও যোগ করুন',
                                en: 'Add Photos & Videos',
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr(
                                bn: 'একাধিক ছবি ও ভিডিও সিলেক্ট করতে পারবেন',
                                en: 'You can select multiple photos & videos',
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            _isSubmitting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3D4F46E5),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                      label: Text(
                        (_postingEntitlement != null &&
                                !_postingEntitlement!.canPost)
                            ? context.tr(
                                bn: '১০০ টাকা ফি দিয়ে পাবলিশ করুন',
                                en: 'Pay ৳100 to Publish',
                              )
                            : context.tr(
                                bn: 'লিস্টিং পাবলিশ করুন',
                                en: 'Publish Listing',
                              ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
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
}

class _CounterField extends StatelessWidget {
  const _CounterField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: value <= min ? null : () => onChanged(value - 1),
              icon: const Icon(Icons.remove_rounded, size: 18),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 32),
              alignment: Alignment.center,
              child: Text(
                context.digitsText(value),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

class _TenantTypeChip extends StatelessWidget {
  const _TenantTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFCBD5E1),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.32),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
              color: isSelected ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
    this.accentColor,
  });

  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? const Color(0xFF4F46E5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFCBD5E1),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.32),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : effectiveAccent,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
