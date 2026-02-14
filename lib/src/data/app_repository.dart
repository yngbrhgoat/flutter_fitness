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

  /// Adds an exercise after validating per-goal configuration constraints.
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
  Future<UserProfile> loginOrCreateUser({required final String username}) {
    return _dataSource.loginOrCreateUser(username: username);
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
    for (final TrainingGoal goal in TrainingGoal.values) {
      final GoalConfiguration configuration = exercise.configurationForGoal(
        goal,
      );
      final bool hasInvalidSuitability =
          configuration.suitabilityRating < 0 ||
          configuration.suitabilityRating > 10;
      if (hasInvalidSuitability) {
        throw FormatException(
          'Suitability for ${goal.label} must be between 0 and 10.',
        );
      }

      if (configuration.suitabilityRating == 0) {
        final bool hasNonZeroFields =
            configuration.recommendedSets != 0 ||
            configuration.recommendedRepetitions != 0 ||
            configuration.recommendedDurationSeconds != 0;
        if (hasNonZeroFields) {
          throw FormatException(
            'All recommended values for ${goal.label} must be 0 when suitability is 0.',
          );
        }
      } else {
        final bool hasMissingValues =
            configuration.recommendedSets <= 0 ||
            configuration.recommendedRepetitions <= 0 ||
            configuration.recommendedDurationSeconds <= 0;
        if (hasMissingValues) {
          throw FormatException(
            'Recommended values for ${goal.label} must be greater than 0 when suitability is positive.',
          );
        }
      }
    }
  }
}
