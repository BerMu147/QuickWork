import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/models/user_skill_model.dart';
import '../../jobs/providers/job_posting_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/skill_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../reviews/providers/review_provider.dart';
import '../../reviews/screens/reviews_screen.dart';
import 'edit_profile_screen.dart';

/// The "Profile" tab — shows the logged-in user's information.
///
/// Login-gated: a guest opening this tab is prompted to log in.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _skillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ensure My Jobs data is loaded once the user is known, so the
    // completed-jobs stat below is accurate. Safe no-op for guests.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final jobProvider = context.read<JobPostingProvider>();
      final skillProvider = context.read<SkillProvider>();
      final reviewProvider = context.read<ReviewProvider>();
      if (auth.user != null) {
        jobProvider.loadMyJobs(auth.user!.id);
        skillProvider.loadSkills(auth.user!.id);
        reviewProvider.loadForUser(auth.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  /// Adds a skill from the text field for the logged-in user.
  Future<void> _addSkill(BuildContext context) async {
    final name = _skillController.text.trim();
    if (name.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final skillProvider = context.read<SkillProvider>();
    if (auth.user == null) return;

    // Capture UI references before the async gap to avoid using the
    // BuildContext after awaiting.
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final ok = await skillProvider.addSkill(
      userId: auth.user!.id,
      skillName: name,
    );
    if (!mounted) return;

    if (ok) {
      _skillController.clear();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(skillProvider.error ?? 'Unable to add the skill.'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  /// Deletes a skill for the logged-in user.
  Future<void> _deleteSkill(
    BuildContext context,
    SkillProvider skillProvider,
    int id,
  ) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    await skillProvider.deleteSkill(id: id, userId: auth.user!.id);
  }

  /// Opens the full-page reviews list (all reviews received by this user).
  void _openReviews() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReviewsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final jobs = context.watch<JobPostingProvider>();
    final skills = context.watch<SkillProvider>();
    final reviews = context.watch<ReviewProvider>();
    final theme = Theme.of(context);

    if (!auth.isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Log in to see your profile.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Log in'),
              ),
            ],
          ),
        ),
      );
    }

    final user = auth.user!;

    return ListView(
      padding: AppConstants.pagePadding,
      children: [
        const SizedBox(height: 16),
        // Avatar + name header.
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppConstants.primary,
            child: Text(
              _initials(user.firstName, user.lastName),
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user.fullName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppConstants.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: Text(
            '@${user.username}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
        ),
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              user.bio!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Completed jobs stat card.
        Card(
          elevation: 1,
          color: const Color(0x0F129ACA),
          child: ListTile(
            leading: const Icon(Icons.verified_outlined,
                color: AppConstants.primary),
            title: Text(
              '${jobs.completedJobsCount}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppConstants.primary,
              ),
            ),
            subtitle: const Text('Completed jobs'),
            trailing: jobs.isLoadingMyJobs
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 24),

        // Work history card — lists platform-verified completed work
        // (published jobs marked Completed + hired jobs accepted as a worker).
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.work_history_outlined,
                        color: AppConstants.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Work history',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (jobs.isLoadingMyJobs)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildWorkHistory(jobs),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Reviews & rating card — shows the average rating the user has
        // received and the individual reviews left for them.
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
                    const Spacer(),
                    if (reviews.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildReviews(reviews),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Skills card (add + list custom skills).
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
                    const Spacer(),
                    if (skills.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (skills.skills.isEmpty)
                  Text(
                    'No skills yet. Add a skill so publishers know what you can do.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.skills
                        .map((s) => _SkillChip(
                              skill: s,
                              deleting:
                                  skills.deletingId == s.id,
                              onDelete: () =>
                                  _deleteSkill(context, skills, s.id),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skillController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Add a skill (e.g. Plumbing)',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addSkill(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    skills.isAdding
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            onPressed: () => _addSkill(context),
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppConstants.primary),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // User details card.
        Card(
          elevation: 1,
          child: Column(
            children: [
              _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
              _divider(),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user.phoneNumber?.isNotEmpty == true
                    ? user.phoneNumber!
                    : '—',
              ),
              _divider(),
              _InfoRow(
                icon: Icons.location_city_outlined,
                label: 'City',
                value: user.cityName,
              ),
              _divider(),
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Gender',
                value: user.genderName,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Edit profile button.
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit profile'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _initials(String firstName, String lastName) {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  Widget _divider() => const Divider(height: 1);

  /// Builds the list of platform-verified "work history" items.
  ///
  /// Combines jobs the user **published** that were marked Completed with the
  /// jobs they were **hired for** (accepted application). Each entry renders
  /// the job title with a check icon.
  Widget _buildWorkHistory(JobPostingProvider jobs) {
    final items = <String>[];

    // Published jobs marked Completed.
    for (final j in jobs.myJobPostings) {
      if (j.status.toLowerCase() == 'completed') {
        items.add(j.title);
      }
    }

    // Hired-for jobs (accepted applications) as a worker.
    for (final a in jobs.myApplications) {
      if (a.status.toLowerCase() == 'accepted') {
        items.add(a.jobPostingTitle);
      }
    }

    // De-duplicate while preserving order (a job could appear in both lists).
    final unique = <String>[];
    final seen = <String>{};
    for (final t in items) {
      if (seen.add(t)) unique.add(t);
    }

    if (unique.isEmpty) {
      return Text(
        'No completed work yet. Finish jobs to build your work history here.',
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      );
    }

    return Column(
      children: unique
          .map((title) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 18, color: AppConstants.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  /// Builds the "Reviews & rating" content: a single aggregate average rating
  /// as stars plus the review count, with a "See reviews" button that opens the
  /// full-page Reviews screen listing each review individually.
  Widget _buildReviews(ReviewProvider reviews) {
    final average = reviews.averageRating;
    final hasReviews = reviews.reviews.isNotEmpty;

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
                ? '${reviews.reviews.length} '
                    '${reviews.reviews.length == 1 ? 'review' : 'reviews'}'
                : 'No reviews yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: hasReviews ? _openReviews : null,
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('See reviews'),
          ),
        ),
      ],
    );
  }

  ThemeData get theme => Theme.of(context);
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

/// A single skill chip with a delete (✕) action.
class _SkillChip extends StatelessWidget {
  const _SkillChip({
    required this.skill,
    required this.onDelete,
    this.deleting = false,
  });

  final UserSkillModel skill;
  final VoidCallback onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(skill.skillName),
      deleteIcon: deleting
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.close, size: 16),
      onDeleted: deleting ? null : onDelete,
      backgroundColor: const Color(0x14129ACA),
      deleteIconColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        side: const BorderSide(color: AppConstants.primary),
      ),
    );
  }
}
