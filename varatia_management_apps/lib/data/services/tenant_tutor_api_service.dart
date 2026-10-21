import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/utils/local_lang.dart';
import '../models/tutor_bdjobs_profile.dart';
import 'auth_session_service.dart';

class TenantTutorApiService {
  static const Duration _requestTimeout = Duration(seconds: 20);

  static const String postsPath = '/api/tenant/tutor/posts';
  static const String profilePath = '/api/tenant/tutor/profile';

  TenantTutorApiService({
    http.Client? client,
    AuthSessionService? authSessionService,
  }) : _client = client ?? http.Client(),
       _authSessionService = authSessionService ?? AuthSessionService(),
       _ownsClient = client == null;

  final http.Client _client;
  final AuthSessionService _authSessionService;
  final bool _ownsClient;

  Future<TenantTutorPostListResult> getPosts({
    String? type,
    String? subject,
    String? area,
    bool? verifiedOnly,
    int page = 1,
    int limit = 50,
  }) async {
    final tenantId = await _authSessionService.readUserId();
    final payload = await _getPayload(
      _buildUri(postsPath, {
        'tenantId': tenantId,
        'type': type,
        'subject': subject,
        'area': area,
        if (verifiedOnly != null) 'verifiedOnly': verifiedOnly.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      }),
    );
    final data = _readDataObject(payload);
    final rawPosts = payload is List
        ? payload
        : _readList(data['posts']).isNotEmpty
        ? _readList(data['posts'])
        : _readList(data['items']);

    return TenantTutorPostListResult(
      page: _readInt(data['page'], fallback: page),
      hasMore: _readBool(data['hasMore']),
      posts: rawPosts
          .whereType<Map>()
          .map((item) => TenantTutorPost.fromJson(item))
          .toList(growable: false),
    );
  }

  Future<TenantTutorCreatePostResult> createPost({
    required TenantTutorCreatePostInput input,
  }) async {
    final tenantId = await _authSessionService.readUserId();
    if (tenantId == null || tenantId.isEmpty) {
      throw const TenantTutorApiException('Login session not found.');
    }

    final payload = await _postJson(_buildUri(postsPath), <String, Object?>{
      'tenantId': tenantId,
      ...input.toJson(),
    });
    final data = _readDataObject(payload);
    final rawPost = _readMap(data['post']).isNotEmpty
        ? _readMap(data['post'])
        : _readMap(data['item']).isNotEmpty
        ? _readMap(data['item'])
        : _looksLikePost(data)
        ? data
        : <String, dynamic>{};

    return TenantTutorCreatePostResult(
      message:
          _readString(data['message']) ?? 'Tutor post created successfully.',
      post: rawPost.isEmpty ? null : TenantTutorPost.fromJson(rawPost),
    );
  }

  Future<TutorBdjobsProfile?> getProfile(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return null;

    try {
      final payload = await _getPayload(_buildUri('$profilePath/$normalized'));
      final data = _readDataObject(payload);
      if (data.isEmpty) return null;
      return TutorBdjobsProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<TutorBdjobsProfile?> saveProfile({
    required String userId,
    required TutorBdjobsProfile profile,
  }) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return null;

    try {
      final payload = await _postJson(
        _buildUri(profilePath),
        <String, Object?>{
          'userId': normalized,
          ...profile.toJson(),
          'completionScore': profile.completionScore,
        },
      );
      final data = _readDataObject(payload);
      final profileData = _readMap(data['profile']);
      if (profileData.isNotEmpty) {
        return TutorBdjobsProfile.fromJson(profileData);
      }
      return profile;
    } catch (e) {
      debugPrint('Failed to sync tutor profile to backend: $e');
      return null;
    }
  }

  Uri _buildUri(String path, [Map<String, String?> query = const {}]) {
    final queryParameters = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value?.trim();
      if (value != null && value.isNotEmpty) {
        queryParameters[entry.key] = value;
      }
    }

    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  Future<Object?> _getPayload(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_requestTimeout);
      _throwIfFailed(response, fallback: 'Tutor posts request failed.');
      return _decodePayload(response.body);
    } on TenantTutorApiException {
      rethrow;
    } on TimeoutException {
      throw const TenantTutorApiException(
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const TenantTutorApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    } on http.ClientException {
      throw const TenantTutorApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    }
  }

