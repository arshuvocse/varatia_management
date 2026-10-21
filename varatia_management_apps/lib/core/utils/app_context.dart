import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/app_view_models.dart';
import 'app_language.dart';
import 'bangla_formatter.dart';
import 'local_lang.dart';

const Map<String, String> _demoBanglaTextMap = {
  'Occupied': 'দখলকৃত',
  'Vacant': 'খালি',
  'Paid': 'পরিশোধিত',
  'Due': 'বকেয়া',
  'Image placeholder': 'ছবির স্থানধারক',
  'Due Date': 'নির্ধারিত তারিখ',
  'Add New': 'নতুন যোগ করুন',
  'Reject request': 'রিকোয়েস্ট বাতিল',
  'Approve request': 'রিকোয়েস্ট অনুমোদন',
  'Send Bill to Tenant': 'টেন্যান্টকে বিল পাঠান',
  'Total Users': 'মোট ইউজার',
  'Active Listings': 'সক্রিয় লিস্টিং',
  'Pending Approvals': 'অনুমোদনের অপেক্ষায়',
  'Monthly Revenue': 'মাসিক আয়',
  'submitted rent payment for April': 'এপ্রিল মাসের ভাড়া পরিশোধ করেছে',
  'requested owner verification': 'মালিক যাচাইকরণের অনুরোধ করেছে',
  'listed a new 3-bed apartment': 'নতুন ৩ বেড অ্যাপার্টমেন্ট লিস্ট করেছে',
  'downloaded receipt archive': 'রসিদের আর্কাইভ ডাউনলোড করেছে',
  'updated tenant profile details': 'টেন্যান্ট প্রোফাইলের তথ্য আপডেট করেছে',
  'Owner': 'মালিক',
  'Quick Post Options': 'দ্রুত পোস্ট অপশন',
  'Rent Listing': 'ভাড়ার লিস্টিং',
  'Post a flat, family unit, or bachelor listing.':
      'ফ্ল্যাট, ফ্যামিলি ইউনিট বা ব্যাচেলর লিস্টিং পোস্ট করুন।',
  'Sale Listing': 'বিক্রির লিস্টিং',
  'Post apartments, land, or ready properties for sale.':
      'অ্যাপার্টমেন্ট, জমি বা রেডি প্রপার্টি বিক্রির জন্য পোস্ট করুন।',
  'My Posts': 'আমার পোস্ট',
  'Review, edit, and boost your existing posts.':
      'আপনার পোস্ট দেখুন, এডিট করুন এবং বুস্ট করুন।',
  'Flat': 'ফ্ল্যাট',
  'Sublet': 'সাবলেট',
  'Hostel': 'হোস্টেল',
  'Office': 'অফিস',
  'New Post': 'নতুন পোস্ট',
  'Rent listing': 'ভাড়ার লিস্টিং',
  'Sale listing': 'বিক্রির লিস্টিং',
  'Create listing': 'লিস্টিং তৈরি',
  'Published': 'প্রকাশিত',
  'Drafts': 'খসড়া',
  'Inquiries': 'জিজ্ঞাসা',
  'Before You Publish': 'পাবলিশের আগে',
  'Quick Actions': 'দ্রুত অ্যাকশন',
  'Create Rent Post': 'ভাড়ার পোস্ট তৈরি করুন',
  'Open the composer for family or bachelor listings.':
      'ফ্যামিলি বা ব্যাচেলর লিস্টিংয়ের জন্য ফর্ম খুলুন।',
  'Create Sale Post': 'বিক্রির পোস্ট তৈরি করুন',
  'Start a sale post for apartments or ready properties.':
      'অ্যাপার্টমেন্ট বা রেডি প্রপার্টির জন্য বিক্রির পোস্ট শুরু করুন।',
  'Manage My Posts': 'আমার পোস্ট ম্যানেজ করুন',
  'Edit, renew, and track the status of your posts.':
      'আপনার পোস্ট এডিট, রিনিউ এবং স্ট্যাটাস দেখুন।',
  'Create Post': 'পোস্ট করুন',
  'Your active posts': 'আপনার সক্রিয় পোস্ট',
  'Manage post status, responses, and recent updates from one place.':
      'এক জায়গা থেকে পোস্টের স্ট্যাটাস, রেসপন্স ও আপডেট ম্যানেজ করুন।',
  'View My Posts': 'আমার পোস্ট দেখুন',
  'Saved': 'সেভড',
  'Menu': 'মেনু',
  'Access profile, payment, and support tools.':
      'প্রোফাইল, পেমেন্ট ও সাপোর্ট টুলস ব্যবহার করুন।',
  'Tenant Account': 'টেন্যান্ট অ্যাকাউন্ট',
  'Tenant Menu': 'টেন্যান্ট মেনু',
  'Owner Menu': 'মালিকের মেনু',
  'Owner Info': 'মালিকের তথ্য',
  'Owner Payment Info': 'মালিকের পেমেন্ট তথ্য',
  'My Profile': 'আমার প্রোফাইল',
  'Tenant Info': 'ভাড়াটিয়ার তথ্য',
  'Tenant Wise Payment Info': 'ভাড়াটিয়া অনুযায়ী পেমেন্ট তথ্য',
  'Send Monthly Bill': 'মাসিক বিল পাঠান',
  'Property List': 'প্রপার্টি তালিকা',
  'Reports': 'রিপোর্ট',
  'Settings': 'সেটিংস',
  'Owner Settings': 'মালিকের সেটিংস',
  'Tenant ID': 'ভাড়াটিয়া আইডি',
  'Phone': 'ফোন',
  'Due Amount': 'বকেয়া পরিমাণ',
  'No property assigned': 'কোনো প্রপার্টি দেওয়া হয়নি',
  'Not set': 'সেট করা হয়নি',
  'Property Owner': 'প্রপার্টি মালিক',
  'Payment & Agreement': 'পেমেন্ট ও চুক্তি',
  'Open payment details and generate agreement.':
      'পেমেন্ট ডিটেইলস খুলুন এবং চুক্তি তৈরি করুন।',
  'Monthly Bills': 'মাসিক বিল',
  'Review current monthly utility and service bills.':
      'চলতি মাসের ইউটিলিটি ও সার্ভিস বিল দেখুন।',
  'Manager Details': 'ম্যানেজার ডিটেইলস',
  'Check manager profile and total outstanding charges.':
      'ম্যানেজার প্রোফাইল ও মোট বকেয়া চার্জ দেখুন।',
  'Tutor Teach / Learn': 'শিক্ষক দিচ্ছি / নিচ্ছি',
  'Tutor Profile': 'শিক্ষকের প্রোফাইল',
  'Need Tutor': 'শিক্ষক চাই',
  'Owner Profile': 'মালিকের প্রোফাইল',
  'View owner contact options and selected listing.':
      'মালিকের যোগাযোগ অপশন ও নির্বাচিত লিস্টিং দেখুন।',
  'Confirm Move-In': 'মুভ-ইন নিশ্চিত করুন',
  'Open move-in confirmation and support shortcuts.':
      'মুভ-ইন কনফার্মেশন ও সাপোর্ট শর্টকাট খুলুন।',
  'Maintenance Request': 'রক্ষণাবেক্ষণ অনুরোধ',
  'Report plumbing, electrical, and other issues.':
      'প্লাম্বিং, ইলেকট্রিক্যাল ও অন্যান্য সমস্যা জানান।',
  'Payment History': 'পেমেন্ট হিস্টোরি',
  'Track rent receipts and prepare your next payment.':
      'ভাড়ার রসিদ দেখুন এবং পরের পেমেন্ট প্রস্তুত করুন।',
  'History': 'হিস্টোরি',
  'Total paid this year': 'এ বছর মোট পরিশোধ',
  'Payment Methods': 'পেমেন্ট পদ্ধতি',
  'Category': 'ক্যাটাগরি',
  'Describe your issue': 'আপনার সমস্যার বর্ণনা দিন',
  'Take Photo': 'ছবি তুলুন',
  'Send to Owner': 'মালিককে পাঠান',
  'Profile': 'প্রোফাইল',
  'Personal summary and access to tenant tools.':
      'ব্যক্তিগত সারাংশ ও টেন্যান্ট টুলসের অ্যাক্সেস।',
  'Tenant': 'টেন্যান্ট',
  'Action': 'অ্যাকশন',
  'Edit post': 'পোস্ট এডিট',
  'Edit': 'এডিট',
  'Boost post': 'পোস্ট বুস্ট',
  'Boost': 'বুস্ট',
  'Download PDF': 'পিডিএফ ডাউনলোড',
  'Payment': 'পেমেন্ট',
  'Generate Agreement': 'চুক্তি তৈরি করুন',
  'Payment due': 'পেমেন্ট বাকি',
  'Digital Signature': 'ডিজিটাল স্বাক্ষর',
  'Authorized by tenant and owner': 'টেন্যান্ট ও মালিক কর্তৃক অনুমোদিত',
  'Agreement Preview': 'চুক্তির প্রিভিউ',
  'Review Final Document': 'চূড়ান্ত ডকুমেন্ট দেখুন',
  'Draft ready': 'খসড়া প্রস্তুত',
  'Agreement': 'চুক্তি',
  'Create Agreement': 'চুক্তি তৈরি করুন',
  'Agreement approved': 'চুক্তি অনুমোদিত',
  'This agreement confirms the rental terms between tenant and owner for the selected property.':
      'এই চুক্তিটি নির্বাচিত প্রপার্টির জন্য টেন্যান্ট ও মালিকের ভাড়ার শর্ত নিশ্চিত করে।',
  'Pay Now': 'এখনই পরিশোধ করুন',
  'Agreement Created!': 'চুক্তি তৈরি হয়েছে!',
  'Your agreement has been generated. Download the PDF or continue to payment.':
      'আপনার চুক্তি তৈরি হয়েছে। পিডিএফ ডাউনলোড করুন অথবা পেমেন্টে এগিয়ে যান।',
  'Continue': 'চালিয়ে যান',
  'View Rent': 'ভাড়া দেখুন',
  'Messages': 'মেসেজ',
  'Pay Owner': 'মালিককে পরিশোধ করুন',
  'Total': 'মোট',
  'Property active': 'প্রপার্টি সক্রিয়',
  'Verified owner': 'যাচাইকৃত মালিক',
  'Tenant Confirm Move-In': 'টেন্যান্ট মুভ-ইন নিশ্চিতকরণ',
  'Move-in pending': 'মুভ-ইন অপেক্ষমান',
  'Assisting Broker': 'সহায়ক ব্রোকার',
  'Signature authorized': 'স্বাক্ষর অনুমোদিত',
  'Signature': 'স্বাক্ষর',
  '2 Bed Flat - Mirpur 10': '২ বেড ফ্ল্যাট - মিরপুর ১০',
  '3 Bed Apartment - Dhanmondi': '৩ বেড অ্যাপার্টমেন্ট - ধানমন্ডি',
  'Family Flat - Uttara': 'ফ্যামিলি ফ্ল্যাট - উত্তরা',
  'Luxury Apartment - Gulshan': 'লাক্সারি অ্যাপার্টমেন্ট - গুলশান',
  "Bachelor Flat - Agrabad": 'ব্যাচেলর ফ্ল্যাট - আগ্রাবাদ',
  "Sea View Apartment - Cox's Bazar": 'সি ভিউ অ্যাপার্টমেন্ট - কক্সবাজার',
  'For Rent': 'ভাড়ার জন্য',
  'For Sale': 'বিক্রয়ের জন্য',
  '/ month': '/ মাস',
  'Family': 'ফ্যামিলি',
  'Bachelor': 'ব্যাচেলর',
  'Ready Flat': 'রেডি ফ্ল্যাট',
  'Apartment': 'অ্যাপার্টমেন্ট',
  'Commercial': 'কমার্শিয়াল',
  'Family or bachelor listing': 'ফ্যামিলি বা ব্যাচেলর লিস্টিং',
  'Shared or furnished setup': 'শেয়ারড বা ফার্নিশড সেটআপ',
  'Seat-based accommodation': 'সিটভিত্তিক থাকা',
  'Commercial workspace': 'বাণিজ্যিক কর্মস্থল',
  'Property photos': 'প্রপার্টির ছবি',
  'Add front view and room photos for better reach.':
      'ভালো রিচের জন্য সামনের ভিউ ও রুমের ছবি যোগ করুন।',
  'Location details': 'লোকেশন ডিটেইলস',
  'Mention area, road, and nearby landmark clearly.':
      'এলাকা, রাস্তা ও কাছের ল্যান্ডমার্ক পরিষ্কারভাবে লিখুন।',
  'Price and rules': 'দাম ও নিয়ম',
  'Share rent, advance, and preferred tenant details.':
      'ভাড়া, অগ্রিম ও পছন্দের টেন্যান্টের তথ্য দিন।',
  'Under Review': 'পর্যালোচনাধীন',
  'Draft': 'খসড়া',
  'Updated 2h ago': '২ ঘণ্টা আগে আপডেট',
  'Updated yesterday': 'গতকাল আপডেট',
  'Saved 3 days ago': '৩ দিন আগে সেভ করা',
  'Mirpur 10, Dhaka': 'মিরপুর ১০, ঢাকা',
  'Active Tenant': 'সক্রিয় ভাড়াটিয়া',
  'Flat Owner • Dhanmondi': 'ফ্ল্যাট মালিক • ধানমন্ডি',
  'Property Manager • Mirpur': 'প্রপার্টি ম্যানেজার • মিরপুর',
  'Manager': 'ম্যানেজার',
  'Move-in Assistant': 'মুভ-ইন সহকারী',
  'Support': 'সাপোর্ট',
  'Plumbing': 'প্লাম্বিং',
  'Electrical': 'ইলেকট্রিক্যাল',
  'Cleaning': 'পরিষ্কার-পরিচ্ছন্নতা',
  'Others': 'অন্যান্য',
  'Rent': 'ভাড়া',
  'Advance Payment': 'অগ্রিম পরিশোধ',
  'Due on 05 Mar': '০৫ মার্চ প্রদেয়',
  'Paid on 01 Mar': '০১ মার্চ পরিশোধিত',
  'Duration': 'মেয়াদ',
  '11 months': '১১ মাস',
  'Renewable': 'নবায়নযোগ্য',
  'Utility Deposit': 'ইউটিলিটি ডিপোজিট',
  'Refundable': 'ফেরতযোগ্য',
  'Property': 'প্রপার্টি',
  'Floor 4B, Road 12': '৪বি তলা, রোড ১২',
  'NID verified': 'এনআইডি যাচাইকৃত',
  'Verified profile': 'যাচাইকৃত প্রোফাইল',
  'Monthly Rent': 'মাসিক ভাড়া',
  'Service charge included': 'সার্ভিস চার্জ অন্তর্ভুক্ত',
  'Advance': 'অগ্রিম',
  '3 months equivalent': '৩ মাসের সমপরিমাণ',
  'Move-in': 'মুভ-ইন',
  '01 March 2026': '০১ মার্চ ২০২৬',
  'Agreement period active': 'চুক্তির মেয়াদ সক্রিয়',
  'Electricity Bill': 'বিদ্যুৎ বিল',
  'Water Bills': 'পানির বিল',
  'Gas Bill': 'গ্যাস বিল',
  'Security Guard': 'সিকিউরিটি গার্ড',
  'Other Charges': 'অন্যান্য চার্জ',
  'Call Room': 'কল করুন',
  'WhatsApp': 'হোয়াটসঅ্যাপ',
  'Location': 'লোকেশন',
  'Chat': 'চ্যাট',
  'Call': 'কল',
  'Search': 'সার্চ',
  'Newest': 'নতুন',
  'See all': 'সব দেখুন',
  'All': 'সব',
  'No matching listings': 'মিলে এমন লিস্টিং পাওয়া যায়নি',
  'Try another keyword or clear the search.':
      'অন্য কীওয়ার্ড ব্যবহার করুন বা সার্চ পরিষ্কার করুন।',
  'Filter by location': 'লোকেশন দিয়ে ফিল্টার করুন',
  'Reset': 'রিসেট',
  'Show results': 'ফলাফল দেখুন',
  'Division': 'বিভাগ',
  'District': 'জেলা',
  'Upazila': 'উপজেলা',
  'Select division': 'বিভাগ নির্বাচন করুন',
  'Select division first': 'আগে বিভাগ নির্বাচন করুন',
  'Select district': 'জেলা নির্বাচন করুন',
  'Select district first': 'আগে জেলা নির্বাচন করুন',
  'Select upazila': 'উপজেলা নির্বাচন করুন',
  'Floor 1': '১ম তলা',
  'Floor 2': '২য় তলা',
  'Floor 3': '৩য় তলা',
  'Floor 4': '৪র্থ তলা',
  'Floor 5': '৫ম তলা',
  'Nov': 'নভে',
  'Dec': 'ডিসে',
  'Jan': 'জানু',
  'Feb': 'ফেব্রু',
  'Mar': 'মার্চ',
  'Apr': 'এপ্রিল',
  'Rent Payment': 'ভাড়া পরিশোধ',
  'Submit rent payment and view payment entries.':
      'ভাড়ার পেমেন্ট জমা দিন এবং এন্ট্রি তালিকা দেখুন।',
  'Payment Confirmed': 'পেমেন্ট নিশ্চিত হয়েছে',
  'Your rent payment has been confirmed and added to the list.':
      'আপনার পেমেন্ট নিশ্চিত হয়েছে এবং তালিকায় যোগ হয়েছে।',
  'OK': 'ঠিক আছে',
  'Select a payment type': 'পেমেন্টের ধরন নির্বাচন করুন',
  'Enter owner, month, year, payment type, and method.':
      'মালিক, মাস, বছর, পেমেন্টের ধরন এবং পদ্ধতি লিখুন।',
  'Payment Entry': 'পেমেন্ট এন্ট্রি',
  'Owner Name': 'মালিকের নাম',
  'Enter owner name': 'মালিকের নাম লিখুন',
  'Month': 'মাস',
  'Year': 'বছর',
  'Payment Type': 'পেমেন্টের ধরন',
  'Rent Amount': 'ভাড়ার পরিমাণ',
  'Enter a valid rent amount': 'সঠিক ভাড়ার পরিমাণ লিখুন',
  'Payment Method': 'পেমেন্ট পদ্ধতি',
  'Payment List': 'পেমেন্ট তালিকা',
  'No payment entries yet.': 'এখনো কোনো পেমেন্ট এন্ট্রি নেই।',
  'Vara': 'ভাড়া',
  'Utility Bill': 'ইউটিলিটি বিল',
  'Pani Bill': 'পানি বিল',
  'Cash': 'ক্যাশ',
  'bKash': 'বিকাশ',
  'Nagad': 'নগদ',
  'Rocket': 'রকেট',
  'January': 'জানুয়ারি',
  'February': 'ফেব্রুয়ারি',
  'March': 'মার্চ',
  'April': 'এপ্রিল',
  'May': 'মে',
  'June': 'জুন',
  'July': 'জুলাই',
  'August': 'আগস্ট',
  'September': 'সেপ্টেম্বর',
  'October': 'অক্টোবর',
  'November': 'নভেম্বর',
  'December': 'ডিসেম্বর',
  'English': 'ইংরেজি',
};

extension AppContextX on BuildContext {
  AppLanguage get appLanguage => read<SettingsViewModel>().language;

  bool get isBangla => appLanguage == AppLanguage.bangla;

  String tr({required String bn, required String en}) {
    return isBangla ? bn : en;
  }

  String loc(LocalizedText text) {
    return isBangla ? text.bn : text.en;
  }

  String demoText(String text) {
    final normalized = text.replaceAll('â€¢', '•');

    if (!isBangla) {
      return normalized;
    }

    return _demoBanglaTextMap[normalized] ?? normalized;
  }

  String money(num value) {
    return BanglaFormatter.taka(value, bangla: isBangla);
  }

  String digitsText(num value) {
    return BanglaFormatter.digits(value, bangla: isBangla);
  }

  String shortDateText(DateTime value) {
    return BanglaFormatter.shortDate(value, bangla: isBangla);
  }

  String fullDateText(DateTime value) {
    return BanglaFormatter.fullDate(value, bangla: isBangla);
  }
}
