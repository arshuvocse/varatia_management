import 'package:flutter/material.dart';

class PhoneVerificationInfoScreen extends StatelessWidget {
  const PhoneVerificationInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'মোবাইল ফোন ভেরিফাই সার্ভিস',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF0F6AA8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(),
            _buildWhyVerifySection(),
            _buildFeatureGrid(),
            _buildProcessSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // Action to go to the actual verification form
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ভেরিফাই ফর্ম ওপেন হচ্ছে...')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F6AA8),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'এখনই ভেরিফাই করুন',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F6AA8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: const Column(
        children: [
          Icon(Icons.verified_user, color: Colors.white, size: 64),
          SizedBox(height: 16),
          Text(
            'আপনার ফোন নিরাপদ তো?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'ফোন কেনার আগে একবার ভেরিফাই করে নিন, নিরাপদ থাকুন!',
            style: TextStyle(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWhyVerifySection() {
    final reasons = [
      'চোরা ফোন থেকে নিরাপদ থাকুন',
      'মামলার ঝামেলা থেকে বাঁচুন',
      'কিস্তির বাকি আছে কি না জানুন',
      'আসল মালিক কে জানুন',
      'নিরাপদ লেনদেনে নিশ্চিত থাকুন',
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'কেন ফোন ভেরিফাই করবেন?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F6AA8),
                ),
              ),
              const SizedBox(height: 12),
              ...reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {
        'title': 'চোরা / হারানো চেক',
        'subtitle': 'ফোন চুরি বা হারানো কিনা তাৎক্ষনিক যাচাই করুন',
        'icon': Icons.admin_panel_settings,
      },
      {
        'title': 'মামলার তথ্য',
        'subtitle': 'ফোনের বিরুদ্ধে কোনো মামলা আছে কিনা জানুন',
        'icon': Icons.gavel,
      },
      {
        'title': 'কিস্তির তথ্য',
        'subtitle': 'কিস্তির ফোন কিনা ও কতটি কিস্তি বাকি আছে দেখুন',
        'icon': Icons.credit_card,
      },
      {
        'title': 'পরিশোধ অবস্থা',
        'subtitle': 'কিস্তি পরিশোধ নিয়মিত হচ্ছে কিনা যাচাই করুন',
        'icon': Icons.receipt_long,
      },
      {
        'title': 'বর্তমান কন্ডিশন',
        'subtitle': 'ফোনের বর্তমান অবস্থা (নতুন/ব্যবহৃত) জানুন',
        'icon': Icons.smartphone,
      },
      {
        'title': 'ওনারশিপ যাচাই',
        'subtitle': 'আসল মালিকের তথ্য যাচাই করুন',
        'icon': Icons.person_search,
      },
      {
        'title': 'ওনারশিপ পরিবর্তন',
        'subtitle': 'সহজেই ওনারশিপ পরিবর্তন করুন',
        'icon': Icons.swap_horiz,
      },
      {
        'title': 'বাই / সেল স্ট্যাটাস',
        'subtitle': 'বাজারে বিক্রয়যোগ্য কিনা জানুন',
        'icon': Icons.shopping_cart_checkout,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'যেসব তথ্য পাবেন',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F6AA8),
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final feature = features[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      feature['icon'] as IconData,
                      size: 36,
                      color: const Color(0xFF0F6AA8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      feature['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      feature['subtitle'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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

  Widget _buildProcessSection() {
    final steps = [
      {'title': 'ফোনের IMEI দিন', 'icon': Icons.phone_android},
      {'title': 'সিস্টেম যাচাই', 'icon': Icons.cloud_sync},
      {'title': 'রিপোর্ট প্রস্তুত', 'icon': Icons.assignment},
      {'title': 'নিশ্চিত হয়ে কিনুন', 'icon': Icons.handshake},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFFEAF4FF),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'আমাদের কাজের পদ্ধতি',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F6AA8),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(steps.length * 2 - 1, (index) {
                  if (index % 2 != 0) {
                    // Arrow
                    return const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  final stepIndex = index ~/ 2;
                  final step = steps[stepIndex];

                  return Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            step['icon'] as IconData,
                            color: const Color(0xFF0F6AA8),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