  Future<Object?> _postJson(Uri uri, Map<String, Object?> body) async {
    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
      _throwIfFailed(response, fallback: 'Tutor post submit failed.');
      return _decodePayload(response.body);
    } on TenantTutorApiException {
      rethrow;
    } on TimeoutException {
      throw const TenantTutorApiException(
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const TenantTutorApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    } on http.ClientException {
      throw const TenantTutorApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    }
  }

  void _throwIfFailed(http.Response response, {required String fallback}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw TenantTutorApiException(
      _readErrorMessage(response.body, statusCode: response.statusCode) ??
          fallback,
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static Object? _decodePayload(String rawBody) {
    final trimmedBody = rawBody.trim();
    if (trimmedBody.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(trimmedBody);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Map<String, dynamic> _readDataObject(Object? payload) {
    final root = _readMap(payload);
    final data = _readMap(root['data']);
    return data.isNotEmpty ? data : root;
  }

  static Map<String, dynamic> _readMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    return <String, dynamic>{};
  }

  static List<dynamic> _readList(Object? value) {
    if (value is List) {
      return value;
    }

    return const <dynamic>[];
  }

  static String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num || value is bool) {
      return value.toString();
    }

    return null;
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return num.tryParse(value.trim())?.round() ?? fallback;
    }

    return fallback;
  }

  static bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'active' ||
          normalized == 'verified';
    }

    return false;
  }

  static LocalizedText _readLocalized(
    Object? value, {
    required String fallback,
    String? fallbackBn,
    String? fallbackEn,
  }) {
    final map = _readMap(value);
    if (map.isNotEmpty) {
      final label =
          _readString(map['label']) ??
          _readString(map['name']) ??
          _readString(map['title']);
      final en =
          _readString(map['en']) ??
          _readString(map['english']) ??
          _readString(map['titleEn']) ??
          fallbackEn ??
          label ??
          fallback;
      final bn =
          _readString(map['bn']) ??
          _readString(map['bangla']) ??
          _readString(map['titleBn']) ??
          fallbackBn ??
          label ??
          en;
      return LocalizedText(bn: bn, en: en);
    }

    final text = _readString(value) ?? fallback;
    return LocalizedText(bn: fallbackBn ?? text, en: fallbackEn ?? text);
  }

  static String _normalizeType(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'need_tutor' ||
      'need-tutor' ||
      'student' ||
      'guardian' ||
      'learn' => 'request',
      _ => normalized == 'request' ? 'request' : 'tutor',
    };
  }

  static bool _looksLikePost(Map<String, dynamic> payload) {
    return payload.containsKey('id') ||
        payload.containsKey('_id') ||
        payload.containsKey('postId') ||
        payload.containsKey('name') ||
        payload.containsKey('subject');
  }

  static String? _readErrorMessage(String rawBody, {int? statusCode}) {
    final trimmedBody = rawBody.trim();

    try {
      final payload = jsonDecode(trimmedBody);
      final map = _readMap(payload);
      for (final key in const ['message', 'error', 'title', 'detail']) {
        final value = _readString(map[key]);
        if (value != null) {
          return value;
        }
      }
    } catch (_) {
      // Ignore invalid JSON and use the generic fallback.
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

    return null;
  }
}

class TenantTutorCreatePostInput {
  const TenantTutorCreatePostInput({
    required this.type,
    required this.name,
    required this.roleBn,
    required this.roleEn,
    required this.subjectBn,
    required this.subjectEn,
    required this.areaBn,
    required this.areaEn,
    required this.priceBn,
    required this.priceEn,
    required this.availabilityBn,
    required this.availabilityEn,
    required this.phone,
    required this.descriptionBn,
    required this.descriptionEn,
    required this.experienceBn,
    required this.experienceEn,
    required this.fulfillmentStatus,
    required this.remarks,
  });

