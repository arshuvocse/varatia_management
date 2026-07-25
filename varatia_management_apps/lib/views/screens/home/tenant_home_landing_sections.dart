import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ----------------- COLORS -----------------
class _LandingColors {
  static const primary = AppColors.primary;
  static const primaryDark = Color(0xFF145C36);
  static const accent = Color(0xFFF2A93B);
  static const bgLight = Color(0xFFF7F9F8);
  static const textDark = Color(0xFF1B2420);
  static const textGrey = Color(0xFF6B7570);
}

// ----------------- DATA MODELS -----------------
class _ServiceItem {
  final IconData icon;
  final String image;
  final String title;
  final String desc;
  final List<String> points;
  _ServiceItem(this.icon, this.image, this.title, this.desc, this.points);
}

class _GroceryItem {
  final String image;
  final String name;
  final String desc;
  final String tag;
  final String size;
  _GroceryItem(this.image, this.name, this.desc, this.tag, this.size);
}

final List<_ServiceItem> _services = [
  _ServiceItem(
    Icons.home_work_outlined,
    'https://images.unsplash.com/photo-1560518883-ce09059eeffa?auto=format&fit=crop&w=900&q=80',
    'ফ্ল্যাট ভাড়া',
    'বাড়িওয়ালা ও ভাড়াটিয়ার জন্য লোকেশন, বাজেট, ছবি, সুবিধা ও যোগাযোগের তথ্যসহ সহজ ফ্ল্যাট ভাড়া সার্ভিস।',
    [
      'Area ও বাজেট অনুযায়ী রিকোয়েস্ট',
      'ছবি, সুবিধা ও যোগাযোগের তথ্য',
      'দ্রুত আগ্রহী কাস্টমার Collection',
    ],
  ),
  _ServiceItem(
    Icons.sell_outlined,
    'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=900&q=80',
    'ফ্ল্যাট বিক্রি',
    'ফ্ল্যাট মালিক, ডেভেলপার বা সেলারদের জন্য পরিষ্কার তথ্য, ছবি ও লোকেশনসহ প্রপার্টি প্রমোশন সুবিধা।',
    [
      'দাম, সাইজ ও লোকেশন স্পষ্টভাবে দেখানো',
      'আগ্রহী ক্রেতার রিকোয়েস্ট তালিকা',
      'বিশ্বাসযোগ্য ডিল প্রেজেন্টেশন',
    ],
  ),
  _ServiceItem(
    Icons.search,
    'https://images.unsplash.com/photo-1558036117-15d82a90b9b1?auto=format&fit=crop&w=900&q=80',
    'বাসা খোঁজা',
    'ভাড়াটিয়া বা ক্রেতা তাদের এরিয়া, বাজেট ও পছন্দ জানাবে; আমারঠিকানা উপযুক্ত অপশন খুঁজতে সহায়তা করবে।',
    [
      'এরিয়া, বাজেট ও পরিবারের প্রয়োজন',
      'পছন্দ অনুযায়ী মিল খুঁজে দেওয়া',
      'সহজ রিকোয়েস্ট ফর্ম',
    ],
  ),
  _ServiceItem(
    Icons.school_outlined,
    'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=900&q=80',
    'শিক্ষক সার্ভিস',
    'স্টুডেন্ট, অভিভাবক ও শিক্ষকদের জন্য সাবজেক্ট, ক্লাস, লোকেশন এবং অনলাইন/অফলাইন অনুযায়ী শিক্ষক খোঁজার সুবিধা।',
    [
      'সাবজেক্টভিত্তিক শিক্ষক প্রোফাইল',
      'অভিভাবকের রিকোয়েস্ট তালিকা',
      'অনলাইন ও অফলাইন টিউশন অপশন',
    ],
  ),
  _ServiceItem(
    Icons.local_shipping_outlined,
    'https://images.unsplash.com/photo-1580674285054-bed31e145f59?auto=format&fit=crop&w=900&q=80',
    'পিকআপ সার্ভিস',
    'বাসা বদল, মালামাল বহন, ছোট ডেলিভারি বা লোকাল ট্রান্সপোর্ট সাপোর্টের জন্য সহজ বুকিং ব্যবস্থা।',
    [
      'পিকআপ ও ড্রপ লোকেশন',
      'গাড়ির ধরন নির্বাচন',
      'সার্ভিস প্রোভাইডারের সাথে সংযোগ',
    ],
  ),
  _ServiceItem(
    Icons.shield_outlined,
    'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?auto=format&fit=crop&w=900&q=80',
    'সেফটি ও SOS',
    'জরুরি অবস্থায় দ্রুত যোগাযোগ, বিশ্বস্ত কন্টাক্ট, লোকেশন সাপোর্ট এবং সেফটি তথ্য দেখানোর জন্য বিশেষ সাপোর্ট সেকশন।',
    [
      'জরুরি যোগাযোগ মাধ্যম',
      'সেফটি অ্যালার্ট দেখানোর সুবিধা',
      'নিরাপদ সাপোর্ট মেসেজ',
    ],
  ),
];

