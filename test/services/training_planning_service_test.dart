import 'package:fitness_app/src/models/domain_models.dart';
import 'package:fitness_app/src/services/training_planning_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_fixtures.dart';

void main() {
  group('TrainingPlanningService', () {
    const TrainingPlanningService service = TrainingPlanningService(
      defaultRestSecondsBetweenSets: 45,
    );

    test('estimates exercise and session duration', () {
      final Exercise exerciseA = buildExercise(
        id: 'a',
        name: 'A',
        suitability: 8,
      );
      final Exercise exerciseB = buildExercise(
        id: 'b',
        name: 'B',
        suitability: 8,
      );

      final int oneDuration = service.estimateExerciseDurationSeconds(
        exercise: exerciseA,
        goal: TrainingGoal.muscleGain,
      );
      final int totalDuration = service.estimateSessionDurationSeconds(
        exercises: <Exercise>[exerciseA, exerciseB],
        goal: TrainingGoal.muscleGain,
      );

      expect(oneDuration, 295);
      expect(totalDuration, 590);
    });

    test('checks whether estimate exceeds budget significantly', () {
      final bool isOverForEightMinutes = service.exceedsBudgetSignificantly(
        estimatedDurationSeconds: 590,
        maxDurationMinutes: 8,
      );
      final bool isOverForNineMinutes = service.exceedsBudgetSignificantly(
        estimatedDurationSeconds: 590,
        maxDurationMinutes: 9,
      );

      expect(isOverForEightMinutes, isTrue);
      expect(isOverForNineMinutes, isFalse);
    });

    test('selects ordered exercises inside tolerance budget', () {
      final Exercise a = buildExercise(id: 'a', name: 'A', suitability: 8);
      final Exercise b = buildExercise(id: 'b', name: 'B', suitability: 8);
      final Exercise c = buildExercise(id: 'c', name: 'C', suitability: 8);

      final List<Exercise> selected = service.selectExercisesWithinBudget(
        orderedExercises: <Exercise>[a, b, c],
        goal: TrainingGoal.muscleGain,
        maxDurationMinutes: 10,
      );

      expect(selected.map((final Exercise exercise) => exercise.id), <String>[
        'a',
        'b',
      ]);
    });
  });
}
