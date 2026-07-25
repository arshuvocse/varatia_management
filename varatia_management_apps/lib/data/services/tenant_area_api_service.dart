import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/utils/local_lang.dart';
import 'auth_session_service.dart';

class TenantAreaApiService {
  static const Duration _requestTimeout = Duration(seconds: 20);

  static const String homePath = '/api/tenant/area/home';
  static const String wardsPath = '/api/tenant/area/wards';
  static const String postsPath = '/api/tenant/area/posts';

  TenantAreaApiService({
    http.Client? client,
    AuthSessionService? authSessionService,
  }) : _client = client ?? http.Client(),
       _authSessionService = authSessionService ?? AuthSessionService(),
       _ownsClient = client == null;

  final http.Client _client;
  final AuthSessionService _authSessionService;
  final bool _ownsClient;

  Future<TenantAreaHomeData> getHome() async {
    final tenantId = await _authSessionService.readUserId();
    final payload = await _getPayload(
      _buildUri(homePath, {'tenantId': tenantId}),
    );
    return TenantAreaHomeData.fromJson(_readDataObject(payload));
  }

  Future<List<TenantAreaWard>> getWards({String? city, String? search}) async {
    final tenantId = await _authSessionService.readUserId();
    final payload = await _getPayload(
      _buildUri(wardsPath, {
        'tenantId': tenantId,
        'city': city,
        'search': search,
      }),
    );
    final data = _readDataObject(payload);
    final rawWards = payload is List
        ? payload
        : _readList(data['wards']).isNotEmpty
        ? _readList(data['wards'])
        : _readList(data['items']);

    return rawWards
        .whereType<Map>()
        .map((item) => TenantAreaWard.fromJson(item))
        .toList(growable: false);
  }

