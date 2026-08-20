import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../models/admin_review_model.dart';
import '../providers/admin_provider.dart';

/// Reviews moderation screen.
///
/// Lists all reviews with an option to remove abusive ones.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      if (admin.reviews.isEmpty && !admin.isLoadingReviews) {
        admin.loadReviews();
      }
    });
  }

  Future<void> _load() => context.read<AdminProvider>().loadReviews();

  Future<void> _confirmAndDelete(AdminReviewModel review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove review'),
        content: Text(
          'Remove the ${review.rating}-star review on "${review.jobPostingTitle}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final admin = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await admin.removeReview(review);
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? 'Review removed.' : 'Failed to remove review.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: AppConstants.primary,
      ),
      body: admin.isLoadingReviews && admin.reviews.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : admin.reviewsError != null && admin.reviews.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(admin.reviewsError!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : admin.reviews.isEmpty
                  ? const Center(child: Text('No reviews found.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: admin.reviews.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final review = admin.reviews[index];
                          return _ReviewTile(
                            review: review,
                            onDelete: () => _confirmAndDelete(review),
                            deleting: admin.isDeletingReview,
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.review,
    required this.onDelete,
    required this.deleting,
  });

  final AdminReviewModel review;
  final VoidCallback onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat.yMMMd().format(review.createdAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 5; i++)
            SizedBox(
              height: 10,
              child: Icon(
                i < review.rating ? Icons.star : Icons.star_border,
                size: 14,
                color: i < review.rating ? Colors.amber : Colors.grey,
              ),
            ),
        ],
      ),
      title: Text(review.reviewerUserName),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To: ${review.reviewedUserName}'),
            Text('${review.jobPostingTitle} • $dateText'),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(review.comment!),
            ],
          ],
        ),
      ),
      isThreeLine: true,
      trailing: IconButton(
        tooltip: 'Remove review',
        onPressed: deleting ? null : onDelete,
        icon: Icon(
          Icons.delete_outline,
          color: deleting ? Colors.grey : Colors.red,
        ),
      ),
    );
  }
}
