import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../lookup/providers/lookup_provider.dart';
import '../models/job_posting_upsert_request.dart';
import '../providers/job_posting_provider.dart';

/// Form for logged-in users to publish a new job posting.
///
/// Requires authentication: the user must be logged in (and authenticated) to
/// create a job. Category lookup also requires auth.
class PublishJobScreen extends StatefulWidget {
  const PublishJobScreen({super.key});

  @override
  State<PublishJobScreen> createState() => _PublishJobScreenState();
}

class _PublishJobScreenState extends State<PublishJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _paymentController = TextEditingController();
  final _durationController = TextEditingController();

  int? _categoryId;
  int? _cityId;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<JobPostingProvider>();
      if (provider.categories.isEmpty) provider.loadCategories();
      // Ensure cities are loaded for the dropdown.
      final lookup = context.read<LookupProvider>();
      if (lookup.cities.isEmpty) lookup.loadLookups();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _paymentController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a category and a city.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final provider = context.read<JobPostingProvider>();

    final request = JobPostingUpsertRequest(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: _categoryId!,
      cityId: _cityId!,
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      paymentAmount: double.parse(_paymentController.text.trim()),
      estimatedDurationHours: _durationController.text.trim().isEmpty
          ? null
          : double.parse(_durationController.text.trim()),
      scheduledDate: _scheduledDate,
      scheduledTimeStart: _startTime == null
          ? null
          : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00',
      scheduledTimeEnd: _endTime == null
          ? null
          : '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00',
    );

    final success = await provider.publishJob(
      request: request,
      postedByUserId: auth.user?.id ?? 0,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job published successfully!')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobPostingProvider>();
    final lookup = context.watch<LookupProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish a job'),
        backgroundColor: AppConstants.primary,
      ),
      body: provider.isPublishing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppConstants.pagePadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'New job posting',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppConstants.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title.
                    TextFormField(
                      controller: _titleController,
                      maxLength: 200,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Job title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter a title.' : null,
                    ),
                    const SizedBox(height: 12),

                    // Description.
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a description.'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Category & City.
                    DropdownButtonFormField<int>(
                      value: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: provider.categories
                          .map((c) => DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: provider.categories.isEmpty
                          ? null
                          : (v) => setState(() => _categoryId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _cityId,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      items: lookup.cities
                          .map((c) => DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: lookup.cities.isEmpty
                          ? null
                          : (v) => setState(() => _cityId = v),
                    ),
                    const SizedBox(height: 12),

                    // Address.
                    TextFormField(
                      controller: _addressController,
                      maxLength: 300,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Address (optional)',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Payment & duration row.
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _paymentController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Payment (KM)',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter payment.';
                              }
                              final n = double.tryParse(v.trim());
                              if (n == null || n <= 0) {
                                return 'Invalid amount.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Duration (h)',
                              prefixIcon: Icon(Icons.timelapse),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Scheduled date.
                    _PickerTile(
                      label: 'Scheduled date',
                      valueText: DateFormat('dd.MM.yyyy').format(_scheduledDate),
                      icon: Icons.event,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 8),

                    // Start / end time.
                    Row(
                      children: [
                        Expanded(
                          child: _PickerTile(
                            label: 'Start time',
                            valueText: _startTime?.format(context) ??
                                'Not set',
                            icon: Icons.access_time,
                            onTap: () => _pickTime(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PickerTile(
                            label: 'End time',
                            valueText:
                                _endTime?.format(context) ?? 'Not set',
                            icon: Icons.access_time_filled,
                            onTap: () => _pickTime(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (provider.publishError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius:
                              BorderRadius.circular(AppConstants.defaultRadius),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.publishError!,
                                style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.publish),
                      label: const Text('Publish job'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// A tappable tile used to pick a date or time.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.valueText,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String valueText;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        child: Row(
          children: [
            Expanded(child: Text(valueText)),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
