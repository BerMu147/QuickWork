// Widget tests for the search / filter screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_mobile/core/api/api_client.dart';
import 'package:quickwork_mobile/features/jobs/data/job_posting_repository.dart';
import 'package:quickwork_mobile/features/jobs/models/category_model.dart';
import 'package:quickwork_mobile/features/jobs/providers/job_posting_provider.dart';
import 'package:quickwork_mobile/features/jobs/screens/search_job_screen.dart';
import 'package:quickwork_mobile/features/lookup/data/lookup_repository.dart';
import 'package:quickwork_mobile/features/lookup/models/city_model.dart';
import 'package:quickwork_mobile/features/lookup/models/gender_model.dart';
import 'package:quickwork_mobile/features/lookup/providers/lookup_provider.dart';

class _FakeJobRepo extends JobPostingRepository {
  @override
  Future<List<CategoryModel>> fetchCategories() async {
    return const [
      CategoryModel(id: 1, name: 'Electrician'),
      CategoryModel(id: 2, name: 'Babysitter'),
    ];
  }
}

class _FakeLookupRepo extends LookupRepository {
  @override
  Future<List<CityModel>> fetchCities() async {
    return const [
      CityModel(id: 1, name: 'Sarajevo'),
      CityModel(id: 2, name: 'Mostar'),
    ];
  }

  @override
  Future<List<GenderModel>> fetchGenders() async {
    return const [
      GenderModel(id: 1, name: 'Male'),
      GenderModel(id: 2, name: 'Female'),
    ];
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.init();
  });

  Future<void> pumpSearch(WidgetTester tester) async {
    final jobProvider = JobPostingProvider(repository: _FakeJobRepo());
    final lookupProvider = LookupProvider(repository: _FakeLookupRepo());

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<JobPostingProvider>.value(value: jobProvider),
        ChangeNotifierProvider<LookupProvider>.value(value: lookupProvider),
      ],
      child: const MaterialApp(home: SearchJobScreen()),
    ));
    // Let the lookups (categories + cities) load before the form renders.
    await tester.pumpAndSettle();
  }

  testWidgets('Search screen renders title, category, and city fields',
      (tester) async {
    await pumpSearch(tester);

    expect(find.text('Job title or keyword'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Search'), findsWidgets);
    expect(find.text('Clear filters'), findsOneWidget);

    // Categories and cities appear in the dropdown menus.
    expect(find.text('All categories'), findsOneWidget);
    expect(find.text('All cities'), findsOneWidget);
  });

  testWidgets('Search pops a query with a typed title', (tester) async {
    final jobProvider = JobPostingProvider(repository: _FakeJobRepo());
    final lookupProvider = LookupProvider(repository: _FakeLookupRepo());

    JobPostingQuery? poppedQuery;
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<JobPostingProvider>.value(value: jobProvider),
        ChangeNotifierProvider<LookupProvider>.value(value: lookupProvider),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                poppedQuery = await Navigator.of(context).push<JobPostingQuery>(
                  MaterialPageRoute(
                    builder: (_) => const SearchJobScreen(),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'Electrician',
    );
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(poppedQuery, isNotNull);
    expect(poppedQuery!.title, 'Electrician');
  });
}
