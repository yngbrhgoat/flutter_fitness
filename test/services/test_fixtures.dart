import 'package:fitness_app/src/models/domain_models.dart';

GoalConfiguration cfg(
  final int suitability,
  final int sets,
  final int reps,
  final int duration,
) {
  return GoalConfiguration(
    suitabilityRating: suitability,
    recommendedSets: sets,
    recommendedRepetitions: reps,
    recommendedDurationSeconds: duration,
  );
}

Map<TrainingGoal, GoalConfiguration> fullGoalConfig({
  required final GoalConfiguration muscleGain,
  required final GoalConfiguration weightLoss,
  required final GoalConfiguration strengthIncrease,
  required final GoalConfiguration enduranceIncrease,
}) {
  return <TrainingGoal, GoalConfiguration>{
    TrainingGoal.muscleGain: muscleGain,
    TrainingGoal.weightLoss: weightLoss,
    TrainingGoal.strengthIncrease: strengthIncrease,
    TrainingGoal.enduranceIncrease: enduranceIncrease,
  };
}

Exercise buildExercise({
  required final String id,
  required final String name,
  required final int suitability,
  final TrainingGoal assignedGoal = TrainingGoal.muscleGain,
}) {
  GoalConfiguration forGoal(final TrainingGoal goal) {
    if (goal != assignedGoal) {
      return GoalConfiguration.zero();
    }
    return cfg(suitability, 4, 10, 40);
  }

  return Exercise(
    id: id,
    name: name,
    description: '$name description',
    mediaUrl: null,
    equipment: Equipment.none,
    targetMuscleGroups: const <MuscleGroup>[MuscleGroup.core],
    goalConfigurations: fullGoalConfig(
      muscleGain: forGoal(TrainingGoal.muscleGain),
      weightLoss: forGoal(TrainingGoal.weightLoss),
      strengthIncrease: forGoal(TrainingGoal.strengthIncrease),
      enduranceIncrease: forGoal(TrainingGoal.enduranceIncrease),
    ),
  );
}

TrainingSession buildSession({
  required final String id,
  required final DateTime started,
  required final DateTime ended,
  required final List<SessionExerciseEntry> entries,
}) {
  return TrainingSession(
    id: id,
    userId: 'user_1',
    goal: TrainingGoal.muscleGain,
    startedAt: started,
    endedAt: ended,
    exerciseEntries: entries,
  );
}
