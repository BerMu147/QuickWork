import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../models/review_model.dart';
import '../providers/review_provider.dart';

/// A full-page list of the reviews a user has received. Opened from the
/// profile's "Reviews & rating" card via the "See reviews" button.
///
/// Reads the reviews from the shared [ReviewProvider], so it reflects the same
/// per-current-user data the profile shows (and which, on logout, is cleared).
class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: AppConstants.primary,
      ),
      body: reviews.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reviews.reviews.isEmpty
              ? _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.reviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final review = reviews.reviews[index];
                    return _ReviewTile(review: review);
                  },
                ),
      bottomNavigationBar: reviews.reviews.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _SummaryBar(reviews: reviews),
              ),
            ),
    );
  }
}

/// A single review received by the user: reviewer name, star rating, job title
/// and comment.
class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppConstants.primary,
                child: Text(
                  _initials(review.reviewerUserName),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerUserName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        final filled = review.rating >= i + 1;
                        return Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 16,
                          color: filled
                              ? Colors.amber.shade700
                              : Colors.grey[400],
                        );
                      }),
                    ),
                    if (review.jobPostingTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        review.jobPostingTitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (review.reviewedUserName.isNotEmpty)
                Text(
                  review.reviewedUserName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          if (review.comment?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '';
    final last = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$last'.toUpperCase();
  }
}

/// A small summary bar pinned at the bottom showing the average + count.
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.reviews});

  final ReviewProvider reviews;

  @override
  Widget build(BuildContext context) {
    final average = reviews.averageRating;
    final count = reviews.reviews.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (i) {
          final filled = average >= i + 1;
          return Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: filled ? Colors.amber.shade700 : Colors.grey[400],
            size: 18,
          );
        }),
        const SizedBox(width: 8),
        Text(
          average.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          '$count ${count == 1 ? 'review' : 'reviews'}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }
}

/// Empty state shown when a user has no received reviews.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.star_border_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'No reviews yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        const Text(
          'Reviews left by others after completing a job will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }
}
