import 'package:flutter/foundation.dart';

@immutable
class LocalizedText {
  const LocalizedText({required this.bn, required this.en});

  final String bn;
  final String en;
}

abstract final class AppLocalLang {
  static const home = LocalizedText(bn: 'হোম', en: 'Home');
  static const search = LocalizedText(bn: 'সার্চ', en: 'Search');
  static const post = LocalizedText(bn: 'পোস্ট', en: 'Post');
  static const saved = LocalizedText(bn: 'সেভড', en: 'Saved');
  static const menu = LocalizedText(bn: 'মেনু', en: 'Menu');
  static const users = LocalizedText(bn: 'ইউজার', en: 'Users');
  static const settings = LocalizedText(bn: 'সেটিংস', en: 'Settings');
  static const payments = LocalizedText(bn: 'পেমেন্ট', en: 'Payments');
  static const tenants = LocalizedText(bn: 'টেন্যান্ট', en: 'Tenants');
  static const profile = LocalizedText(bn: 'প্রোফাইল', en: 'Profile');

  static const adminRole = LocalizedText(bn: 'অ্যাডমিন', en: 'Admin');
  static const propertyOwnerRole = LocalizedText(
    bn: 'প্রপার্টি মালিক',
    en: 'Property Owner',
  );
  static const tenantRole = LocalizedText(bn: 'ভাড়াটিয়া', en: 'Tenant');

  static const adminRoleSubtitle = LocalizedText(
    bn: 'এক জায়গা থেকে ইউজার, অনুমোদন ও আয়ের হিসাব দেখুন।',
    en: 'Monitor users, approvals, and revenue in one place.',
  );
  static const ownerRoleSubtitle = LocalizedText(
    bn: 'প্রপার্টি, বিলিং, টেন্যান্ট ও প্রোফাইল টুলস ম্যানেজ করুন।',
    en: 'Manage properties, billing, tenants, and profile tools.',
  );
  static const tenantRoleSubtitle = LocalizedText(
    bn: 'লিস্টিং খুঁজুন, ভাড়া পরিশোধ করুন এবং মেইনটেন্যান্স রিকোয়েস্ট পাঠান।',
    en: 'Explore listings, pay rent, and send maintenance requests.',
  );

  static const openAdminDashboard = LocalizedText(
    bn: 'অ্যাডমিন ড্যাশবোর্ড খুলুন',
    en: 'Open Admin Dashboard',
  );
  static const openOwnerWorkspace = LocalizedText(
    bn: 'ওনার ওয়ার্কস্পেস খুলুন',
    en: 'Open Owner Workspace',
  );
  static const openTenantApp = LocalizedText(
    bn: 'টেন্যান্ট অ্যাপ খুলুন',
    en: 'Open Tenant App',
  );

  static const adminControl = LocalizedText(
    bn: 'অ্যাডমিন কন্ট্রোল',
    en: 'Admin Control',
  );
  static const adminControlSubtitle = LocalizedText(
    bn: 'ইউজার, লিস্টিং, অনুমোদন ও আয়ের সারসংক্ষেপ দেখুন।',
    en: 'Overview of users, listings, approvals, and revenue.',
  );
  static const recentActivity = LocalizedText(
    bn: 'সাম্প্রতিক কার্যক্রম',
    en: 'Recent Activity',
  );
  static const verificationRequest = LocalizedText(
    bn: 'ভেরিফিকেশন রিকোয়েস্ট',
    en: 'Verification Request',
  );
  static const verificationRequestSubtitle = LocalizedText(
    bn: 'পরিচয় তথ্য ও সংযুক্ত ডকুমেন্ট পর্যালোচনা করুন।',
    en: 'Review identity details and attached documents.',
  );
  static const userInfo = LocalizedText(bn: 'ইউজার তথ্য', en: 'User Info');
  static const documents = LocalizedText(bn: 'ডকুমেন্টস', en: 'Documents');
  static const nidFront = LocalizedText(
    bn: 'এনআইডি সামনের দিক',
    en: 'NID Front',
  );
  static const nidBack = LocalizedText(bn: 'এনআইডি পিছনের দিক', en: 'NID Back');
  static const reject = LocalizedText(bn: 'রিজেক্ট', en: 'Reject');
  static const approve = LocalizedText(bn: 'অ্যাপ্রুভ', en: 'Approve');
  static const adminSettingsSubtitle = LocalizedText(
    bn: 'অ্যাডমিন কন্ট্রোল ও দ্রুত পছন্দগুলো ম্যানেজ করুন।',
    en: 'Administrative controls and quick preferences.',
  );
  static const controlCenter = LocalizedText(
    bn: 'কন্ট্রোল সেন্টার',
    en: 'Control Center',
  );
  static const userModeration = LocalizedText(
    bn: 'ইউজার মডারেশন',
    en: 'User moderation',
  );
  static const userModerationSubtitle = LocalizedText(
    bn: 'অ্যাকাউন্ট অনুমোদন ও স্ট্যাটাস পরিবর্তন ম্যানেজ করুন।',
    en: 'Manage account approvals and status changes.',
  );
  static const revenueReports = LocalizedText(
    bn: 'রেভিনিউ রিপোর্ট',
    en: 'Revenue reports',
  );
  static const revenueReportsSubtitle = LocalizedText(
    bn: 'মাসিক রেভিনিউ এক্সপোর্ট ও সারসংক্ষেপ দেখুন।',
    en: 'Access monthly revenue exports and summaries.',
  );
  static const systemAlerts = LocalizedText(
    bn: 'সিস্টেম অ্যালার্ট',
    en: 'System alerts',
  );
  static const systemAlertsSubtitle = LocalizedText(
    bn: 'লেনদেন ও ভেরিফিকেশন অ্যালার্ট চালু রাখুন।',
    en: 'Keep transaction and verification alerts enabled.',
  );

