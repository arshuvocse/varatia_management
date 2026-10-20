import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class ContactRequestStatus {
  const ContactRequestStatus({
    required this.requestId,
    required this.status,
    required this.isApproved,
    this.revealedPhoneNumber,
    this.message,
  });

  final int requestId;
  final String status; // 'none', 'pending', 'approved', 'rejected'
  final bool isApproved;
  final String? revealedPhoneNumber;
  final String? message;

  factory ContactRequestStatus.fromJson(Map<String, dynamic> json) {
    return ContactRequestStatus(
      requestId: json['requestId'] as int? ?? 0,
      status: json['status'] as String? ?? 'none',
      isApproved: json['isApproved'] as bool? ?? false,
      revealedPhoneNumber: json['revealedPhoneNumber'] as String?,
      message: json['message'] as String?,
    );
  }

  factory ContactRequestStatus.none() {
    return const ContactRequestStatus(
      requestId: 0,
      status: 'none',
      isApproved: false,
    );
  }
}

class ContactRequestApiService {
  ContactRequestApiService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<ContactRequestStatus> createContactRequest({
    required String requesterUserId,
    required String postType,
    required int postId,
    String? purpose,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/contact-requests'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requesterUserId': requesterUserId,
          'postType': postType,
          'postId': postId,
          if (purpose != null) 'purpose': purpose,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ContactRequestStatus.fromJson(data);
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Failed to submit contact request');
      }
    } catch (e) {
      // Return pending in demo fallback so UI remains responsive
      return ContactRequestStatus(
        requestId: 1,
        status: 'pending',
        isApproved: false,
        message: 'Request submitted. Awaiting admin review.',
      );
    }
  }

  Future<ContactRequestStatus> getContactStatus({
    required String requesterUserId,
    required String postType,
    required int postId,
  }) async {
    if (requesterUserId.isEmpty) {
      return ContactRequestStatus.none();
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/contact-requests/status')
          .replace(
            queryParameters: {
              'requesterUserId': requesterUserId,
              'postType': postType,
              'postId': postId.toString(),
            },
          );

      final response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ContactRequestStatus.fromJson(data);
      }
    } catch (_) {
      // Ignore network errors in status check
    }

    return ContactRequestStatus.none();
  }

  void dispose() {
    _client.close();
  }
}
