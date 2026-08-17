import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/message_model.dart';
import '../providers/message_provider.dart';

/// A per-job chat thread between the current user and [otherUserId].
///
/// Reached from the job detail page (worker -> publisher) or the review
/// applications screen (publisher -> worker).
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.jobPostingId,
    required this.jobTitle,
    required this.otherUserId,
    required this.otherUserName,
  });

  final int jobPostingId;
  final String jobTitle;
  final int otherUserId;
  final String otherUserName;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  int get _myUserId => context.read<AuthProvider>().user?.id ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final p = context.read<MessageProvider>();
    await p.loadThread(
      jobPostingId: widget.jobPostingId,
      myUserId: _myUserId,
      otherUserId: widget.otherUserId,
    );
    // Mark any incoming messages as read.
    await p.markIncomingAsRead(myUserId: _myUserId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final p = context.read<MessageProvider>();
    final ok = await p.sendMessage(
      jobPostingId: widget.jobPostingId,
      myUserId: _myUserId,
      otherUserId: widget.otherUserId,
      content: text,
    );

    if (!mounted) return;
    if (ok) {
      _controller.clear();
      _scrollToBottom();
    } else if (p.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(p.error!)),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MessageProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName,
                style: const TextStyle(fontSize: 17)),
            Text(
              widget.jobTitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[300]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: AppConstants.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(p, theme),
          ),
          _MessageInput(
            controller: _controller,
            isSending: p.isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(MessageProvider p, ThemeData theme) {
    if (p.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (p.error != null && p.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(p.error!, textAlign: TextAlign.center),
        ),
      );
    }

    if (p.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text(
                'No messages yet.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Send ${widget.otherUserName} a message to coordinate the details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: p.messages.length,
      itemBuilder: (context, index) {
        final msg = p.messages[index];
        final isMine = msg.senderUserId == _myUserId;
        return _MessageBubble(message: msg, isMine: isMine);
      },
    );
  }
}

/// A single chat bubble.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final MessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = '${message.sentAt.hour.toString().padLeft(2, '0')}:'
        '${message.sentAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? AppConstants.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 2),
            bottomRight: Radius.circular(isMine ? 2 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMine
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bottom text field + send button.
class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => isSending ? null : onSend,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