  static const myProperties = LocalizedText(
    bn: 'আমার প্রপার্টি',
    en: 'My Properties',
  );
  static const myPropertiesSubtitle = LocalizedText(
    bn: 'সব লিস্টেড ইউনিটের দখল ও আয়ের হিসাব ট্র্যাক করুন।',
    en: 'Track occupancy and income across all listed units.',
  );
  static const addNew = LocalizedText(bn: 'নতুন যোগ করুন', en: 'Add New');
  static const collectedRent = LocalizedText(
    bn: 'সংগৃহীত ভাড়া',
    en: 'Collected Rent',
  );
  static const dueBills = LocalizedText(bn: 'বকেয়া বিল', en: 'Due Bills');
  static const monthlyBillGenerator = LocalizedText(
    bn: 'মাসিক বিল জেনারেটর',
    en: 'Monthly Bill Generator',
  );
  static const monthlyBillGeneratorSubtitle = LocalizedText(
    bn: 'একটি বিল তৈরি করুন, মোট হিসাব দেখুন এবং টেন্যান্টকে পাঠান।',
    en: 'Create a bill, review the total, and send it to a tenant.',
  );
  static const billingForm = LocalizedText(
    bn: 'বিলিং ফর্ম',
    en: 'Billing Form',
  );
  static const selectTenant = LocalizedText(
    bn: 'টেন্যান্ট নির্বাচন করুন',
    en: 'Select Tenant',
  );
  static const electricityBill = LocalizedText(
    bn: 'বিদ্যুৎ বিল',
    en: 'Electricity Bill',
  );
  static const waterBill = LocalizedText(bn: 'পানির বিল', en: 'Water Bill');
  static const gasBill = LocalizedText(bn: 'গ্যাস বিল', en: 'Gas Bill');
  static const serviceCharge = LocalizedText(
    bn: 'সার্ভিস চার্জ',
    en: 'Service Charge',
  );
  static const totalAmount = LocalizedText(
    bn: 'মোট পরিমাণ',
    en: 'Total Amount',
  );
  static const sendBillToTenant = LocalizedText(
    bn: 'টেন্যান্টকে বিল পাঠান',
    en: 'Send Bill to Tenant',
  );
  static const tenantsSubtitleOwner = LocalizedText(
    bn: 'সক্রিয় টেন্যান্ট প্রোফাইল ও যোগাযোগের তথ্য দেখুন।',
    en: 'Review active tenant profiles and contact information.',
  );
  static const ownerWorkspaceProfileSubtitle = LocalizedText(
    bn: 'আপনার ওনার ওয়ার্কস্পেসের দ্রুত সারসংক্ষেপ।',
    en: 'Quick summary of your owner workspace.',
  );
  static const workspaceSnapshot = LocalizedText(
    bn: 'ওয়ার্কস্পেস সারসংক্ষেপ',
    en: 'Workspace Snapshot',
  );
  static const activeTenants = LocalizedText(
    bn: 'সক্রিয় টেন্যান্ট',
    en: 'Active Tenants',
  );