  final String type;
  final String name;
  final String roleBn;
  final String roleEn;
  final String subjectBn;
  final String subjectEn;
  final String areaBn;
  final String areaEn;
  final String priceBn;
  final String priceEn;
  final String availabilityBn;
  final String availabilityEn;
  final String phone;
  final String descriptionBn;
  final String descriptionEn;
  final String experienceBn;
  final String experienceEn;
  final String fulfillmentStatus;
  final String remarks;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type,
      'postType': type,
      'category': type,
      'name': name,
      'authorName': name,
      'guardianName': name,
      'role': {'bn': roleBn, 'en': roleEn},
      'roleLabel': {'bn': roleBn, 'en': roleEn},
      'subject': {'bn': subjectBn, 'en': subjectEn},
      'subjectLabel': {'bn': subjectBn, 'en': subjectEn},
      'title': {'bn': subjectBn, 'en': subjectEn},
      'subjectBn': subjectBn,
      'subjectEn': subjectEn,
      'titleBn': subjectBn,
      'titleEn': subjectEn,
      'area': {'bn': areaBn, 'en': areaEn},
      'location': {'label': areaEn, 'bn': areaBn, 'en': areaEn},
      'areaName': areaEn,
      'locationLabel': areaEn,
      'areaBn': areaBn,
      'areaEn': areaEn,
      'price': {'bn': priceBn, 'en': priceEn},
      'fee': {'bn': priceBn, 'en': priceEn},
      'budget': {'bn': priceBn, 'en': priceEn},
      'priceBn': priceBn,
      'priceEn': priceEn,
      'availability': {'bn': availabilityBn, 'en': availabilityEn},
      'schedule': {'bn': availabilityBn, 'en': availabilityEn},
      'time': {'bn': availabilityBn, 'en': availabilityEn},
      'availabilityBn': availabilityBn,
      'availabilityEn': availabilityEn,
      'phone': phone,
      'contactNumber': phone,
      'mobile': phone,
      'description': {'bn': descriptionBn, 'en': descriptionEn},
      'details': {'bn': descriptionBn, 'en': descriptionEn},
      'body': {'bn': descriptionBn, 'en': descriptionEn},
      'descriptionBn': descriptionBn,
      'descriptionEn': descriptionEn,
      'experience': {'bn': experienceBn, 'en': experienceEn},
      'qualification': {'bn': experienceBn, 'en': experienceEn},
      'requirement': {'bn': experienceBn, 'en': experienceEn},
      'experienceBn': experienceBn,
      'experienceEn': experienceEn,
      'fulfillmentStatus': fulfillmentStatus,
      'resultStatus': fulfillmentStatus,
      'remarks': remarks,
    };
  }
}

class TenantTutorPost {
  const TenantTutorPost({
    required this.id,
    required this.type,
    required this.name,
    required this.role,
    required this.subject,
    required this.area,
    required this.price,
    required this.availability,
    required this.badge,
    required this.rating,
    required this.phone,
    required this.description,
    required this.experience,
    required this.fulfillmentStatus,
    required this.remarks,
    required this.verified,
  });

  final String id;
  final String type;
  final String name;
  final LocalizedText role;
  final LocalizedText subject;
  final LocalizedText area;
  final LocalizedText price;
  final LocalizedText availability;
  final LocalizedText badge;
  final String rating;
  final String phone;
  final LocalizedText description;
  final LocalizedText experience;
  final String fulfillmentStatus;
  final String remarks;
  final bool verified;

