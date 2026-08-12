import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../models/message_model.dart';

/// Fetches and sends per-job messages between a publisher and a worker.
class MessageRepository {
  MessageRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Returns all messages for [jobPostingId] exchanged between [senderUserId]
  /// and [receiverUserId]. Ordered by the backend by sent date (newest first).
  Future<List<MessageModel>> fetchThread({
    required int jobPostingId,
    required int senderUserId,
    required int receiverUserId,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/Messages',
        queryParameters: {
          'JobPostingId': jobPostingId,
          'RetrieveAll': true,
          'IncludeTotalCount': true,
        },
      );

      final items = response.data?['items'] as List<dynamic>? ?? [];
      final all = items
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Keep only messages in this specific two-person conversation.
      return all
          .where((m) =>
              (m.senderUserId == senderUserId &&
                  m.receiverUserId == receiverUserId) ||
              (m.senderUserId == receiverUserId &&
                  m.receiverUserId == senderUserId))
          .toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt)); // chronological order
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Sends a message from [senderUserId] to [receiverUserId] about the job.
  Future<MessageModel> sendMessage({
    required int jobPostingId,
    required int senderUserId,
    required int receiverUserId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/Messages',
        queryParameters: {'senderUserId': senderUserId},
        data: {
          'jobPostingId': jobPostingId,
          'receiverUserId': receiverUserId,
          'content': content,
        },
      );
      return MessageModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Marks a message as read.
  Future<MessageModel> markAsRead(int messageId) async {
    try {
      final response =
          await _apiClient.dio.patch<Map<String, dynamic>>('/Messages/$messageId/mark-as-read');
      return MessageModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
