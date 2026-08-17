import 'package:flutter/foundation.dart';

import '../../../core/api/api_exceptions.dart';
import '../data/message_repository.dart';
import '../models/message_model.dart';

/// Manages a single per-job conversation thread between the current user and
/// the other party (publisher <-> worker).
class MessageProvider extends ChangeNotifier {
  MessageProvider({MessageRepository? repository})
      : _repository = repository ?? MessageRepository();

  final MessageRepository _repository;

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  /// Clears the current conversation thread so a subsequent [loadThread]
  /// starts fresh (used when switching users on logout).
  void clear() {
    _messages = [];
    _error = null;
    notifyListeners();
  }

  /// Loads the thread for a job between [myUserId] and [otherUserId].
  Future<void> loadThread({
    required int jobPostingId,
    required int myUserId,
    required int otherUserId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _repository.fetchThread(
        jobPostingId: jobPostingId,
        senderUserId: myUserId,
        receiverUserId: otherUserId,
      );
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Unable to load messages. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks all messages addressed to [myUserId] as read (fire-and-forget).
  Future<void> markIncomingAsRead({required int myUserId}) async {
    final incoming =
        _messages.where((m) => m.receiverUserId == myUserId && !m.isRead);
    for (final m in incoming) {
      try {
        await _repository.markAsRead(m.id);
        final index = _messages.indexWhere((x) => x.id == m.id);
        if (index != -1) {
          _messages = [..._messages]..[index] = MessageModel(
              id: m.id,
              jobPostingId: m.jobPostingId,
              jobPostingTitle: m.jobPostingTitle,
              senderUserId: m.senderUserId,
              senderUserName: m.senderUserName,
              receiverUserId: m.receiverUserId,
              receiverUserName: m.receiverUserName,
              content: m.content,
              sentAt: m.sentAt,
              isRead: true,
            );
        }
      } on ApiException {
        // Non-critical; ignore read-marking failures.
      }
    }
    notifyListeners();
  }

  /// Sends a message and appends it to the thread.
  ///
  /// Returns true on success, false on failure (error in [error]).
  Future<bool> sendMessage({
    required int jobPostingId,
    required int myUserId,
    required int otherUserId,
    required String content,
  }) async {
    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final sent = await _repository.sendMessage(
        jobPostingId: jobPostingId,
        senderUserId: myUserId,
        receiverUserId: otherUserId,
        content: content,
      );
      _messages = [..._messages, sent];
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Unable to send your message. Please try again.';
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