final List<_GroceryItem> _groceries = [
  _GroceryItem(
    'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=900&q=80',
    'মিনিকেট চাল',
    'পরিবারের দৈনিক রান্নার জন্য পরিচ্ছন্ন প্যাকেট চাল।',
    'চাল',
    '৫ কেজি / ২৫ কেজি',
  ),
  _GroceryItem(
    'https://images.unsplash.com/photo-1515543904379-3d757afe72e4?auto=format&fit=crop&w=900&q=80',
    'মসুর ডাল',
    'ভালো মানের ডাল, খুচরা ও প্যাকেট দুইভাবেই দেখানো যাবে।',
    'ডাল',
    '১ কেজি',
  ),
  _GroceryItem(
    'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=900&q=80',
    'সয়াবিন তেল',
    'রান্নার জন্য জনপ্রিয় তেল, বোতলের আকার অনুযায়ী দেখা যাবে।',
    'তেল',
    '১ লিটার / ৫ লিটার',
  ),
  _GroceryItem(
    'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=900&q=80',
    'আটা ও ময়দা',
    'রুটি, পরোটা ও বেকারির নিত্যপ্রয়োজনীয় পণ্য হিসেবে রাখা হয়েছে।',
    'আটা',
    '২ কেজি / ৫ কেজি',
  ),
  _GroceryItem(
    'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=900&q=80',
    'হলুদ, মরিচ ও মসলা',
    'রান্নার মসলা আলাদা ক্যাটাগরি হিসেবে ক্রেতাকে দ্রুত বুঝতে সাহায্য করবে।',
    'মসলা',
    '১০০ গ্রাম / ২০০ গ্রাম',
  ),
  _GroceryItem(
    'https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?auto=format&fit=crop&w=900&q=80',
    'চা পাতা',
    'নিত্যদিনের চা, বাসার মাসিক বাজার এবং দোকানের অফার দেখানোর জন্য।',
    'চা',
    '২০০ গ্রাম / ৫০০ গ্রাম',
  ),
];

