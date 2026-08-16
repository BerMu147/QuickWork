import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// A modal form for leaving a 1–5 star review (with an optional comment for a
/// job you took part in and that has been completed.
class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({
    super.key,
    required this.reviewerName,
    required this.reviewedName,
    required this.jobTitle,
    required this.onSubmit,
    this.initialRating = 5,
    this.submitting = false,
    this.error,
  });

  /// Name of the person being reviewed (shown as a hint of "reviewing X").
  final String reviewedName;

  /// Name of the current user leaving the review (used for a subtitle).
  final String reviewerName;

  /// Title of the associated job.
  final String jobTitle;

  /// Called with the chosen rating and (trimmed, nullable) comment.
  final Future<void> Function(int rating, String? comment) onSubmit;

  final int initialRating;
  final bool submitting;
  final String? error;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  late int _rating;
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating.clamp(1, 5);
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    await widget.onSubmit(_rating, comment.isEmpty ? null : comment);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Leave a review',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: widget.submitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.jobTitle,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Reviewing: ${widget.reviewedName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppConstants.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            // Star picker.
            Center(
              child: _StarPicker(
                color: Colors.amber.shade700,
                size: 44,
                rating: _rating,
                onChanged: (r) => setState(() => _rating = r),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _ratingLabel(_rating),
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              enabled: !widget.submitting,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Tell us about your experience (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.error != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.submitting ? null : _submit,
              icon: widget.submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(widget.submitting ? 'Submitting...' : 'Submit review'),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int rating) => switch (rating) {
        1 => 'Poor',
        2 => 'Fair',
        3 => 'Good',
        4 => 'Very good',
        _ => 'Excellent',
      };
}

/// An interactive 1–5 star picker.
class _StarPicker extends StatelessWidget {
  const _StarPicker({
    required this.rating,
    required this.onChanged,
    this.color = Colors.amber,
    this.size = 44,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        return IconButton(
          onPressed: () => onChanged(star),
          iconSize: size,
          padding: const EdgeInsets.all(2),
          icon: Icon(
            star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: star <= rating ? color : Colors.grey[400],
          ),
        );
      }),
    );
  }
}
