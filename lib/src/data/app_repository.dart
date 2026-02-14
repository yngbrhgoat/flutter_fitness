import '../models/domain_models.dart';
import 'backend_data_source.dart';

/// Centralized app repository that validates entities and delegates persistence.
class AppRepository {
  /// Creates an app repository.
  AppRepository({required final BackendDataSource dataSource})
    : _dataSource = dataSource;

  final BackendDataSource _dataSource;

  List<Exercise>? _cachedExercises;

  /// Returns all exercises, optionally refreshing the cache.
  Future<List<Exercise>> getExercises({final bool refresh = false}) async {
    if (!refresh && _cachedExercises != null) {
      return List<Exercise>.from(_cachedExercises!);
    }

    final List<Exercise> exercises = await _dataSource.fetchExercises();
    _cachedExercises = exercises;
    return List<Exercise>.from(exercises);
  }

  /// Adds an exercise after validating single-goal configuration constraints.
  Future<void> addExercise({required final Exercise exercise}) async {
    _validateExerciseConfiguration(exercise);
    await _dataSource.addExercise(exercise);
    _cachedExercises = null;
  }

  /// Returns recently active users.
  Future<List<UserProfile>> getRecentUsers({final int limit = 3}) {
    return _dataSource.fetchRecentUsers(limit: limit);
  }

  /// Logs in an existing user or creates a new profile.
  Future<LoginResult> loginOrCreateUser({required final String username}) {
    return _dataSource.loginOrCreateUser(username: username);
  }

  /// Updates a user's primary goal and returns the updated profile.
  Future<UserProfile> updateUserPrimaryGoal({
    required final String userId,
    required final TrainingGoal primaryGoal,
  }) {
    return _dataSource.updateUserPrimaryGoal(
      userId: userId,
      primaryGoal: primaryGoal,
    );
  }

  /// Returns a user's training history.
  Future<List<TrainingSession>> getSessionsForUser({
    required final String userId,
  }) {
    return _dataSource.fetchSessionsForUser(userId: userId);
  }

  /// Saves a training session record.
  Future<void> saveTrainingSession({required final TrainingSession session}) {
    return _dataSource.saveTrainingSession(session: session);
  }

  void _validateExerciseConfiguration(final Exercise exercise) {
    final GoalConfiguration configuration = exercise.goalConfiguration;
    final bool hasInvalidSuitability =
        configuration.suitabilityRating < 1 ||
        configuration.suitabilityRating > 10;
    if (hasInvalidSuitability) {
      throw FormatException(
        'Suitability for ${exercise.goal.label} must be between 1 and 10.',
      );
    }

    final bool hasMissingValues =
        configuration.recommendedSets <= 0 ||
        configuration.recommendedRepetitions <= 0 ||
        configuration.recommendedDurationSeconds <= 0;
    if (hasMissingValues) {
      throw FormatException(
        'Recommended values for ${exercise.goal.label} must be greater than 0.',
      );
    }
  }
}
