import '../models/domain_models.dart';

/// Contract for backend persistence and query operations.
abstract class BackendDataSource {
  /// Returns all available exercises.
  Future<List<Exercise>> fetchExercises();

  /// Persists a new exercise.
  Future<void> addExercise(final Exercise exercise);

  /// Returns the most recently logged in users.
  Future<List<UserProfile>> fetchRecentUsers({final int limit = 3});

  /// Logs in an existing user or creates a new one.
  Future<LoginResult> loginOrCreateUser({required final String username});

  /// Updates and returns a user's primary training goal.
  Future<UserProfile> updateUserPrimaryGoal({
    required final String userId,
    required final TrainingGoal primaryGoal,
  });

  /// Returns a user's session history.
  Future<List<TrainingSession>> fetchSessionsForUser({
    required final String userId,
  });

  /// Persists a completed or terminated training session.
  Future<void> saveTrainingSession({required final TrainingSession session});
}
