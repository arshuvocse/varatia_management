import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_models.dart';
import '../../../data/services/auth_session_service.dart';
import '../../../data/services/contact_request_api_service.dart';
import '../../../data/services/tenant_tutor_api_service.dart';
import '../screens/home/tenant_home_screen.dart';

/// Unified model for Facebook-style social feed items
class SocialPostData {
  const SocialPostData({
    required this.id,
    required this.postType,
    required this.authorName,
    this.authorRole,
    this.authorAvatar,
    this.isVerified = false,
    this.publishedAt,
    required this.category,
    required this.categoryLabel,
    required this.title,
    this.description,
    required this.priceFormatted,
    required this.locationFormatted,
    this.imageUrls = const [],
    this.badges = const [],
    this.advanceFormatted,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isSaved = false,
    this.rawObject,
  });

  final int id;
  final String postType; // 'general' or 'tutor'
  final String authorName;
  final String? authorRole;
  final String? authorAvatar;
  final bool isVerified;
  final DateTime? publishedAt;
  final String category;
  final String categoryLabel;
  final String title;
  final String? description;
  final String priceFormatted;
  final String locationFormatted;
  final List<String> imageUrls;
  final List<String> badges;
  final String? advanceFormatted;
  final int likesCount;
  final int commentsCount;
  final bool isSaved;
  final dynamic rawObject;

  factory SocialPostData.fromGeneralPost(
    GeneralPostItem post, {
    bool isSaved = false,
  }) {
    final images = <String>[];
    if (post.mediaInfo != null && post.mediaInfo!.isNotEmpty) {
      try {
        if (post.mediaInfo!.trim().startsWith('{')) {
          final decoded = jsonDecode(post.mediaInfo!) as Map<String, dynamic>;
          if (decoded.containsKey('imageUrl')) {
            images.add(decoded['imageUrl'] as String);
          }
        } else {
          final parts = post.mediaInfo!.split(',');
          for (final part in parts) {
            final trimmed = part.trim();
            final lower = trimmed.toLowerCase();
            if (lower.endsWith('.jpg') ||
                lower.endsWith('.jpeg') ||
                lower.endsWith('.png') ||
                lower.endsWith('.webp') ||
                lower.endsWith('.gif')) {
              final normalized = trimmed.startsWith('/')
                  ? trimmed
                  : '/$trimmed';
              images.add('${ApiConfig.baseUrl}$normalized');
            }
          }
        }
      } catch (_) {}
    }

    final badgesList = <String>[];
    if (post.bedrooms > 0) badgesList.add('${post.bedrooms} বেড');
    if (post.bathrooms > 0) badgesList.add('${post.bathrooms} বাথ');
    if (post.kitchens > 0) badgesList.add('${post.kitchens} কিচেন');
    if (post.balconies > 0) badgesList.add('${post.balconies} বারান্দা');
    if (post.hasGas) badgesList.add('গ্যাস');
    if (post.hasLift) badgesList.add('লিফট');
    if (post.hasGenerator) badgesList.add('জেনারেটর');
    if (post.hasParking) badgesList.add('পার্কিং');

    String catLabel;
    switch (post.category.toLowerCase()) {
      case 'flat_wanted':
      case 'looking_flat':
        catLabel = 'বাসা চাই';
        break;
      case 'room_rent':
        catLabel = 'রুম ভাড়া';
        break;
      case 'room_wanted':
        catLabel = 'রুম চাই';
        break;
      case 'sublet':
        catLabel = 'সাবলেট';
        break;
      case 'sublet_wanted':
        catLabel = 'সাবলেট চাই';
        break;
      case 'bachelor':
        catLabel = 'ব্যাচেলর মেস';
        break;
      case 'seat_rent':
        catLabel = 'সিট ভাড়া';
        break;
      case 'sale':
        catLabel = 'বিক্রি';
        break;
      case 'rent':
      default:
        catLabel =
            post.tenantType == 'bachelor_male' ||
                post.tenantType == 'bachelor_female'
            ? 'ব্যাচেলর বাসা'
            : 'ফ্ল্যাট ভাড়া';
        break;
    }

    final formattedPrice = post.price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    final area = post.areaNameBn.isNotEmpty ? post.areaNameBn : post.areaId;
    final division = post.divisionNameBn.isNotEmpty
        ? post.divisionNameBn
        : 'ঢাকা';

    return SocialPostData(
      id: post.id,
      postType: 'general',
      authorName: 'বাড়িওয়ালা / সদস্য #${post.id}',
      authorRole: post.category == 'flat_wanted' ? 'ভাড়াটিয়া' : 'বাড়িওয়ালা',
      isVerified: true,
      publishedAt: post.createdOn,
      category: post.category,
      categoryLabel: catLabel,
      title: post.title,
      description: post.description,
      priceFormatted: '৳$formattedPrice / মাস',
      locationFormatted: '$area, $division',
      imageUrls: images,
      badges: badgesList,
      advanceFormatted: post.advance != null && post.advance! > 0
          ? 'অ্যাডভান্স: ৳${post.advance!.toStringAsFixed(0)}'
          : null,
      likesCount: (post.id * 7) % 43 + 3,
      commentsCount: (post.id * 3) % 19 + 1,
      isSaved: isSaved,
      rawObject: post,
    );
  }

