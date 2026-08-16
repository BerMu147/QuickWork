import 'package:flutter/foundation.dart';

import '../../../core/api/api_exceptions.dart';
import '../data/user_skill_repository.dart';
import '../models/user_skill_model.dart';

/// Holds the current user's custom skills and manages add/delete actions.
class SkillProvider extends ChangeNotifier {
  SkillProvider({UserSkillRepository? repository})
      : _repository = repository ?? UserSkillRepository();

  final UserSkillRepository _repository;

  List<UserSkillModel> _skills = [];
  bool _isLoading = false;
  bool _isAdding = false;
  int? _deletingId;
  String? _error;

  List<UserSkillModel> get skills => _skills;
  bool get isLoading => _isLoading;
  bool get isAdding => _isAdding;
  int? get deletingId => _deletingId;
  String? get error => _error;

  /// Loads the custom skills for [userId] from the backend.
  Future<void> loadSkills(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _skills = await _repository.fetchSkillsForUser(userId);
    } on ApiException {
      // Keep existing list on failure; not critical.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new skill for [userId]. Returns true on success, false on failure
  /// (error stored in [error]).
  Future<bool> addSkill({
    required int userId,
    required String skillName,
  }) async {
    _isAdding = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _repository.addSkill(
        userId: userId,
        skillName: skillName,
      );
      _skills = [..._skills, created];
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Unable to add the skill. Please try again.';
      return false;
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  /// Clears the cached skills so a subsequent [loadSkills] starts fresh. Used
  /// when switching users (e.g. on logout) so one account's skills never leak
  /// into another account's profile.
  void clear() {
    _skills = [];
    _error = null;
    notifyListeners();
  }

  /// Deletes a skill by its [id]. Returns true on success, false on failure
  /// (error stored in [error]).
  Future<bool> deleteSkill({
    required int id,
    required int userId,
  }) async {
    _deletingId = id;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteSkill(id: id, userId: userId);
      _skills = _skills.where((s) => s.id != id).toList();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Unable to delete the skill. Please try again.';
      return false;
    } finally {
      _deletingId = null;
      notifyListeners();
    }
  }
}
