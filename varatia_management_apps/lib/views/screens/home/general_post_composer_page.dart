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
import '../../widgets/app_widgets.dart';
import '../payment/ssl_commerz_payment_screen.dart';

enum PostCategory { rent, sale }

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
  final ServiceChargePaymentApiService _paymentApiService =
      ServiceChargePaymentApiService();

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
  bool _isCheckingPayment = true;
  bool _isCurrentMonthPaid = false;
  bool _isPaymentPromptVisible = false;
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

  @override
  void initState() {
    super.initState();
    unawaited(_loadDivisions());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkPaymentOnPageLoad());
    });
  }

  @override
  void dispose() {
    _locationApiService.dispose();
    _areaApiService.dispose();
    _generalPostApiService.dispose();
    _paymentApiService.dispose();
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

  Future<void> _checkPaymentOnPageLoad() async {
    try {
      final userId = await _readCurrentUserId();
      final isPaid = await _paymentApiService.checkPaymentStatus(userId);
      if (!mounted) return;

      setState(() {
        _isCurrentMonthPaid = isPaid;
        _isCheckingPayment = false;
      });

      if (!isPaid) {
        await _promptForCurrentMonthPayment(userId);
      }
    } on ServiceChargePaymentApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isCurrentMonthPaid = false;
        _isCheckingPayment = false;
      });
      _showMessage(error.message);
    }
  }

  Future<bool> _ensureCurrentMonthPayment() async {
    if (_isCheckingPayment) {
      _showMessage('পেমেন্ট স্ট্যাটাস যাচাই হচ্ছে। অনুগ্রহ করে অপেক্ষা করুন।');
      return false;
    }

    final userId = await _readCurrentUserId();
    final isPaid = await _paymentApiService.checkPaymentStatus(userId);
    if (!mounted) return false;

    setState(() => _isCurrentMonthPaid = isPaid);
    if (isPaid) return true;

    await _promptForCurrentMonthPayment(userId);
    return _isCurrentMonthPaid;
  }

  Future<void> _promptForCurrentMonthPayment(String userId) async {
    if (_isPaymentPromptVisible || !mounted) return;
    _isPaymentPromptVisible = true;

    try {
      final paymentCompleted = await _showServiceChargeBottomSheet(userId);
      if (paymentCompleted != true || !mounted) return;

      setState(() => _isCheckingPayment = true);
      final isPaid = await _paymentApiService.checkPaymentStatus(userId);
      if (!mounted) return;

      setState(() {
        _isCurrentMonthPaid = isPaid;
        _isCheckingPayment = false;
      });

      if (!isPaid) {
        _showMessage(
          'পেমেন্ট এখনো নিশ্চিত হয়নি। কিছুক্ষণ পরে আবার যাচাই করুন।',
        );
      }
    } on ServiceChargePaymentApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isCurrentMonthPaid = false;
        _isCheckingPayment = false;
      });
      _showMessage(error.message);
    } finally {
      _isPaymentPromptVisible = false;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    try {
      if (!await _ensureCurrentMonthPayment()) return;
    } on ServiceChargePaymentApiException catch (error) {
      if (mounted) _showMessage(error.message);
      return;
    }
    if (!mounted) return;

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
      final label = switch (_selectedCategory) {
        PostCategory.rent => 'ভাড়া',
        PostCategory.sale => 'মূল্য',
      };
      _showMessage('মাসিক $label বা মূল্য উল্লেখ করুন।');
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
        category: _selectedCategory == PostCategory.rent ? 'rent' : 'sale',
        title: title,
        price: double.tryParse(price) ?? 0.0,
        divisionId: division.id,
        areaId: area.id,
        tenantType: _selectedCategory == PostCategory.rent
            ? _selectedTenantType
            : null,
        advance: _selectedCategory == PostCategory.rent
            ? double.tryParse(_advanceController.text.trim())
            : null,
        utilityIncluded:
            _selectedCategory == PostCategory.rent && _utilityIncluded,
        fullAddress: _fullAddressController.text.trim().isNotEmpty
            ? _fullAddressController.text.trim()
            : null,
        street: _streetController.text.trim().isNotEmpty
            ? _streetController.text.trim()
            : null,
        latitude: double.tryParse(_latController.text.trim()),
        longitude: double.tryParse(_lngController.text.trim()),
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        kitchens: _kitchens,
        balconies: _balconies,
        hasGas: _hasGas,
        hasLift: _hasLift,
        hasGenerator: _hasGenerator,
        hasParking: _hasParking,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        mediaFiles: _selectedMedia,
      );

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

  Future<bool?> _showServiceChargeBottomSheet(String userId) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => PopScope(
        canPop: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadii.card),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.payment_rounded,
                color: AppColors.primary,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'মাসিক সার্ভিস চার্জ প্রদেয়',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'নতুন বিজ্ঞাপন পোস্ট করার পূর্বে এই মাসের জন্য ৫০ টাকা সার্ভিস চার্জ প্রদান করা আবশ্যক।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(bottomSheetContext).pop(true);
                  },
                  child: const Text('পেমেন্ট করুন (৫০ টাকা)'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((shouldPay) async {
      if (shouldPay == true) {
        if (!mounted) return false;
        _showLoadingDialog('পেমেন্ট গেটওয়ে লোড হচ্ছে...');

        try {
          final gatewayUrl = await _paymentApiService.initiatePayment(userId);
          if (!mounted) return false;
          _dismissLoadingDialog();

          final paymentResult = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) =>
                  SslCommerzPaymentScreen(paymentUrl: gatewayUrl),
            ),
          );

          return paymentResult ?? false;
        } catch (e) {
          if (mounted) {
            _dismissLoadingDialog();
            _showMessage(e.toString());
          }
          return false;
        }
      }
      return false;
    });
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  void _dismissLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
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

  @override
  Widget build(BuildContext context) {
    final priceLabel = switch (_selectedCategory) {
      PostCategory.rent => context.tr(
        bn: 'মাসিক ভাড়া (৳)',
        en: 'Monthly Rent (৳)',
      ),
      PostCategory.sale => context.tr(bn: 'বিক্রয় মূল্য (৳)', en: 'Price (৳)'),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.tr(bn: 'নতুন বিজ্ঞাপন তৈরি করুন', en: 'Create New Ad'),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            ScreenHeader(
              title: context.tr(
                bn: 'বিজ্ঞাপন তৈরি করুন',
                en: 'Create Advertisement',
              ),
              subtitle: context.tr(
                bn: 'বাসা ভাড়া বা বিক্রির জন্য প্রয়োজনীয় বিবরণ দিয়ে পোস্ট করুন।',
                en: 'Fill in details to post your flat rent or sale listing.',
              ),
            ),
            const SizedBox(height: 18),

            // Post Type Segmented Control
            SectionCard(
              title: context.tr(bn: 'বিজ্ঞাপনের ধরন', en: 'Advertisement Type'),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TypeSelectionButton(
                          label: context.tr(bn: 'ভাড়া দেব', en: 'Rent Out'),
                          isSelected: _selectedCategory == PostCategory.rent,
                          icon: Icons.home_rounded,
                          onTap: () => setState(
                            () => _selectedCategory = PostCategory.rent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TypeSelectionButton(
                          label: context.tr(bn: 'বিক্রি করব', en: 'For Sale'),
                          isSelected: _selectedCategory == PostCategory.sale,
                          icon: Icons.sell_rounded,
                          onTap: () => setState(
                            () => _selectedCategory = PostCategory.sale,
                          ),
                        ),
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
            _isSubmitting || _isCheckingPayment
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _submit,
                    child: Text(
                      _isCurrentMonthPaid
                          ? context.tr(bn: 'পাবলিশ করুন', en: 'Publish Listing')
                          : context.tr(
                              bn: 'পেমেন্ট করে পাবলিশ করুন',
                              en: 'Pay to Publish',
                            ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _TypeSelectionButton extends StatelessWidget {
  const _TypeSelectionButton({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
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
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
      ),
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }
}
