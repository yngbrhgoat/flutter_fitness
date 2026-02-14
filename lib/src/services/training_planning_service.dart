import '../models/domain_models.dart';

/// Estimates exercise/session duration and budget fit.
class TrainingPlanningService {
  /// Creates a planning service.
  const TrainingPlanningService({this.defaultRestSecondsBetweenSets = 45});

  /// Default rest duration between sets.
  final int defaultRestSecondsBetweenSets;

  /// Estimates one exercise duration in seconds for a goal.
  int estimateExerciseDurationSeconds({
    required final Exercise exercise,
    required final TrainingGoal goal,
    final int? restSecondsBetweenSets,
  }) {
    return exercise.estimatedDurationForGoalSeconds(
      goal: goal,
      restSecondsBetweenSets:
          restSecondsBetweenSets ?? defaultRestSecondsBetweenSets,
    );
  }

  /// Estimates total session duration in seconds for ordered exercises.
  int estimateSessionDurationSeconds({
    required final List<Exercise> exercises,
    required final TrainingGoal goal,
    final int? restSecondsBetweenSets,
  }) {
    final int restSeconds =
        restSecondsBetweenSets ?? defaultRestSecondsBetweenSets;
    int total = 0;
    for (final Exercise exercise in exercises) {
      total += exercise.estimatedDurationForGoalSeconds(
        goal: goal,
        restSecondsBetweenSets: restSeconds,
      );
    }
    return total;
  }

  /// Returns true when estimated duration exceeds budget by more than tolerance.
  bool exceedsBudgetSignificantly({
    required final int estimatedDurationSeconds,
    required final int maxDurationMinutes,
    final double toleranceFactor = 1.1,
  }) {
    final double budgetSeconds = maxDurationMinutes * 60.0;
    return estimatedDurationSeconds > budgetSeconds * toleranceFactor;
  }

  /// Greedy selection that keeps ordered exercises within time tolerance.
  List<Exercise> selectExercisesWithinBudget({
    required final List<Exercise> orderedExercises,
    required final TrainingGoal goal,
    required final int maxDurationMinutes,
    final double toleranceFactor = 1.1,
    final int? restSecondsBetweenSets,
  }) {
    final int limitSeconds = (maxDurationMinutes * 60 * toleranceFactor)
        .round();
    final int restSeconds =
        restSecondsBetweenSets ?? defaultRestSecondsBetweenSets;

    final List<Exercise> selected = <Exercise>[];
    int total = 0;
    for (final Exercise exercise in orderedExercises) {
      final int exerciseDuration = exercise.estimatedDurationForGoalSeconds(
        goal: goal,
        restSecondsBetweenSets: restSeconds,
      );
      if (exerciseDuration == 0) {
        continue;
      }

      if (total + exerciseDuration <= limitSeconds) {
        selected.add(exercise);
        total += exerciseDuration;
      }
    }

    return selected;
  }
}
