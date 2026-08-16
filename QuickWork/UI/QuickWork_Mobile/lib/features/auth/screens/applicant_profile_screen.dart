import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../jobs/data/job_posting_repository.dart';
import '../../jobs/models/job_application_model.dart';
import '../../jobs/models/job_posting_model.dart';
import '../../reviews/data/review_repository.dart';
import '../../reviews/models/review_model.dart';
import '../data/user_repository.dart';
import '../data/user_skill_repository.dart';
import '../models/user_model.dart';
import '../models/user_skill_model.dart';

/// Read-only profile overview for a user (e.g. a job applicant viewed by a
/// publisher). Loads the target user's own data locally, so it never touches
/// (or clobbers) the signed-in user's shared SkillProvider / ReviewProvider.
///
/// Shows: name, username, city, bio, custom skills, average rating + received
/// reviews, and a platform-verified completed-jobs count.
class ApplicantProfileScreen extends StatefulWidget {
  const ApplicantProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userRepository,
    this.skillRepository,
    this.reviewRepository,
    this.jobRepository,
  });

  final int userId;
  final String userName;

  /// Optional repository overrides (used by tests to avoid a live backend).
  final UserRepository? userRepository;
  final UserSkillRepository? skillRepository;
  final ReviewRepository? reviewRepository;
  final JobPostingRepository? jobRepository;

  @override
  State<ApplicantProfileScreen> createState() => _ApplicantProfileScreenState();
}

/// Bundles everything the applicant screen needs to render, fetched in
/// parallel from the respective repositories.
class _ApplicantData {
  const _ApplicantData({
    required this.user,
    required this.skills,
    required this.reviews,
    required this.averageRating,
    required this.completedJobsCount,
    required this.workHistory,
  });

  final UserModel? user;
  final List<UserSkillModel> skills;
  final List<ReviewModel> reviews;
  final double averageRating;
  final int completedJobsCount;
  final List<String> workHistory;
}

class _ApplicantProfileScreenState extends State<ApplicantProfileScreen> {
  late final UserRepository _userRepository =
      widget.userRepository ?? UserRepository();
  late final UserSkillRepository _skillRepository =
      widget.skillRepository ?? UserSkillRepository();
  late final ReviewRepository _reviewRepository =
      widget.reviewRepository ?? ReviewRepository();
  late final JobPostingRepository _jobRepository =
      widget.jobRepository ?? JobPostingRepository();

