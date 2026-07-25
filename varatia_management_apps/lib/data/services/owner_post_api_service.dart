import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'auth_session_service.dart';

class OwnerPostApiService {
  static const Duration _requestTimeout = Duration(seconds: 20);

  OwnerPostApiService({
    http.Client? client,
    AuthSessionService? authSessionService,
  }) : _client = client ?? http.Client(),
       _authSessionService = authSessionService ?? AuthSessionService(),
       _ownsClient = client == null;

  final http.Client _client;
  final AuthSessionService _authSessionService;
  final bool _ownsClient;

  Future<OwnerPostSubmitResult> submitPost({
    required Map<String, Object?> body,
  }) async {
    if (ApiConfig.isDemoMode) {
      final status = _readString(body['status']) ?? 'published';
      return OwnerPostSubmitResult(
        ownerId: 'DEMO-OWNER',
        postId: 'DEMO-POST-${DateTime.now().millisecondsSinceEpoch}',
        status: status,
        message: status == 'draft'
            ? 'Demo post saved as draft.'
            : 'Demo post published.',
      );
    }

    final ownerId = await _readOwnerId();
    final payload = <String, Object?>{'ownerId': ownerId, ...body};

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/owner/post'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OwnerPostApiException(
          _readErrorMessage(response.body, statusCode: response.statusCode),
        );
      }

      final responsePayload = _decodeObject(response.body);
      return OwnerPostSubmitResult(
        ownerId: _readString(responsePayload['ownerId']) ?? ownerId,
        postId:
            _readString(responsePayload['postId']) ??
            _readString(responsePayload['id']) ??
            _readNestedPostId(responsePayload['post']),
        status:
            _readString(responsePayload['status']) ??
            _readString(payload['status']) ??
            '',
        message:
            _readString(responsePayload['message']) ??
            'Post saved successfully.',
      );
    } on OwnerPostApiException {
      rethrow;
    } on TimeoutException {
      throw const OwnerPostApiException(
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const OwnerPostApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    } on http.ClientException {
      throw const OwnerPostApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    }
  }

  Future<OwnerPostListResult> getPosts({String? status}) async {
    if (ApiConfig.isDemoMode) {
      final normalizedStatus = status?.trim();
      final posts = _demoOwnerPosts
          .where(
            (item) =>
                normalizedStatus == null ||
                normalizedStatus.isEmpty ||
                item.status == normalizedStatus,
          )
          .toList(growable: false);

      return OwnerPostListResult(ownerId: 'DEMO-OWNER', posts: posts);
    }

    final ownerId = await _readOwnerId();
    final queryParameters = <String, String>{'ownerId': ownerId};
    final normalizedStatus = status?.trim();
    if (normalizedStatus != null && normalizedStatus.isNotEmpty) {
      queryParameters['status'] = normalizedStatus;
    }

    try {
      final response = await _client
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/owner/post',
            ).replace(queryParameters: queryParameters),
          )
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OwnerPostApiException(
          _readErrorMessage(response.body, statusCode: response.statusCode),
        );
      }

      final payload = _decodeObject(response.body);
      final rawPosts = payload['posts'];
      final posts = rawPosts is List
          ? rawPosts
                .whereType<Map>()
                .map((item) => OwnerPostRecord.fromJson(item))
                .toList(growable: false)
          : <OwnerPostRecord>[];

      return OwnerPostListResult(ownerId: ownerId, posts: posts);
    } on OwnerPostApiException {
      rethrow;
    } on TimeoutException {
      throw const OwnerPostApiException(
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const OwnerPostApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    } on http.ClientException {
      throw const OwnerPostApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    }
  }

  Future<String> _readOwnerId() async {
    final ownerId = await _authSessionService.readUserId();
    if (ownerId == null || ownerId.isEmpty) {
      throw const OwnerPostApiException('Login session not found.');
    }

    return ownerId;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static Map<String, dynamic> _decodeObject(String rawBody) {
    final trimmedBody = rawBody.trim();
    if (trimmedBody.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final payload = jsonDecode(trimmedBody);
      return payload is Map<String, dynamic> ? payload : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return null;
  }

  static String? _readNestedPostId(Object? postValue) {
    if (postValue is Map<String, dynamic>) {
      return _readString(postValue['postId']) ?? _readString(postValue['id']);
    }

    return null;
  }

  static Map<String, dynamic> _readMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  static int _readInt(Object? value) {
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return num.tryParse(value.trim())?.round() ?? 0;
    }

    return 0;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.trim());
  }

  static String _readErrorMessage(String rawBody, {int? statusCode}) {
    final trimmedBody = rawBody.trim();

    try {
      final payload = jsonDecode(trimmedBody);
      if (payload is Map<String, dynamic>) {
        for (final key in const ['message', 'error', 'title', 'detail']) {
          final value = payload[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    } catch (_) {
      // Ignore JSON parsing errors and fall back to a generic message.
    }

    final normalizedBody = trimmedBody.toLowerCase();
    final looksLikeServerFailure =
        (statusCode != null && statusCode >= 500) ||
        normalizedBody.contains('<!doctype html') ||
        normalizedBody.contains('<html');

    if (looksLikeServerFailure) {
      return 'Service is temporarily unavailable. Please try again later.';
    }

    if (trimmedBody.isNotEmpty &&
        trimmedBody.length <= 160 &&
        !trimmedBody.contains('\n')) {
      return trimmedBody;
    }

    return 'Owner post request failed. Please try again.';
  }
}

final _demoOwnerPosts = <OwnerPostRecord>[
  OwnerPostRecord(
    id: 'DEMO-POST-01',
    ownerId: 'DEMO-OWNER',
    postType: 'rent',
    status: 'published',
    title: 'মিরপুর DOHS, ২ বেড ফ্ল্যাট',
    location: 'মিরপুর, ঢাকা',
    monthlyRent: 15000,
    areaSqft: 1200,
    contactNumber: '01700000001',
    description: 'ফ্যামিলির জন্য রেডি ফ্ল্যাট, গ্যাস ও লিফট সুবিধা আছে।',
    fulfillmentStatus: 'not_got',
    remarks: 'Still available.',
    inquiryCount: 8,
    createdAt: DateTime(2026, 6, 1, 10, 30),
    updatedAt: DateTime(2026, 6, 2, 12),
  ),
  OwnerPostRecord(
    id: 'DEMO-POST-02',
    ownerId: 'DEMO-OWNER',
    postType: 'sale',
    status: 'published',
    title: 'গুলশান ২, ৩ বেড ফ্ল্যাট',
    location: 'গুলশান, ঢাকা',
    monthlyRent: 0,
    areaSqft: 1600,
    contactNumber: '01700000002',
    description: 'রেডি ফ্ল্যাট, পার্কিং এবং জেনারেটর সুবিধা আছে।',
    fulfillmentStatus: 'got',
    remarks: 'Tenant confirmed.',
    inquiryCount: 5,
    createdAt: DateTime(2026, 5, 26, 15, 20),
    updatedAt: DateTime(2026, 6, 4, 9, 45),
  ),
  OwnerPostRecord(
    id: 'DEMO-POST-03',
    ownerId: 'DEMO-OWNER',
    postType: 'rent',
    status: 'draft',
    title: 'মোহাম্মদপুর, ২ বেড ফ্যামিলি ফ্ল্যাট',
    location: 'মোহাম্মদপুর, ঢাকা',
    monthlyRent: 18500,
    areaSqft: 1100,
    contactNumber: '01700000003',
    description: 'ডেমো ড্রাফট পোস্ট। ছবি ও ফাইনাল ভাড়া পরে আপডেট হবে।',
    fulfillmentStatus: 'not_got',
    remarks: '',
    inquiryCount: 0,
    createdAt: DateTime(2026, 6, 5, 18),
    updatedAt: DateTime(2026, 6, 5, 18),
  ),
];

class OwnerPostSubmitResult {
  const OwnerPostSubmitResult({
    required this.ownerId,
    required this.status,
    required this.message,
    this.postId,
  });

  final String ownerId;
  final String status;
  final String message;
  final String? postId;
}

class OwnerPostListResult {
  const OwnerPostListResult({required this.ownerId, required this.posts});

  final String ownerId;
  final List<OwnerPostRecord> posts;
}

class OwnerPostRecord {
  const OwnerPostRecord({
    required this.id,
    required this.ownerId,
    required this.postType,
    required this.status,
    required this.title,
    required this.location,
    required this.monthlyRent,
    required this.areaSqft,
    required this.contactNumber,
    required this.description,
    required this.fulfillmentStatus,
    required this.remarks,
    required this.inquiryCount,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String postType;
  final String status;
  final String title;
  final String location;
  final int monthlyRent;
  final int areaSqft;
  final String contactNumber;
  final String description;
  final String fulfillmentStatus;
  final String remarks;
  final int inquiryCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OwnerPostRecord.fromJson(Map<Object?, Object?> payload) {
    final normalizedPayload = Map<String, dynamic>.from(payload);
    final property = OwnerPostApiService._readMap(
      normalizedPayload['property'],
    );
    final pricing = OwnerPostApiService._readMap(normalizedPayload['pricing']);
    final title =
        OwnerPostApiService._readString(property['title']) ??
        OwnerPostApiService._readString(normalizedPayload['title']) ??
        'Untitled Post';
    final location =
        OwnerPostApiService._readString(property['location']) ??
        OwnerPostApiService._readString(property['latLongAddress']) ??
        '';

    return OwnerPostRecord(
      id: OwnerPostApiService._readString(normalizedPayload['id']) ?? '',
      ownerId:
          OwnerPostApiService._readString(normalizedPayload['ownerId']) ?? '',
      postType:
          OwnerPostApiService._readString(normalizedPayload['postType']) ??
          'rent',
      status:
          OwnerPostApiService._readString(normalizedPayload['status']) ??
          'draft',
      title: title,
      location: location,
      monthlyRent: OwnerPostApiService._readInt(pricing['monthlyRent']),
      areaSqft: OwnerPostApiService._readInt(normalizedPayload['areaSqft']),
      contactNumber:
          OwnerPostApiService._readString(normalizedPayload['contactNumber']) ??
          '',
      description:
          OwnerPostApiService._readString(normalizedPayload['description']) ??
          '',
      fulfillmentStatus:
          OwnerPostApiService._readString(
            normalizedPayload['fulfillmentStatus'] ??
                normalizedPayload['resultStatus'],
          ) ??
          'not_got',
      remarks:
          OwnerPostApiService._readString(normalizedPayload['remarks']) ?? '',
      inquiryCount: OwnerPostApiService._readInt(
        normalizedPayload['inquiryCount'],
      ),
      createdAt: OwnerPostApiService._readDateTime(
        normalizedPayload['createdAt'],
      ),
      updatedAt: OwnerPostApiService._readDateTime(
        normalizedPayload['updatedAt'],
      ),
    );
  }
}

class OwnerPostApiException implements Exception {
  const OwnerPostApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
