import 'package:flutter/material.dart';
import 'package:varatia_management_apps/core/utils/app_context.dart';
import 'package:varatia_management_apps/core/theme/app_theme.dart';

import 'package:varatia_management_apps/views/screens/home/tenant_home_screen.dart';
import 'package:varatia_management_apps/views/screens/home/tenant_general_post_chat_page.dart';
import 'package:varatia_management_apps/views/screens/home/tenant_general_post_call_page.dart';

class TenantGeneralPostDetailsScreen extends StatelessWidget {
  const TenantGeneralPostDetailsScreen({super.key, required this.listing});

  final TenantShowcaseListingData listing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: Text(context.tr(bn: 'বিস্তারিত', en: 'Details')),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: listing.imageUrl != null
                ? Image.network(
                    listing.imageUrl!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        ListingArtwork(style: listing.artworkStyle),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        width: double.infinity,
                        color: const Color(0xFFF0F2F5),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  )
                : Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: ListingArtwork(style: listing.artworkStyle),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            context.loc(listing.title),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.loc(listing.price),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (listing.rawPost?.advance != null &&
                  listing.rawPost!.advance! > 0)
                Text(
                  'অ্যাডভান্স: ৳${listing.rawPost!.advance}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  (listing.rawPost?.fullAddress?.isNotEmpty ?? false)
                      ? listing.rawPost!.fullAddress!
                      : context.loc(listing.location),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _buildFeatureItem(
                context,
                Icons.bed_outlined,
                '${listing.bedrooms} বেড',
              ),
              _buildFeatureItem(
                context,
                Icons.bathtub_outlined,
                '${listing.bathrooms} বাথ',
              ),
              if (listing.rawPost != null)
                _buildFeatureItem(
                  context,
                  Icons.kitchen_outlined,
                  '${listing.rawPost!.kitchens} কিচেন',
                ),
              if (listing.rawPost != null)
                _buildFeatureItem(
                  context,
                  Icons.balcony_outlined,
                  '${listing.rawPost!.balconies} বারান্দা',
                ),
              _buildFeatureItem(
                context,
                Icons.square_foot_outlined,
                '${listing.areaSqft} sqft',
              ),
            ],
          ),
          if (listing.rawPost != null &&
              (listing.rawPost!.hasGas ||
                  listing.rawPost!.hasLift ||
                  listing.rawPost!.hasGenerator ||
                  listing.rawPost!.hasParking)) ...[
            const SizedBox(height: 24),
            Text(
              context.tr(bn: 'সুযোগ সুবিধা', en: 'Amenities'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (listing.rawPost!.hasGas)
                  _buildChip(context.tr(bn: 'গ্যাস', en: 'Gas')),
                if (listing.rawPost!.hasLift)
                  _buildChip(context.tr(bn: 'লিফট', en: 'Lift')),
                if (listing.rawPost!.hasGenerator)
                  _buildChip(context.tr(bn: 'জেনারেটর', en: 'Generator')),
                if (listing.rawPost!.hasParking)
                  _buildChip(context.tr(bn: 'পার্কিং', en: 'Parking')),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text(
            context.tr(bn: 'বিবরণ', en: 'Description'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            (listing.rawPost?.description?.isNotEmpty ?? false)
                ? listing.rawPost!.description!
                : context.tr(
                    bn: 'এখানে কোনো বিবরণ নেই। আরও তথ্যের জন্য মালিকের সাথে যোগাযোগ করুন।',
                    en: 'No detailed description available. Please contact the owner for more information.',
                  ),
            style: const TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showContactOptions(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.tr(bn: 'যোগাযোগ করুন', en: 'Contact Owner')),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(
                  bn: 'যোগাযোগের মাধ্যম বেছে নিন',
                  en: 'Choose Contact Method',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.surfaceSoft,
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  context.tr(bn: 'মেসেজ / চ্যাট করুন', en: 'Message / Chat'),
                ),
                subtitle: Text(
                  context.tr(
                    bn: 'অ্যাপের মাধ্যমে সরাসরি মেসেজ দিন',
                    en: 'Send direct message via app',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TenantGeneralPostChatPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: const Icon(
                    Icons.call_outlined,
                    color: AppColors.success,
                  ),
                ),
                title: Text(context.tr(bn: 'অডিও কল করুন', en: 'Audio Call')),
                subtitle: Text(
                  context.tr(
                    bn: 'অ্যাপের মাধ্যমে কল করুন',
                    en: 'Make a call via app',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TenantGeneralPostCallPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textMuted),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.surfaceSoft,
      side: BorderSide.none,
      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
    );
  }
}