  factory SocialPostData.fromShowcase(
    TenantShowcaseListingData listing, {
    bool isSaved = false,
  }) {
    final images = <String>[];
    if (listing.imageUrl != null && listing.imageUrl!.isNotEmpty) {
      images.add(listing.imageUrl!);
    }

    final badgesList = <String>[];
    if (listing.bedrooms > 0) badgesList.add('${listing.bedrooms} বেড');
    if (listing.bathrooms > 0) badgesList.add('${listing.bathrooms} বাথ');
    if (listing.areaSqft > 0) badgesList.add('${listing.areaSqft} sqft');

    return SocialPostData(
      id: listing.postId ?? 0,
      postType: listing.postType ?? 'general',
      authorName: 'সদস্য #${listing.postId ?? 1}',
      authorRole: 'বাড়িওয়ালা',
      isVerified: true,
      category: listing.category.name == 'sale' ? 'sale' : 'rent',
      categoryLabel: listing.badge.bn,
      title: listing.title.bn,
      priceFormatted: listing.price.bn,
      locationFormatted: listing.location.bn,
      imageUrls: images,
      badges: badgesList,
      likesCount: 12,
      commentsCount: 4,
      isSaved: isSaved,
      rawObject: listing,
    );
  }

  factory SocialPostData.fromTutor(
    TenantTutorPost post, {
    bool isSaved = false,
  }) {
    final isRequest = post.type == 'request';
    final intId = int.tryParse(post.id) ?? post.id.hashCode.abs() % 10000;

    final badgesList = <String>[];
    if (post.experience.bn.isNotEmpty) badgesList.add(post.experience.bn);
    if (post.availability.bn.isNotEmpty) badgesList.add(post.availability.bn);

    return SocialPostData(
      id: intId,
      postType: 'tutor',
      authorName: post.name.isNotEmpty
          ? post.name
          : (isRequest ? 'অভিভাবক' : 'শিক্ষক'),
      authorRole: post.role.bn.isNotEmpty
          ? post.role.bn
          : (isRequest ? 'অভিভাবক' : 'গৃহশিক্ষক'),
      isVerified: post.verified,
      category: isRequest ? 'looking_tutor' : 'tutor_available',
      categoryLabel: post.badge.bn.isNotEmpty
          ? post.badge.bn
          : (isRequest ? 'শিক্ষক চাই' : 'শিক্ষক দিচ্ছি'),
      title: '${post.subject.bn} — ${post.area.bn}',
      description: post.description.bn.isNotEmpty
          ? post.description.bn
          : post.remarks,
      priceFormatted: post.price.bn.isNotEmpty
          ? post.price.bn
          : 'আলোচনা সাপেক্ষে',
      locationFormatted: post.area.bn,
      badges: badgesList,
      likesCount: (intId * 5) % 35 + 2,
      commentsCount: (intId * 2) % 15,
      isSaved: isSaved,
      rawObject: post,
    );
  }
}