  late Future<_ApplicantData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<_ApplicantData> _load() async {
    final results = await Future.wait<dynamic>([
      _userRepository.fetchUser(widget.userId),
      _skillRepository.fetchSkillsForUser(widget.userId),
      _reviewRepository.fetchReviewsForUser(widget.userId),
      _reviewRepository.fetchAverageRating(widget.userId),
      _jobRepository.fetchJobsForUser(widget.userId),
      _jobRepository.fetchApplicationsForUser(widget.userId),
    ]);

    UserModel? user;
    try {
      user = results[0] as UserModel?;
    } catch (_) {
      // User fetch may fail (e.g. restricted); keep null and fall back.
    }
    final skills = results[1] as List<UserSkillModel>;
    final reviews = results[2] as List<ReviewModel>;
    final averageRating = results[3] as double;
    final publishedJobs = results[4] as List<JobPostingModel>;
    final applications = results[5] as List<JobApplicationModel>;

    // Completed-jobs count + work history (same definition as the logged-in
    // user's profile): published jobs marked Completed + accepted applications.
    final workHistory = <String>[];
    for (final j in publishedJobs) {
      if (j.status.toLowerCase() == 'completed') {
        workHistory.add(j.title);
      }
    }
    for (final a in applications) {
      if (a.status.toLowerCase() == 'accepted') {
        workHistory.add(a.jobPostingTitle);
      }
    }
    final uniqueHistory = <String>[];
    final seen = <String>{};
    for (final t in workHistory) {
      if (seen.add(t)) uniqueHistory.add(t);
    }

    return _ApplicantData(
      user: user,
      skills: skills,
      reviews: reviews,
      averageRating: averageRating,
      completedJobsCount: uniqueHistory.length,
      workHistory: uniqueHistory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userName.isEmpty ? 'Applicant profile' : widget.userName,
        ),
        backgroundColor: AppConstants.primary,
      ),
      body: FutureBuilder<_ApplicantData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(onRetry: _reload);
          }
          final data = snapshot.data;
          if (data == null) {
            return _ErrorState(onRetry: _reload);
          }
          return _buildContent(theme, data);
        },
      ),
    );
  }

  Widget _buildContent(ThemeData theme, _ApplicantData data) {
    final user = data.user;

    return ListView(
      padding: AppConstants.pagePadding,
      children: [
        const SizedBox(height: 16),
        // Avatar + name header.
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppConstants.primary,
            child: Text(
              _initials(user?.firstName ?? '', user?.lastName ?? '').isNotEmpty
                  ? _initials(user!.firstName, user.lastName)
                  : _initialsFromName(widget.userName),
              style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user?.fullName ?? widget.userName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppConstants.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: Text(
            user != null && user.username.isNotEmpty
                ? '@${user.username}'
                : '',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ),
        if (user?.bio != null && user!.bio!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            user.bio!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Completed jobs stat.
        Card(
          elevation: 1,
          color: const Color(0x0F129ACA),
          child: ListTile(
            leading: const Icon(Icons.verified_outlined,
                color: AppConstants.primary),
            title: Text(
              '${data.completedJobsCount}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppConstants.primary,
              ),
            ),
            subtitle: const Text('Completed jobs'),
          ),
        ),
        const SizedBox(height: 24),

        // Reviews & rating (aggregate + list).
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_outline,
                        color: AppConstants.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Reviews & rating',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildReviews(data),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Skills card.
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_outlined,
                        color: AppConstants.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Skills',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (data.skills.isEmpty)
                  Text(
                    'No skills added yet.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.skills
                        .map((s) => _ReadOnlyChip(label: s.skillName))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Location / user details card (city + email).
        Card(
          elevation: 1,
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.location_city_outlined,
                label: 'City',
                value: user?.cityName.isNotEmpty == true
                    ? user!.cityName
                    : '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Builds the reviews section for the applicant: average rating as stars plus
  /// the received reviews they've got.
  Widget _buildReviews(_ApplicantData data) {
    final average = data.averageRating;
    final hasReviews = data.reviews.isNotEmpty;

    final ratingRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (i) {
          final filled = average >= i + 1;
          return Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: filled ? Colors.amber.shade700 : Colors.grey[400],
            size: 30,
          );
        }),
        const SizedBox(width: 12),
        Text(
          average.toStringAsFixed(1),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppConstants.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ratingRow,
        const SizedBox(height: 4),
        Center(
          child: Text(
            hasReviews
                ? '${data.reviews.length} '
                    '${data.reviews.length == 1 ? 'review' : 'reviews'}'
                : 'No reviews yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        if (hasReviews) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 4),
          ...data.reviews.map((r) => _ReviewTile(review: r)),
        ],
      ],
    );
  }

  String _initials(String firstName, String lastName) {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '';
    final last = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$last'.toUpperCase();
  }
}

/// Simple retry / error state used when the applicant data fails to load.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Unable to load the applicant profile.'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// A non-interactive chip used to render a skill on the read-only screen.
class _ReadOnlyChip extends StatelessWidget {
  const _ReadOnlyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color(0x14129ACA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        side: const BorderSide(color: AppConstants.primary),
      ),
    );
  }
}

/// A single review received by the applicant: reviewer name, star rating,
/// comment and the job it relates to.
class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(review.reviewerUserName);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppConstants.primary,
                child: Text(
                  initials,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
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
                    Text(
                      review.jobPostingTitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = review.rating >= i + 1;
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 14,
                    color: filled ? Colors.amber.shade700 : Colors.grey[400],
                  );
                }),
              ),
            ],
          ),
          if (review.comment?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Text(
                review.comment!,
                style: theme.textTheme.bodySmall,
              ),
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

/// A single info row (icon + label + value).
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppConstants.primary),
      title: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }
}