  Future<TenantAreaPostListResult> getPosts({
    String? wardId,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final tenantId = await _authSessionService.readUserId();
    final payload = await _getPayload(
      _buildUri(postsPath, {
        'tenantId': tenantId,
        'wardId': wardId,
        'category': category,
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

    return TenantAreaPostListResult(
      page: _readInt(data['page'], fallback: page),
      hasMore: _readBool(data['hasMore']),
      posts: rawPosts
          .whereType<Map>()
          .map((item) => TenantAreaPost.fromJson(item))
          .toList(growable: false),
    );
  }

  Future<TenantAreaCreatePostResult> createPost({
    required String postType,
    required String details,
    required String locationLabel,
    required String privacy,
    String? wardId,
    String? attachmentName,
    String? attachmentMediaType,
    bool highQuality = false,
    String? postScope,
    double? latitude,
    double? longitude,
  }) async {
    final tenantId = await _authSessionService.readUserId();
    if (tenantId == null || tenantId.isEmpty) {
      throw const TenantAreaApiException('Login session not found.');
    }

    final attachments = attachmentName == null || attachmentName.trim().isEmpty
        ? const <Map<String, Object?>>[]
        : <Map<String, Object?>>[
            {
              'fileName': attachmentName.trim(),
              if (attachmentMediaType != null &&
                  attachmentMediaType.trim().isNotEmpty)
                'mediaType': attachmentMediaType.trim(),
              'quality': highQuality ? 'high' : 'standard',
            },
          ];

    final requestBody = <String, Object?>{
      'tenantId': tenantId,
      'wardId': wardId,
      'postType': postType,
      'details': details,
      'location': {
        'label': locationLabel,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
      'privacy': privacy,
      if (postScope != null && postScope.trim().isNotEmpty)
        'postScope': postScope.trim(),
      'highQuality': highQuality,
      'attachments': attachments,
    };

    final payload = await _postJson(_buildUri(postsPath), requestBody);
    final data = _readDataObject(payload);
    final rawPost = _readMap(data['post']).isNotEmpty
        ? _readMap(data['post'])
        : _readMap(data['item']);

    return TenantAreaCreatePostResult(
      message:
          _readString(data['message']) ?? 'Area post created successfully.',
      post: rawPost.isEmpty ? null : TenantAreaPost.fromJson(rawPost),
    );
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
      _throwIfFailed(response, fallback: 'Tenant area request failed.');
      return _decodePayload(response.body);
    } on TenantAreaApiException {
      rethrow;
    } on TimeoutException {
      throw const TenantAreaApiException(
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const TenantAreaApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    } on http.ClientException {
      throw const TenantAreaApiException(
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
      _throwIfFailed(response, fallback: 'Tenant area post request failed.');
      return _decodePayload(response.body);
    } on TenantAreaApiException {
      rethrow;
    } on TimeoutException {
      throw const TenantAreaApiException(
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const TenantAreaApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    } on http.ClientException {
      throw const TenantAreaApiException(
        'Unable to reach the server. Please check the API connection and try again.',
      );
    }
  }

  void _throwIfFailed(http.Response response, {required String fallback}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw TenantAreaApiException(
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
          normalized == 'active';
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
      final en =
          _readString(map['en']) ??
          _readString(map['english']) ??
          _readString(map['titleEn']) ??
          fallbackEn ??
          fallback;
      final bn =
          _readString(map['bn']) ??
          _readString(map['bangla']) ??
          _readString(map['titleBn']) ??
          fallbackBn ??
          en;
      return LocalizedText(bn: bn, en: en);
    }

    final text = _readString(value) ?? fallback;
    return LocalizedText(bn: fallbackBn ?? text, en: fallbackEn ?? text);
  }

  static List<LocalizedText> _readRules(Object? value) {
    final rules = <LocalizedText>[];
    final map = _readMap(value);
    if (map.isNotEmpty) {
      final bnList = _readList(map['bn']);
      final enList = _readList(map['en']);
      final maxLength = bnList.length > enList.length
          ? bnList.length
          : enList.length;
      for (var index = 0; index < maxLength; index++) {
        final en = index < enList.length ? _readString(enList[index]) : null;
        final bn = index < bnList.length ? _readString(bnList[index]) : null;
        if (en != null || bn != null) {
          rules.add(LocalizedText(bn: bn ?? en ?? '', en: en ?? bn ?? ''));
        }
      }
      return rules;
    }

    for (final item in _readList(value)) {
      rules.add(_readLocalized(item, fallback: ''));
    }
    return rules
        .where((item) => item.bn.isNotEmpty || item.en.isNotEmpty)
        .toList();
  }

  static String _composeWardTitle(String wardNo, String area) {
    if (wardNo.isEmpty) {
      return area.isEmpty ? 'Ward' : area;
    }
    if (area.isEmpty) {
      return 'Ward $wardNo';
    }
    return 'Ward $wardNo - $area';
  }

  static String _formatCompactCount(int value) {
    if (value >= 1000) {
      final compact = value / 1000;
      final label = compact == compact.roundToDouble()
          ? compact.round().toString()
          : compact.toStringAsFixed(1);
      return '${label}k';
    }

    return value.toString();
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

class TenantAreaHomeData {
  const TenantAreaHomeData({
    required this.activeWard,
    required this.wards,
    required this.feedPreview,
    required this.wardRules,
    required this.locationOptions,
    required this.emergencyHelpline,
    required this.notificationUnreadCount,
  });

  final TenantAreaWard? activeWard;
  final List<TenantAreaWard> wards;
  final List<TenantAreaPost> feedPreview;
  final List<LocalizedText> wardRules;
  final List<String> locationOptions;
  final TenantAreaHelpline? emergencyHelpline;
  final int notificationUnreadCount;

  factory TenantAreaHomeData.fromJson(Map<String, dynamic> payload) {
    final rawActiveWard = TenantAreaApiService._readMap(
      payload['activeWard'] ?? payload['currentWard'],
    );
    final rawWards = TenantAreaApiService._readList(
      payload['wards'] ?? payload['nearbyWards'],
    );
    final rawPosts = TenantAreaApiService._readList(
      payload['feedPreview'] ?? payload['posts'] ?? payload['recentPosts'],
    );
    final rawHelpline = TenantAreaApiService._readMap(
      payload['emergencyHelpline'] ?? payload['helpline'],
    );

    final activeWard = rawActiveWard.isEmpty
        ? null
        : TenantAreaWard.fromJson(rawActiveWard);
    final wards = rawWards
        .whereType<Map>()
        .map((item) => TenantAreaWard.fromJson(item))
        .toList(growable: true);
    if (activeWard != null && wards.every((ward) => ward.id != activeWard.id)) {
      wards.insert(0, activeWard);
    }

    return TenantAreaHomeData(
      activeWard: activeWard,
      wards: wards,
      feedPreview: rawPosts
          .whereType<Map>()
          .map((item) => TenantAreaPost.fromJson(item))
          .toList(growable: false),
      wardRules: TenantAreaApiService._readRules(payload['wardRules']),
      locationOptions:
          TenantAreaApiService._readList(payload['locationOptions'])
              .map(TenantAreaApiService._readString)
              .whereType<String>()
              .toList(growable: false),
      emergencyHelpline: rawHelpline.isEmpty
          ? null
          : TenantAreaHelpline.fromJson(rawHelpline),
      notificationUnreadCount: TenantAreaApiService._readInt(
        payload['notificationUnreadCount'] ?? payload['unreadNotifications'],
      ),
    );
  }
}

class TenantAreaWard {
  const TenantAreaWard({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.area,
    required this.city,
    required this.memberLabel,
    required this.memberCount,
    required this.selected,
    required this.verified,
  });

  final String id;
  final LocalizedText title;
  final String titleEn;
  final String area;
  final String city;
  final LocalizedText memberLabel;
  final int memberCount;
  final bool selected;
  final bool verified;

  factory TenantAreaWard.fromJson(Map<Object?, Object?> payload) {
    final map = TenantAreaApiService._readMap(payload);
    final id =
        TenantAreaApiService._readString(map['id']) ??
        TenantAreaApiService._readString(map['wardId']) ??
        TenantAreaApiService._readString(map['_id']) ??
        '';
    final wardNo =
        TenantAreaApiService._readString(map['wardNo']) ??
        TenantAreaApiService._readString(map['wardNumber']) ??
        TenantAreaApiService._readString(map['number']) ??
        '';
    final area =
        TenantAreaApiService._readString(map['area']) ??
        TenantAreaApiService._readString(map['areaName']) ??
        TenantAreaApiService._readString(map['location']) ??
        '';
    final fallbackTitle = TenantAreaApiService._composeWardTitle(wardNo, area);
    final title = TenantAreaApiService._readLocalized(
      map['title'],
      fallback: fallbackTitle,
      fallbackEn:
          TenantAreaApiService._readString(map['titleEn']) ?? fallbackTitle,
      fallbackBn:
          TenantAreaApiService._readString(map['titleBn']) ?? fallbackTitle,
    );
    final memberCount = TenantAreaApiService._readInt(
      map['memberCount'] ?? map['members'],
    );
    final defaultMemberLabel = memberCount > 0
        ? '${TenantAreaApiService._formatCompactCount(memberCount)} members'
        : '';

    return TenantAreaWard(
      id: id.isEmpty && wardNo.isNotEmpty ? 'ward-$wardNo' : id,
      title: title,
      titleEn: TenantAreaApiService._readString(map['titleEn']) ?? title.en,
      area: area,
      city:
          TenantAreaApiService._readString(map['city']) ??
          TenantAreaApiService._readString(map['cityCode']) ??
          'dncc',
      memberLabel: TenantAreaApiService._readLocalized(
        map['memberLabel'],
        fallback: defaultMemberLabel,
      ),
      memberCount: memberCount,
      selected: TenantAreaApiService._readBool(
        map['selected'] ?? map['isSelected'] ?? map['active'],
      ),
      verified: TenantAreaApiService._readBool(
        map['verified'] ?? map['isVerified'],
      ),
    );
  }
}

class TenantAreaPost {
  const TenantAreaPost({
    required this.id,
    required this.postType,
    required this.author,
    required this.meta,
    required this.category,
    required this.body,
    required this.location,
    required this.likeCount,
    required this.commentCount,
    required this.artworkStyle,
    this.imageUrl,
  });

  final String id;
  final String postType;
  final LocalizedText author;
  final LocalizedText meta;
  final LocalizedText category;
  final LocalizedText body;
  final String location;
  final int likeCount;
  final int commentCount;
  final String artworkStyle;
  final String? imageUrl;

  factory TenantAreaPost.fromJson(Map<Object?, Object?> payload) {
    final map = TenantAreaApiService._readMap(payload);
    final postType =
        (TenantAreaApiService._readString(map['postType']) ??
                TenantAreaApiService._readString(map['type']) ??
                TenantAreaApiService._readString(map['category']) ??
                'problem')
            .toLowerCase();
    final categoryFallback = _categoryFallback(postType);
    final body =
        map['body'] ?? map['details'] ?? map['content'] ?? map['description'];

    return TenantAreaPost(
      id:
          TenantAreaApiService._readString(map['id']) ??
          TenantAreaApiService._readString(map['postId']) ??
          TenantAreaApiService._readString(map['_id']) ??
          '',
      postType: postType,
      author: TenantAreaApiService._readLocalized(
        map['author'] ?? map['authorName'] ?? map['userName'],
        fallback: 'Area member',
      ),
      meta: TenantAreaApiService._readLocalized(
        map['meta'] ?? map['timeAgo'],
        fallback: '',
      ),
      category: TenantAreaApiService._readLocalized(
        map['categoryLabel'] ?? map['category'],
        fallback: categoryFallback,
      ),
      body: TenantAreaApiService._readLocalized(body, fallback: ''),
      location:
          TenantAreaApiService._readString(map['locationLabel']) ??
          TenantAreaApiService._readString(map['location']) ??
          '',
      likeCount: TenantAreaApiService._readInt(
        map['likeCount'] ?? map['likes'],
      ),
      commentCount: TenantAreaApiService._readInt(
        map['commentCount'] ?? map['comments'],
      ),
      artworkStyle:
          TenantAreaApiService._readString(map['artworkStyle']) ??
          (postType == 'home' ? 'room' : 'streetNight'),
      imageUrl: TenantAreaApiService._readString(
        map['imageUrl'] ?? map['photoUrl'],
      ),
    );
  }

  static String _categoryFallback(String postType) {
    return switch (postType) {
      'home' => 'Home',
      'service' => 'Service',
      'announcement' || 'notice' => 'Notice',
      'help' => 'Help',
      _ => 'Problem',
    };
  }
}

class TenantAreaHelpline {
  const TenantAreaHelpline({required this.label, required this.phone});

  final String label;
  final String phone;

  factory TenantAreaHelpline.fromJson(Map<Object?, Object?> payload) {
    final map = TenantAreaApiService._readMap(payload);
    return TenantAreaHelpline(
      label: TenantAreaApiService._readString(map['label']) ?? 'Emergency',
      phone:
          TenantAreaApiService._readString(map['phone']) ??
          TenantAreaApiService._readString(map['phoneNumber']) ??
          '',
    );
  }
}

class TenantAreaPostListResult {
  const TenantAreaPostListResult({
    required this.posts,
    required this.page,
    required this.hasMore,
  });

  final List<TenantAreaPost> posts;
  final int page;
  final bool hasMore;
}

class TenantAreaCreatePostResult {
  const TenantAreaCreatePostResult({required this.message, this.post});

  final String message;
  final TenantAreaPost? post;
}

class TenantAreaApiException implements Exception {
  const TenantAreaApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
