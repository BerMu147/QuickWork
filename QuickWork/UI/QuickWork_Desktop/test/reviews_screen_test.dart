// Widget tests for the standalone ReviewsScreen (Bugfix 3).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_desktop/core/api/api_client.dart';
import 'package:quickwork_desktop/features/reviews/data/review_repository.dart';
import 'package:quickwork_desktop/features/reviews/models/review_model.dart';
import 'package:quickwork_desktop/features/reviews/providers/review_provider.dart';
import 'package:quickwork_desktop/features/reviews/screens/reviews_screen.dart';

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository({List<ReviewModel> reviews = const []})
      : _reviews = reviews;

  final List<ReviewModel> _reviews;

  @override
  Future<List<ReviewModel>> fetchReviewsForUser(int userId) async =>
      List.of(_reviews);

  @override
  Future<double> fetchAverageRating(int userId) async {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / _reviews.length;
  }
}

Widget _wrap(ReviewProvider reviewProvider) {
  return ChangeNotifierProvider<ReviewProvider>.value(
    value: reviewProvider,
    child: const MaterialApp(home: ReviewsScreen()),
  );
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.init();
  });

  testWidgets('ReviewsScreen shows an empty state when there are no reviews',
      (tester) async {
    final provider = ReviewProvider(repository: _FakeReviewRepository());
    await provider.loadForUser(2);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No reviews yet.'), findsOneWidget);
  });

  testWidgets('ReviewsScreen lists each received review individually',
      (tester) async {
    final reviews = [
      ReviewModel(
        id: 1,
        jobPostingId: 1,
        jobPostingTitle: 'Fix the roof',
        reviewerUserId: 3,
        reviewerUserName: 'Bob K.',
        reviewedUserId: 2,
        reviewedUserName: 'Jane Doe',
        rating: 4,
        comment: 'Punctual and skilled.',
      ),
      ReviewModel(
        id: 2,
        jobPostingId: 2,
        jobPostingTitle: 'Paint the fence',
        reviewerUserId: 4,
        reviewerUserName: 'Amy R.',
        reviewedUserId: 2,
        reviewedUserName: 'Jane Doe',
        rating: 5,
      ),
    ];
    final provider = ReviewProvider(
      repository: _FakeReviewRepository(reviews: reviews),
    );
    await provider.loadForUser(2);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    // Each reviewer + job + comment is listed.
    expect(find.text('Bob K.'), findsOneWidget);
    expect(find.text('Fix the roof'), findsOneWidget);
    expect(find.text('Punctual and skilled.'), findsOneWidget);
    expect(find.text('Amy R.'), findsOneWidget);
    expect(find.text('Paint the fence'), findsOneWidget);

    // The summary bar shows the aggregate average (4+5)/2 = 4.5.
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('2 reviews'), findsOneWidget);
  });
}
