import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class SavedPostDto {
  final int id;
  final String postId;
  final String postType;
  final DateTime savedAt;

  SavedPostDto({
    required this.id,
    required this.postId,
    required this.postType,
    required this.savedAt,
  });

  factory SavedPostDto.fromJson(Map<String, dynamic> json) {
    return SavedPostDto(
      id: json['id'] as int,
      postId: json['postId'].toString(),
      postType: json['postType'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

class SavedPostsApiService {
  SavedPostsApiService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<bool> toggleSavedPost({
    required String userId,
    required String postId,
    required String postType,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/SavedPosts/toggle');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'postId': postId,
        'postType': postType,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['isSaved'] as bool;
    } else {
      throw Exception('Failed to toggle saved post');
    }
  }

  Future<List<SavedPostDto>> getSavedPosts(String userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/SavedPosts/$userId');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map((json) => SavedPostDto.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return <SavedPostDto>[];
    } else {
      throw Exception('Failed to fetch saved posts');
    }
  }
}
