import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../lookup/providers/lookup_provider.dart';
import '../providers/auth_provider.dart';

/// User registration screen.
///
/// Loads genders and cities from the backend, collects the user's details,
/// and calls [AuthProvider.register] which auto-logs the user in.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int? _genderId;
  int? _cityId;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loadAttempted = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    // Defer lookup loading to after the first frame so we don't call
    // setState/markNeedsBuild during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLookups();
    });
  }

  Future<void> _loadLookups() async {
    final lookup = context.read<LookupProvider>();
    // Only load once.
    if (lookup.genders.isNotEmpty || lookup.cities.isNotEmpty || _loadAttempted) {
      return;
    }
    _loadAttempted = true;
    await lookup.loadLookups();
    if (mounted) {
      setState(() {
        _loadError = lookup.error;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_genderId == null || _cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a gender and city.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      genderId: _genderId!,
      cityId: _cityId!,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        // Error is read from the provider below.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lookup = context.watch<LookupProvider>();
    final theme = Theme.of(context);

    // Prefer a provider-driven error if there is one.
    final visibleError = auth.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
        backgroundColor: AppConstants.primary,
      ),
      body: SafeArea(
        child: lookup.isLoading && lookup.genders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: AppConstants.pagePadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Join QuickWork',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppConstants.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create an account to publish jobs and apply for work.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // First & last name row.
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'First name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: _requiredField('first name'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Last name',
                              ),
                              validator: _requiredField('last name'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Username.
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: _requiredField('username'),
                      ),
                      const SizedBox(height: 16),

                      // Email.
                      TextFormField(
                        controller: _emailController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Please enter your email.';
                          final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
                          if (!emailOk) return 'Please enter a valid email.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone (optional).
                      TextFormField(
                        controller: _phoneController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone (optional)',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gender & city dropdowns.
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _genderId,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: Icon(Icons.wc_outlined),
                              ),
                              items: lookup.genders
                                  .map((g) => DropdownMenuItem<int>(
                                        value: g.id,
                                        child: Text(g.name),
                                      ))
                                  .toList(),
                              onChanged: lookup.genders.isEmpty
                                  ? null
                                  : (v) => setState(() => _genderId = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _cityId,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                prefixIcon: Icon(Icons.location_city_outlined),
                              ),
                              items: lookup.cities
                                  .map((c) => DropdownMenuItem<int>(
                                        value: c.id,
                                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: lookup.cities.isEmpty
                                  ? null
                                  : (v) => setState(() => _cityId = v),
                            ),
                          ),
                        ],
                      ),

                      if (_loadError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _loadError!,
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Password.
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 4) {
                            return 'Password must be at least 4 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm password.
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password.';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),

                      if (visibleError != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: theme.colorScheme.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  visibleError,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create account'),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pop(), // go back to login
                            child: const Text('Log in'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String? Function(String?) _requiredField(String label) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter your $label.';
      }
      return null;
    };
  }
}
