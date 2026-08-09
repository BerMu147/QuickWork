import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/constants/app_constants.dart';
import '../data/auth_repository.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';

/// Holds authentication state for the whole app and exposes login/logout.
///
/// On successful login the JWT token and user are persisted locally, so the
/// session survives app restarts until the user logs out.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository() {
    // Prepare the HTTP client (adds the bearer-token interceptor) once.
    ApiClient.instance.init();
  }

  final AuthRepository _repository;

  String? _token;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  UserModel? get user => _user;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Attempts to log the user in with the given credentials.
  ///
  /// Returns `true` on success. On failure sets [error] and returns `false`.
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.login(username: username, password: password);

      _token = result.token;
      _user = result.user;
      ApiClient.instance.setAuthToken(_token);

      await _persistSession();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registers a new user with the given details, then automatically logs
  /// them in so they can start using the app right away.
  ///
  /// Returns `true` on success. On failure sets [error] and returns `false`.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
    required int genderId,
    required int cityId,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.register(
        RegisterRequest(
          firstName: firstName,
          lastName: lastName,
          email: email,
          username: username,
          password: password,
          genderId: genderId,
          cityId: cityId,
          phoneNumber: phoneNumber,
        ),
      );

      // Auto-login the freshly created account.
      return await login(username: username, password: password);
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logs the user out, clearing the in-memory and persisted session.
  Future<void> logout() async {

    _token = null;
    _user = null;
    ApiClient.instance.setAuthToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.authTokenKey);
    await prefs.remove(AppConstants.authUserKey);
    notifyListeners();
  }

  /// Updates the in-memory + persisted user after a successful profile edit.
  Future<void> updateUser(UserModel user) async {
    _user = user;
    await _persistSession();
    notifyListeners();
  }

  /// Restores a previously persisted session (if any) at app start-up.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(AppConstants.authTokenKey);
    final savedUser = prefs.getString(AppConstants.authUserKey);

    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      ApiClient.instance.setAuthToken(_token);

      if (savedUser != null) {
        try {
          _user = UserModel.fromJson(
            jsonDecode(savedUser) as Map<String, dynamic>,
          );
        } catch (_) {
          // Ignore malformed cached user; only the token is restored.
        }
      }
      notifyListeners();
    }
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.authTokenKey, _token ?? '');
    if (_user != null) {
      await prefs.setString(AppConstants.authUserKey, jsonEncode({
        'id': _user!.id,
        'firstName': _user!.firstName,
        'lastName': _user!.lastName,
        'email': _user!.email,
        'username': _user!.username,
        'phoneNumber': _user!.phoneNumber,
        'genderId': _user!.genderId,
        'genderName': _user!.genderName,
        'cityId': _user!.cityId,
        'cityName': _user!.cityName,
        'roles': _user!.roles.map((r) => r.toJson()).toList(),
      }));
    }
  }
}