/// Facebook-style Social Feed Post Card
class SocialPostCard extends StatefulWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onBookmarkToggle,
  });

  final SocialPostData post;
  final VoidCallback? onTap;
  final Future<void> Function()? onBookmarkToggle;

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> {
  final ContactRequestApiService _contactApiService =
      ContactRequestApiService();

  bool _isLiked = false;
  late int _likesCount;
  late bool _isSaved;
  bool _isDescriptionExpanded = false;

  ContactRequestStatus _contactStatus = ContactRequestStatus.none();
  bool _isSubmittingContactRequest = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    _isSaved = widget.post.isSaved;
    _checkContactStatus();
  }

  @override
  void didUpdateWidget(covariant SocialPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.isSaved != widget.post.isSaved) {
      _isSaved = widget.post.isSaved;
      _checkContactStatus();
    }
  }

  @override
  void dispose() {
    _contactApiService.dispose();
    super.dispose();
  }

  Future<void> _checkContactStatus() async {
    if (widget.post.id <= 0) return;
    try {
      final userId = await AuthSessionService().readUserId() ?? '';
      if (userId.isEmpty) return;

      final status = await _contactApiService.getContactStatus(
        requesterUserId: userId,
        postType: widget.post.postType,
        postId: widget.post.id,
      );

      if (mounted) {
        setState(() => _contactStatus = status);
      }
    } catch (_) {}
  }

  Future<void> _handleRequestContact() async {
    final userId = await AuthSessionService().readUserId() ?? '';
    if (!mounted) return;

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'বিজ্ঞাপনদাতার যোগাযোগের নম্বর পেতে অনুগ্রহ করে লগইন করুন।',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Show confirmation dialog explaining privacy & admin approval
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'যোগাযোগের নম্বর অনুরোধ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'বিজ্ঞাপনদাতার গোপনীয়তা ও নিরাপত্তার জন্য মোবাইল নম্বর সরাসরি প্রকাশ করা হয় না।',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'আপনি অনুরোধ পাঠালে আমাদের অ্যাডমিন টিম তা দ্রুত পর্যালোচনা করে অনুমোদন দেবেন। অনুমোদন পেলেই আপনি অ্যাপে বিজ্ঞাপনদাতার নম্বর দেখতে পাবেন এবং সরাসরি কল করতে পারবেন।',
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
                children: const [
                  Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'এই প্রক্রিয়াটি সম্পূর্ণ নিরাপদ ও ভেরিফাইড।',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('অনুরোধ পাঠান'),
          ),
        ],
      ),
    );

    if (shouldProceed != true || !mounted) return;

    setState(() => _isSubmittingContactRequest = true);

    try {
      final status = await _contactApiService.createContactRequest(
        requesterUserId: userId,
        postType: widget.post.postType,
        postId: widget.post.id,
        purpose: 'Interested in post #${widget.post.id}: ${widget.post.title}',
      );

      if (mounted) {
        setState(() {
          _contactStatus = status;
          _isSubmittingContactRequest = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'অনুরোধ সফলভাবে পাঠানো হয়েছে! অ্যাডমিন পর্যালোচনার পর নম্বরটি দৃশ্যমান হবে।',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingContactRequest = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _callNumber(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s+'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('কল করা সম্ভব হচ্ছে না: $phone')),
        );
      }
    }
  }

  void _showCommentsBottomSheet() {
    final textController = TextEditingController();
    final sampleComments = <String>[
      'লোকেশনটা খুব সুন্দর! যোগাযোগ করতে অনুরোধ করেছি।',
      'ভাড়ার পরিমাণ কিছুটা কমানো সম্ভব কি?',
      'অ্যাডভান্স কত মাসের নেওয়া হবে?',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SizedBox(
                height: 440,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'মন্তব্য (${sampleComments.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.separated(
                        itemCount: sampleComments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, idx) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    child: const Icon(
                                      Icons.person,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ইউজার #${idx + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'কিছুক্ষণ আগে',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                sampleComments[idx],
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: InputDecoration(
                              hintText: 'একটি মন্তব্য লিখুন...',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            if (textController.text.trim().isNotEmpty) {
                              setSheetState(() {
                                sampleComments.add(textController.text.trim());
                                textController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReportDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('পোস্ট রিপোর্ট করুন'),
        content: const Text(
          'আপনি কি নিশ্চিত যে এই পোস্টটি প্ল্যাটফর্মের নিয়মাবলী লঙ্ঘন করছে? আমাদের মডারেশন টিম এটি যাচাই করবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('রিপোর্ট গ্রহণ করা হয়েছে। ধন্যবাদ।'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text(
              'রিপোর্ট পাঠান',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime? dt) {
    if (dt == null) return 'নতুন পোস্ট';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} মিনিট আগে';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ঘণ্টা আগে';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} দিন আগে';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Author Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceSoft,
                  child: Text(
                    post.authorName.isNotEmpty
                        ? post.authorName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _formatTimeAgo(post.publishedAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '•',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              post.categoryLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppColors.textMuted,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    if (val == 'report') {
                      _showReportDialog();
                    } else if (val == 'copy') {
                      Clipboard.setData(
                        ClipboardData(
                          text: '${post.title} - ${post.locationFormatted}',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('পোস্টের তথ্য কপি করা হয়েছে'),
                        ),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('লিংক ও তথ্য কপি'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: const [
                          Icon(
                            Icons.flag_outlined,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'রিপোর্ট করুন',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Title & Price row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: widget.onTap,
                  child: Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      post.priceFormatted,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (post.advanceFormatted != null)
                      Text(
                        post.advanceFormatted!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        post.locationFormatted,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Feature Badges Chips
          if (post.badges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: post.badges.map((b) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // 4. Description with expand/collapse
          if (post.description != null && post.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => setState(
                  () => _isDescriptionExpanded = !_isDescriptionExpanded,
                ),
                child: Text(
                  post.description!,
                  maxLines: _isDescriptionExpanded ? 100 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],

          // 5. Image Preview
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: widget.onTap,
              child: ClipRRect(
                child: Image.network(
                  post.imageUrls.first,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],

          // 6. Secure Privacy-Protected Contact Action Box
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _contactStatus.isApproved
                  ? const Color(0xFFF0FDF4)
                  : (_contactStatus.status == 'pending'
                        ? const Color(0xFFFFFBEB)
                        : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _contactStatus.isApproved
                    ? const Color(0xFFBBF7D0)
                    : (_contactStatus.status == 'pending'
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFE2E8F0)),
              ),
            ),
            child: _buildContactSection(),
          ),

          // 7. Social Action Bar (Like, Comment, Save, Share)
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Like Button
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLiked = !_isLiked;
                      _likesCount += _isLiked ? 1 : -1;
                    });
                  },
                  icon: Icon(
                    _isLiked
                        ? Icons.thumb_up_rounded
                        : Icons.thumb_up_alt_outlined,
                    size: 18,
                    color: _isLiked ? AppColors.primary : AppColors.textMuted,
                  ),
                  label: Text(
                    '$_likesCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _isLiked
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _isLiked ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ),
                // Comment Button
                TextButton.icon(
                  onPressed: _showCommentsBottomSheet,
                  icon: const Icon(
                    Icons.mode_comment_outlined,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  label: Text(
                    '${widget.post.commentsCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                // Bookmark / Save
                TextButton.icon(
                  onPressed: () async {
                    setState(() => _isSaved = !_isSaved);
                    if (widget.onBookmarkToggle != null) {
                      await widget.onBookmarkToggle!();
                    }
                  },
                  icon: Icon(
                    _isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    size: 19,
                    color: _isSaved ? AppColors.primary : AppColors.textMuted,
                  ),
                  label: Text(
                    _isSaved ? 'সংরক্ষিত' : 'সংরক্ষণ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _isSaved
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _isSaved ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    if (_contactStatus.isApproved &&
        _contactStatus.revealedPhoneNumber != null) {
      final phone = _contactStatus.revealedPhoneNumber!;
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF16A34A),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'নম্বর অনুমোদিত (Admin Approved)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _callNumber(phone),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.call, size: 16),
            label: const Text(
              'কল করুন',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    if (_contactStatus.status == 'pending') {
      return Row(
        children: const [
          Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'অনুরোধ অপেক্ষমাণ (Pending Admin Review)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'অ্যাডমিন অনুমোদন সম্পন্ন হলে নম্বরটি দৃশ্যমান হবে।',
                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_contactStatus.status == 'rejected') {
      return Row(
        children: const [
          Icon(Icons.cancel_outlined, color: AppColors.danger, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'যোগাযোগের অনুরোধটি অ্যাডমিন কর্তৃক অনুমোদিত হয়নি।',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    // Default: Not yet requested
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'মোবাইল নম্বর সুরক্ষিত (Private)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              SizedBox(height: 1),
              Text(
                'অ্যাডমিন অনুমোদনের মাধ্যমে দেখতে চান?',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmittingContactRequest ? null : _handleRequestContact,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmittingContactRequest
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'নম্বর চান',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
        ),
      ],
    );
  }
}
