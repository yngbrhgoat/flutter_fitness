import 'package:fitness_app/src/data/app_repository.dart';
import 'package:fitness_app/src/data/mock_backend_data_source.dart';
import 'package:fitness_app/src/models/domain_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRepository', () {
    test('rejects exercises with invalid single-goal suitability', () async {
      final AppRepository repository = AppRepository(
        dataSource: MockBackendDataSource.seeded(),
      );

      final Exercise invalidExercise = Exercise(
        id: 'invalid_goal_exercise',
        name: 'Invalid Goal',
        description: 'Invalid config for test.',
        mediaUrl: null,
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[MuscleGroup.core],
        goal: TrainingGoal.muscleGain,
        goalConfiguration: const GoalConfiguration(
          suitabilityRating: 0,
          recommendedSets: 4,
          recommendedRepetitions: 12,
          recommendedDurationSeconds: 40,
        ),
      );

      expect(
        repository.addExercise(exercise: invalidExercise),
        throwsA(isA<FormatException>()),
      );
    });

    test('accepts exercise assigned to exactly one goal', () async {
      final AppRepository repository = AppRepository(
        dataSource: MockBackendDataSource.seeded(),
      );

      final Exercise validExercise = Exercise(
        id: 'single_goal_exercise',
        name: 'Single Goal',
        description: 'Valid config for test.',
        mediaUrl: null,
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[MuscleGroup.legs],
        goal: TrainingGoal.weightLoss,
        goalConfiguration: const GoalConfiguration(
          suitabilityRating: 9,
          recommendedSets: 4,
          recommendedRepetitions: 18,
          recommendedDurationSeconds: 35,
        ),
      );

      await repository.addExercise(exercise: validExercise);
      final List<Exercise> allExercises = await repository.getExercises(
        refresh: true,
      );

      expect(
        allExercises.any((final Exercise exercise) {
          return exercise.id == validExercise.id;
        }),
        isTrue,
      );
    });

    test('updates and returns user primary goal', () async {
      final AppRepository repository = AppRepository(
        dataSource: MockBackendDataSource.seeded(),
      );

      final LoginResult loginResult = await repository.loginOrCreateUser(
        username: 'goal_update_user',
      );
      final UserProfile updated = await repository.updateUserPrimaryGoal(
        userId: loginResult.user.id,
        primaryGoal: TrainingGoal.enduranceIncrease,
      );

      expect(updated.primaryGoal, TrainingGoal.enduranceIncrease);
    });
  });
}
