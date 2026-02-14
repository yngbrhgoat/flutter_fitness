import '../models/domain_models.dart';
import 'backend_data_source.dart';

/// REST-backed implementation intended for a server + PostgreSQL deployment.
///
/// The app defaults to the mock backend so it can run locally without a server.
/// Replace these methods with real HTTP calls for production use.
class RestBackendDataSource implements BackendDataSource {
  /// Creates a REST data source.
  RestBackendDataSource({required this.baseUrl});

  /// Backend base URL.
  final String baseUrl;

  @override
  Future<void> addExercise(final Exercise exercise) {
    throw UnimplementedError(
      'REST backend is not wired in this template. '
      'Configure API calls to $baseUrl/add-exercise.',
    );
  }

  @override
  Future<List<Exercise>> fetchExercises() {
    throw UnimplementedError(
      'REST backend is not wired in this template. '
      'Configure API calls to $baseUrl/exercises.',
    );
  }

  @override
  Future<List<UserProfile>> fetchRecentUsers({final int limit = 3}) {
    throw UnimplementedError(
      'REST backend is not wired in this template. '
      'Configure API calls to $baseUrl/users/recent?limit=$limit.',
    );
  }

  @override
  Future<List<TrainingSession>> fetchSessionsForUser({
    required final String userId,
  }) {
    throw UnimplementedError(
      'REST backend is not wired in this template. '
      'Configure API calls to $baseUrl/users/$userId/sessions.',
    );
  }

  @override
  Future<LoginResult> loginOrCreateUser({required final String username}) {
    throw UnimplementedError(
      'REST backend is not wired in this template. '
      'Configure API calls to $baseUrl/login.',
    );
  }

  @override
  Future<UserProfile> updateUserPrimaryGoal({
    required final String userId,
    required final TrainingGoal primaryGoal,
  }) {
    throw UnimplementedError(
      'REST backend is not wired in this template. '
      'Configure API calls to $baseUrl/users/$userId/primary-goal.',
    );
  }

  @override
  Future<void> saveTrainingSession({required final TrainingSession session}) {
    throw UnimplementedError(
      'REST backend is not wired in this template. '
      'Configure API calls to $baseUrl/sessions.',
    );
  }
}