Widget buildLandingSectionTag(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: _LandingColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: _LandingColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class TenantLandingStatsSection extends StatelessWidget {
  const TenantLandingStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('6+', 'মূল সার্ভিস ক্যাটাগরি'),
      ('24/7', 'অনলাইন রিকোয়েস্ট সুবিধা'),
      ('1', 'সহজ ডিজিটাল প্ল্যাটফর্ম'),
    ];
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: stats
            .map(
              (s) => Column(
                children: [
                  Text(
                    s.$1,
                    style: const TextStyle(
                      color: _LandingColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 90,
                    child: Text(
                      s.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _LandingColors.textGrey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class TenantLandingServicesSection extends StatelessWidget {
  const TenantLandingServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLandingSectionTag('আমাদের সার্ভিস'),
          const SizedBox(height: 8),
          const Text(
            'প্রয়োজনীয় সার্ভিসগুলো একদম পরিষ্কার ও সুন্দরভাবে সাজানো',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'আপনি কী খুঁজছেন — বাসা, শিক্ষক, পিকআপ, সেফটি বা নিরাপদ ডিল — প্রতিটি সার্ভিস এখানে সহজভাবে ব্যাখ্যা করা আছে।',
            style: TextStyle(color: _LandingColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) => _serviceCard(_services[i]),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(_ServiceItem s) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              s.image,
              fit: BoxFit.cover,
              loadingBuilder: (c, child, progress) => progress == null
                  ? child
                  : Container(color: Colors.grey.shade200),
              errorBuilder: (c, e, str) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _LandingColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        s.icon,
                        color: _LandingColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  s.desc,
                  style: const TextStyle(
                    color: _LandingColors.textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ...s.points.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: _LandingColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text(
                    'এই সার্ভিস চাই →',
                    style: TextStyle(color: _LandingColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TenantLandingGrocerySection extends StatelessWidget {
  const TenantLandingGrocerySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLandingSectionTag('মুদী মালামাল'),
          const SizedBox(height: 8),
          const Text(
            'নিত্যপ্রয়োজনীয় মুদী পণ্য',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'চাল, ডাল, তেল, আটা, মসলা ও চায়ের মতো নিত্যপ্রয়োজনীয় পণ্যের ছবি ও ক্যাটাগরি এক জায়গায়।',
            style: TextStyle(color: _LandingColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _groceries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.65,
            ),
            itemBuilder: (context, i) => _groceryCard(_groceries[i]),
          ),
        ],
      ),
    );
  }

  Widget _groceryCard(_GroceryItem g) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: Image.network(
              g.image,
              fit: BoxFit.cover,
              loadingBuilder: (c, child, progress) => progress == null
                  ? child
                  : Container(color: Colors.grey.shade200),
              errorBuilder: (c, e, s) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      g.desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _LandingColors.textGrey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [_chip(g.tag), _chip(g.size)],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _LandingColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: _LandingColors.primaryDark),
      ),
    );
  }
}

class TenantLandingHowItWorksSection extends StatelessWidget {
  const TenantLandingHowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        '১',
        'সার্ভিস নির্বাচন',
        'আপনি প্রয়োজন অনুযায়ী ফ্ল্যাট, শিক্ষক, পিকআপ, SOS বা অন্য সার্ভিস নির্বাচন করবেন।',
      ),
      (
        '২',
        'রিকোয়েস্ট পাঠানো',
        'নাম, মোবাইল নম্বর, লোকেশন ও প্রয়োজনীয় তথ্য দিয়ে রিকোয়েস্ট সাবমিট করবেন।',
      ),
      (
        '৩',
        'যোগাযোগ ও সেবা নিশ্চিত করা',
        'দায়িত্বপ্রাপ্ত দল দ্রুত যোগাযোগ করে উপযুক্ত সমাধান দেবে।',
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLandingSectionTag('সহজ প্রক্রিয়া'),
          const SizedBox(height: 8),
          const Text(
            'কীভাবে আমারঠিকানা কাজ করে?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _LandingColors.primary,
                    child: Text(
                      s.$1,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.$2,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.$3,
                          style: const TextStyle(
                            color: _LandingColors.textGrey,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TenantLandingAudienceSection extends StatelessWidget {
  const TenantLandingAudienceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final audience = [
      (
        Icons.house_outlined,
        'বাড়িওয়ালা',
        'ফ্ল্যাট ভাড়া বা বিক্রির জন্য আগ্রহী ক্রেতা পাবেন।',
      ),
      (
        Icons.key_outlined,
        'ভাড়াটিয়া',
        'এরিয়া, বাজেট ও সুবিধা অনুযায়ী বাসা খুঁজতে পারবেন।',
      ),
      (
        Icons.menu_book_outlined,
        'শিক্ষক',
        'টিউশন প্রোফাইল তৈরি করে শিক্ষার্থী/অভিভাবকের রিকোয়েস্ট পাবেন।',
      ),
      (
        Icons.handshake_outlined,
        'সার্ভিস প্রোভাইডার',
        'পিকআপ, রিপেয়ার বা লোকাল সার্ভিস সুন্দরভাবে প্রমোট করতে পারবেন।',
      ),
      (
        Icons.person_outline,
        'সাধারণ ইউজার',
        'নিরাপদ ডিল, ফোন যাচাই ও SOS সাপোর্ট ব্যবহার করতে পারবেন।',
      ),
    ];
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLandingSectionTag('কারা ব্যবহার করবেন'),
          const SizedBox(height: 8),
          const Text(
            'কার জন্য আমারঠিকানা সবচেয়ে উপকারী?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: audience.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, i) {
              final a = audience[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(a.$1, color: _LandingColors.primary),
                    const SizedBox(height: 8),
                    Text(
                      a.$2,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.$3,
                      style: const TextStyle(
                        color: _LandingColors.textGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TenantLandingFaqSection extends StatelessWidget {
  const TenantLandingFaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      (
        'AmarThikanaa কোন ধরনের সার্ভিস দেয়?',
        'ফ্ল্যাট ভাড়া বা বিক্রি, বাসা খোঁজা, শিক্ষক, পিকআপ, জরুরি সহায়তা, নিরাপদ লেনদেন ও ফোন যাচাইয়ের সেবা এক জায়গায় দেওয়ার জন্য আমার ঠিকানা তৈরি।',
      ),
      (
        'আমি কীভাবে সার্ভিস রিকোয়েস্ট করব?',
        'নিচের ফর্মে আপনার নাম, মোবাইল নম্বর, সার্ভিসের ধরন এবং প্রয়োজনীয় Message লিখে সাবমিট করুন।',
      ),
      (
        'এটা কি মোবাইলে সুন্দরভাবে ব্যবহার করা যাবে?',
        'হ্যাঁ, এই পেজ মোবাইল, ট্যাবলেট ও ডেস্কটপ — সব স্ক্রিনে সুন্দরভাবে ব্যবহারযোগ্য।',
      ),
      (
        'সার্ভিস প্রোভাইডার হিসেবে আমি কীভাবে উপকার পাব?',
        'আপনার সার্ভিস সুন্দরভাবে উপস্থাপন হবে, আগ্রহী কাস্টমার ফর্ম পূরণ করবে, এবং আপনি সহজে যোগাযোগ করতে পারবেন।',
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLandingSectionTag('সাধারণ প্রশ্ন'),
          const SizedBox(height: 8),
          const Text(
            'সাধারণ প্রশ্নের সহজ উত্তর',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...faqs.map((f) => _faqTile(f.$1, f.$2)),
        ],
      ),
    );
  }

  Widget _faqTile(String q, String a) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          title: Text(
            q,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedAlignment: Alignment.topLeft,
          children: [
            Text(
              a,
              style: const TextStyle(
                color: _LandingColors.textGrey,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TenantLandingContactSection extends StatefulWidget {
  const TenantLandingContactSection({super.key});

  @override
  State<TenantLandingContactSection> createState() =>
      _TenantLandingContactSectionState();
}

class _TenantLandingContactSectionState
    extends State<TenantLandingContactSection> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedService;

  final List<String> serviceOptions = [
    'ফ্ল্যাট ভাড়া',
    'ফ্ল্যাট বিক্রি',
    'বাসা খোঁজা',
    'শিক্ষক সার্ভিস',
    'পিকআপ সার্ভিস',
    'সেফটি ও SOS',
    'নিরাপদ লেনদেন',
    'ডিজিটাল বাজার',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _LandingColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'যোগাযোগ',
            style: TextStyle(
              color: _LandingColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'আপনার প্রয়োজনীয় সার্ভিসের জন্য এখনই রিকোয়েস্ট করুন',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'নাম, মোবাইল নম্বর, সার্ভিস এবং আপনার প্রয়োজন সংক্ষেপে লিখুন। আমরা দ্রুত যোগাযোগ করব।',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _textField('নাম'),
                  const SizedBox(height: 12),
                  _textField('মোবাইল নম্বর', keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedService,
                    decoration: _inputDecoration('সার্ভিস নির্বাচন করুন'),
                    items: serviceOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedService = v),
                  ),
                  const SizedBox(height: 12),
                  _textField('লোকেশন'),
                  const SizedBox(height: 12),
                  _textField('আপনার প্রয়োজন', maxLines: 4),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('রিকোয়েস্ট পাঠানো হয়েছে!'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _LandingColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('রিকোয়েস্ট পাঠান'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _LandingColors.bgLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _textField(
    String label, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: _inputDecoration(label),
      validator: (v) => (v == null || v.isEmpty) ? '$label আবশ্যক' : null,
    );
  }
}

class TenantLandingFooterSection extends StatelessWidget {
  const TenantLandingFooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _LandingColors.textDark,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'আমারঠিকানা',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'বাসা, সার্ভিস ও নিরাপদ লেনদেনের স্মার্ট ঠিকানা',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children:
                [
                      'সার্ভিস',
                      'মুদী মালামাল',
                      'কীভাবে কাজ করে',
                      'সাধারণ প্রশ্ন',
                      'যোগাযোগ',
                    ]
                    .map(
                      (t) => Text(
                        t,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Text(
            '© ${DateTime.now().year} আমারঠিকানা. সর্বস্বত্ব সংরক্ষিত।',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