  static const locationFilters = LocalizedText(
    bn: 'লোকেশন ফিল্টার',
    en: 'Location Filters',
  );
  static const reset = LocalizedText(bn: 'রিসেট', en: 'Reset');
  static const matchingListings = LocalizedText(
    bn: 'ম্যাচিং লিস্টিং',
    en: 'Matching Listings',
  );
  static const noListingsForLocation = LocalizedText(
    bn: 'এই লোকেশনে কোনো লিস্টিং পাওয়া যায়নি',
    en: 'No listings for this location',
  );
  static const tryAnotherDivisionDistrictUpazila = LocalizedText(
    bn: 'অন্য বিভাগ, জেলা বা উপজেলা চেষ্টা করুন।',
    en: 'Try another division, district, or upazila.',
  );
  static const quickFilters = LocalizedText(
    bn: 'দ্রুত ফিল্টার',
    en: 'Quick Filters',
  );
  static const location = LocalizedText(bn: 'লোকেশন', en: 'Location');
  static const filterByLocation = LocalizedText(
    bn: 'লোকেশন দিয়ে ফিল্টার',
    en: 'Filter by location',
  );
  static const showResults = LocalizedText(
    bn: 'ফলাফল দেখুন',
    en: 'Show results',
  );
  static const division = LocalizedText(bn: 'বিভাগ', en: 'Division');
  static const district = LocalizedText(bn: 'জেলা', en: 'District');
  static const upazila = LocalizedText(bn: 'উপজেলা', en: 'Upazila');
  static const selectDivision = LocalizedText(
    bn: 'বিভাগ নির্বাচন করুন',
    en: 'Select division',
  );
  static const selectDistrict = LocalizedText(
    bn: 'জেলা নির্বাচন করুন',
    en: 'Select district',
  );
  static const selectUpazila = LocalizedText(
    bn: 'উপজেলা নির্বাচন করুন',
    en: 'Select upazila',
  );
  static const selectDivisionFirst = LocalizedText(
    bn: 'আগে বিভাগ নির্বাচন করুন',
    en: 'Select division first',
  );
  static const selectDistrictFirst = LocalizedText(
    bn: 'আগে জেলা নির্বাচন করুন',
    en: 'Select district first',
  );
  static const noListingsFound = LocalizedText(
    bn: 'কোনো লিস্টিং পাওয়া যায়নি',
    en: 'No listings found',
  );
  static const adjustDivisionDistrictUpazilaFilters = LocalizedText(
    bn: 'বিভাগ, জেলা বা উপজেলা ফিল্টার পরিবর্তন করুন।',
    en: 'Adjust division, district, or upazila filters.',
  );
  static const noMatchingListings = LocalizedText(
    bn: 'ম্যাচিং লিস্টিং পাওয়া যায়নি',
    en: 'No matching listings',
  );
  static const tryAnotherKeywordOrClearSearch = LocalizedText(
    bn: 'অন্য কীওয়ার্ড চেষ্টা করুন বা সার্চ ক্লিয়ার করুন।',
    en: 'Try another keyword or clear the search.',
  );

  static const menuSubtitleTenant = LocalizedText(
    bn: 'প্রোফাইল, পেমেন্ট ও সাপোর্ট টুলস ব্যবহার করুন।',
    en: 'Access profile, payment, and support tools.',
  );
  static const paymentAgreement = LocalizedText(
    bn: 'পেমেন্ট ও এগ্রিমেন্ট',
    en: 'Payment & Agreement',
  );
  static const paymentAgreementSubtitle = LocalizedText(
    bn: 'পেমেন্ট ডিটেইলস খুলুন এবং এগ্রিমেন্ট তৈরি করুন।',
    en: 'Open payment details and generate agreement.',
  );
  static const monthlyBills = LocalizedText(
    bn: 'মাসিক বিল',
    en: 'Monthly Bills',
  );
  static const monthlyBillsSubtitle = LocalizedText(
    bn: 'চলতি মাসের ইউটিলিটি ও সার্ভিস বিল দেখুন।',
    en: 'Review current monthly utility and service bills.',
  );
  static const managerDetails = LocalizedText(
    bn: 'ম্যানেজার ডিটেইলস',
    en: 'Manager Details',
  );
  static const managerDetailsSubtitle = LocalizedText(
    bn: 'ম্যানেজারের প্রোফাইল ও মোট বকেয়া চার্জ দেখুন।',
    en: 'Check manager profile and total outstanding charges.',
  );
  static const ownerProfile = LocalizedText(
    bn: 'ওনার প্রোফাইল',
    en: 'Owner Profile',
  );
  static const ownerProfileSubtitle = LocalizedText(
    bn: 'ওনারের যোগাযোগের অপশন ও নির্বাচিত লিস্টিং দেখুন।',
    en: 'View owner contact options and selected listing.',
  );
  static const confirmMoveIn = LocalizedText(
    bn: 'মুভ-ইন কনফার্ম',
    en: 'Confirm Move-In',
  );
  static const confirmMoveInSubtitle = LocalizedText(
    bn: 'মুভ-ইন কনফার্মেশন ও সাপোর্ট শর্টকাট খুলুন।',
    en: 'Open move-in confirmation and support shortcuts.',
  );
  static const maintenanceRequest = LocalizedText(
    bn: 'মেইনটেন্যান্স রিকোয়েস্ট',
    en: 'Maintenance Request',
  );
  static const maintenanceRequestSubtitle = LocalizedText(
    bn: 'প্লাম্বিং, ইলেকট্রিক্যাল ও অন্যান্য সমস্যা রিপোর্ট করুন।',
    en: 'Report plumbing, electrical, and other issues.',
  );
}