  factory TenantTutorPost.fromJson(Map<Object?, Object?> payload) {
    final map = TenantTutorApiService._readMap(payload);
    final type = TenantTutorApiService._normalizeType(
      TenantTutorApiService._readString(
            map['type'] ?? map['postType'] ?? map['category'],
          ) ??
          'tutor',
    );
    final isRequest = type == 'request';
    final badgeFallback = isRequest ? 'Need Tutor' : 'Tutor';
    final roleFallback = isRequest ? 'Guardian/student request' : 'Tutor post';
    final locationMap = TenantTutorApiService._readMap(
      map['location'] ?? map['area'],
    );
    final locationLabel =
        TenantTutorApiService._readString(locationMap['label']) ??
        TenantTutorApiService._readString(locationMap['name']) ??
        TenantTutorApiService._readString(map['locationLabel']) ??
        TenantTutorApiService._readString(map['areaName']);

    return TenantTutorPost(
      id:
          TenantTutorApiService._readString(map['id']) ??
          TenantTutorApiService._readString(map['postId']) ??
          TenantTutorApiService._readString(map['_id']) ??
          '',
      type: type,
      name:
          TenantTutorApiService._readString(map['name']) ??
          TenantTutorApiService._readString(map['authorName']) ??
          TenantTutorApiService._readString(map['guardianName']) ??
          'Tutor member',
      role: TenantTutorApiService._readLocalized(
        map['role'] ?? map['roleLabel'],
        fallback: roleFallback,
        fallbackBn: isRequest ? 'অভিভাবক/শিক্ষার্থী পোস্ট' : 'শিক্ষক পোস্ট',
      ),
      subject: TenantTutorApiService._readLocalized(
        map['subject'] ?? map['subjectLabel'] ?? map['title'],
        fallback: 'Subject',
        fallbackBn: TenantTutorApiService._readString(map['subjectBn']),
        fallbackEn: TenantTutorApiService._readString(map['subjectEn']),
      ),
      area: TenantTutorApiService._readLocalized(
        map['area'] ?? map['location'],
        fallback: locationLabel ?? '',
        fallbackBn:
            TenantTutorApiService._readString(map['areaBn']) ?? locationLabel,
        fallbackEn:
            TenantTutorApiService._readString(map['areaEn']) ?? locationLabel,
      ),
      price: TenantTutorApiService._readLocalized(
        map['price'] ?? map['fee'] ?? map['budget'],
        fallback: '',
        fallbackBn: TenantTutorApiService._readString(map['priceBn']),
        fallbackEn: TenantTutorApiService._readString(map['priceEn']),
      ),
      availability: TenantTutorApiService._readLocalized(
        map['availability'] ?? map['schedule'] ?? map['time'],
        fallback: '',
        fallbackBn: TenantTutorApiService._readString(map['availabilityBn']),
        fallbackEn: TenantTutorApiService._readString(map['availabilityEn']),
      ),
      badge: TenantTutorApiService._readLocalized(
        map['badge'] ?? map['badgeLabel'],
        fallback: badgeFallback,
        fallbackBn: isRequest ? 'শিক্ষক চাই' : 'শিক্ষক',
      ),
      rating:
          TenantTutorApiService._readString(map['rating']) ??
          TenantTutorApiService._readString(map['status']) ??
          (isRequest ? 'Open' : 'New'),
      phone:
          TenantTutorApiService._readString(map['phone']) ??
          TenantTutorApiService._readString(map['contactNumber']) ??
          TenantTutorApiService._readString(map['mobile']) ??
          '',
      description: TenantTutorApiService._readLocalized(
        map['description'] ?? map['details'] ?? map['body'],
        fallback: '',
        fallbackBn: TenantTutorApiService._readString(map['descriptionBn']),
        fallbackEn: TenantTutorApiService._readString(map['descriptionEn']),
      ),
      experience: TenantTutorApiService._readLocalized(
        map['experience'] ?? map['qualification'] ?? map['requirement'],
        fallback: '',
        fallbackBn: TenantTutorApiService._readString(map['experienceBn']),
        fallbackEn: TenantTutorApiService._readString(map['experienceEn']),
      ),
      fulfillmentStatus:
          TenantTutorApiService._readString(
            map['fulfillmentStatus'] ?? map['resultStatus'],
          ) ??
          'not_got',
      remarks: TenantTutorApiService._readString(map['remarks']) ?? '',
      verified: TenantTutorApiService._readBool(
        map['verified'] ?? map['isVerified'],
      ),
    );
  }
}

class TenantTutorPostListResult {
  const TenantTutorPostListResult({
    required this.posts,
    required this.page,
    required this.hasMore,
  });

  final List<TenantTutorPost> posts;
  final int page;
  final bool hasMore;
}

class TenantTutorCreatePostResult {
  const TenantTutorCreatePostResult({required this.message, this.post});

  final String message;
  final TenantTutorPost? post;
}

class TenantTutorApiException implements Exception {
  const TenantTutorApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
