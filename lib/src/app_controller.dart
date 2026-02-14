import 'package:flutter/foundation.dart';

import 'data/app_repository.dart';
import 'models/domain_models.dart';
import 'services/history_service.dart';
import 'services/recommendation_service.dart';
import 'services/statistics_service.dart';
import 'services/training_planning_service.dart';

/// App-wide state container coordinating repository + domain services.
class AppController extends ChangeNotifier {
  /// Creates a controller.
  AppController({
    required final AppRepository repository,
    final RecommendationService recommendationService =
        const RecommendationService(),
    final TrainingPlanningService planningService =
        const TrainingPlanningService(),
    final HistoryService historyService = const HistoryService(),
    final StatisticsService statisticsService = const StatisticsService(),
  }) : _repository = repository,
       _recommendationService = recommendationService,
       _planningService = planningService,
       _historyService = historyService,
       _statisticsService = statisticsService;

  final AppRepository _repository;
  final RecommendationService _recommendationService;
  final TrainingPlanningService _planningService;
  final HistoryService _historyService;
  final StatisticsService _statisticsService;

  bool _isInitializing = true;
  bool _isBusy = false;
  String? _errorMessage;

  UserProfile? _currentUser;
  bool _requiresPrimaryGoalOnboarding = false;
  List<UserProfile> _recentUsers = <UserProfile>[];
  List<Exercise> _exercises = <Exercise>[];
  List<TrainingSession> _sessions = <TrainingSession>[];

  /// Whether initial app data is still being loaded.
  bool get isInitializing => _isInitializing;

  /// Whether a command is currently running.
  bool get isBusy => _isBusy;

  /// Current operational error message, if any.
  String? get errorMessage => _errorMessage;

  /// Currently logged in user.
  UserProfile? get currentUser => _currentUser;

  /// Whether the current user must complete first-login goal selection.
  bool get requiresPrimaryGoalOnboarding => _requiresPrimaryGoalOnboarding;

  /// Active user's preferred goal fallback for defaults.
  TrainingGoal get preferredGoal {
    return _currentUser?.primaryGoal ?? TrainingGoal.muscleGain;
  }

  /// Recent users for quick login.
  List<UserProfile> get recentUsers => List<UserProfile>.from(_recentUsers);

  /// Complete exercise catalog.
  List<Exercise> get exercises => List<Exercise>.from(_exercises);

  /// Current user's sessions ordered from latest to oldest.
  List<TrainingSession> get sessions => List<TrainingSession>.from(_sessions);

  /// Current user's summary statistics.
  TrainingStatistics get statistics {
    return _statisticsService.calculate(
      sessions: _sessions,
      now: DateTime.now(),
    );
  }

  /// Loads initial app data.
  Future<void> initialize() async {
    _setBusy(true);
    _errorMessage = null;

    try {
      _exercises = await _repository.getExercises(refresh: true);
      _recentUsers = await _repository.getRecentUsers(limit: 3);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isInitializing = false;
      _setBusy(false);
    }
  }

  /// Logs in or creates a user profile by username.
  Future<void> loginOrCreateUser(final String username) async {
    final String normalized = username.trim();
    if (normalized.isEmpty) {
      _errorMessage = 'Username cannot be empty.';
      notifyListeners();
      return;
    }

    _setBusy(true);
    _errorMessage = null;

    try {
      final LoginResult loginResult = await _repository.loginOrCreateUser(
        username: normalized,
      );
      _currentUser = loginResult.user;
      _requiresPrimaryGoalOnboarding = loginResult.isNewUser;
      _recentUsers = await _repository.getRecentUsers(limit: 3);
      _sessions = await _repository.getSessionsForUser(
        userId: _currentUser!.id,
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setBusy(false);
    }
  }

  /// Logs in with an existing user option.
  Future<void> loginWithExistingUser(final UserProfile user) {
    return loginOrCreateUser(user.username);
  }

  /// Logs out and clears user-specific state.
  void logout() {
    _currentUser = null;
    _requiresPrimaryGoalOnboarding = false;
    _sessions = <TrainingSession>[];
    _errorMessage = null;
    notifyListeners();
  }

  /// Updates current user's primary goal and refreshes visible user lists.
  Future<void> updateCurrentUserPrimaryGoal(final TrainingGoal goal) async {
    if (_currentUser == null) {
      return;
    }
    if (_currentUser!.primaryGoal == goal) {
      if (_requiresPrimaryGoalOnboarding) {
        _requiresPrimaryGoalOnboarding = false;
        notifyListeners();
      }
      return;
    }

    _setBusy(true);
    _errorMessage = null;
    try {
      final UserProfile updated = await _repository.updateUserPrimaryGoal(
        userId: _currentUser!.id,
        primaryGoal: goal,
      );
      _currentUser = updated;
      _recentUsers = await _repository.getRecentUsers(limit: 3);
      _requiresPrimaryGoalOnboarding = false;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setBusy(false);
    }
  }

  /// Refreshes exercise catalog from persistence.
  Future<void> refreshExercises() async {
    _setBusy(true);
    _errorMessage = null;

    try {
      _exercises = await _repository.getExercises(refresh: true);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setBusy(false);
    }
  }

  /// Adds a new exercise and refreshes the catalog.
  Future<void> addExercise(final Exercise exercise) async {
    _setBusy(true);
    _errorMessage = null;

    try {
      await _repository.addExercise(exercise: exercise);
      _exercises = await _repository.getExercises(refresh: true);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setBusy(false);
    }
  }

  /// Refreshes current user's training history.
  Future<void> refreshCurrentUserHistory() async {
    if (_currentUser == null) {
      return;
    }

    _setBusy(true);
    _errorMessage = null;

    try {
      _sessions = await _repository.getSessionsForUser(
        userId: _currentUser!.id,
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setBusy(false);
    }
  }

  /// Filters current user's history using inclusive start/end dates.
  List<TrainingSession> filteredSessions({
    required final DateTime? start,
    required final DateTime? end,
  }) {
    return _historyService.filterByDateRange(
      sessions: _sessions,
      start: start,
      end: end,
    );
  }

  /// Builds ranked exercise recommendations for the current user.
  List<RecommendationEntry> buildRecommendations({
    required final TrainingGoal goal,
  }) {
    return _recommendationService.buildRecommendations(
      exercises: _exercises,
      history: _sessions,
      goal: goal,
    );
  }

  /// Estimates duration in seconds for ordered exercises.
  int estimateDurationSeconds({
    required final List<Exercise> exercises,
    required final TrainingGoal goal,
    required final int restSecondsBetweenSets,
  }) {
    return _planningService.estimateSessionDurationSeconds(
      exercises: exercises,
      goal: goal,
      restSecondsBetweenSets: restSecondsBetweenSets,
    );
  }

  /// Returns true if the estimated duration exceeds user budget significantly.
  bool isOverBudget({
    required final int estimatedDurationSeconds,
    required final int maxDurationMinutes,
  }) {
    return _planningService.exceedsBudgetSignificantly(
      estimatedDurationSeconds: estimatedDurationSeconds,
      maxDurationMinutes: maxDurationMinutes,
    );
  }

  /// Saves a finished session and updates local history.
  Future<void> saveSession(final TrainingSession session) async {
    _setBusy(true);
    _errorMessage = null;

    try {
      await _repository.saveTrainingSession(session: session);
      if (_currentUser != null && session.userId == _currentUser!.id) {
        _sessions = await _repository.getSessionsForUser(
          userId: _currentUser!.id,
        );
      }
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(final bool value) {
    _isBusy = value;
    notifyListeners();
  }
}
