import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../lookup/providers/lookup_provider.dart';
import '../data/job_posting_repository.dart';
import '../providers/job_posting_provider.dart';

/// A dedicated search + filter screen for job postings.
///
/// Collects a free-text title, a category and a city, and pops a
/// [JobPostingQuery] back to the caller. Popping `null` means "clear filters".
class SearchJobScreen extends StatefulWidget {
  const SearchJobScreen({super.key, this.initialQuery});

  /// The currently applied query (to pre-fill the form if re-opening).
  final JobPostingQuery? initialQuery;

  @override
  State<SearchJobScreen> createState() => _SearchJobScreenState();
}

class _SearchJobScreenState extends State<SearchJobScreen> {
  final _titleController = TextEditingController();
  int? _categoryId;
  int? _cityId;

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialQuery?.title ?? '';
    _categoryId = widget.initialQuery?.categoryId;
    _cityId = widget.initialQuery?.cityId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureLookups();
    });
  }

  Future<void> _ensureLookups() async {
    if (_loaded) return;
    _loaded = true;

    final jobProvider = context.read<JobPostingProvider>();
    final lookupProvider = context.read<LookupProvider>();

    // Categories require authentication (same as the publish flow).
    if (jobProvider.categories.isEmpty) {
      await jobProvider.loadCategories();
    }
    if (lookupProvider.cities.isEmpty) {
      await lookupProvider.loadLookups();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _search() {
    final query = JobPostingQuery(
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      categoryId: _categoryId,
      cityId: _cityId,
      // Search always targets open jobs.
      status: 'Open',
    );
    Navigator.of(context).pop(query);
  }

  void _clear() {
    _titleController.clear();
    setState(() {
      _categoryId = null;
      _cityId = null;
    });
    // Let the caller reset to the unfiltered list.
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobPostingProvider>();
    final lookupProvider = context.watch<LookupProvider>();

    final categories = jobProvider.categories;
    final cities = lookupProvider.cities;
    final loading = jobProvider.categories.isEmpty && lookupProvider.cities.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search jobs'),
        backgroundColor: AppConstants.primary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppConstants.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Free-text title search.
                  TextField(
                    controller: _titleController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      labelText: 'Job title or keyword',
                      prefixIcon: Icon(Icons.search),
                      hintText: 'e.g. Electrician, Babysitter...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category dropdown.
                  DropdownButtonFormField<int?>(
                    value: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ...categories.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  const SizedBox(height: 16),

                  // City dropdown.
                  DropdownButtonFormField<int?>(
                    value: _cityId,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All cities'),
                      ),
                      ...cities.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _cityId = v),
                  ),
                  const SizedBox(height: 32),

                  // Actions.
                  ElevatedButton.icon(
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear filters'),
                  ),
                ],
              ),
            ),
    );
  }
}
