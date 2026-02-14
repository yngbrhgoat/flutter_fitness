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

Exercise buildExercise({
  required final String id,
  required final String name,
  required final int suitability,
  final TrainingGoal goal = TrainingGoal.muscleGain,
}) {
  final bool isSuitable = suitability > 0;

  return Exercise(
    id: id,
    name: name,
    description: '$name description',
    mediaUrl: null,
    equipment: Equipment.none,
    targetMuscleGroups: const <MuscleGroup>[MuscleGroup.core],
    goal: goal,
    goalConfiguration: cfg(
      suitability,
      isSuitable ? 4 : 0,
      isSuitable ? 10 : 0,
      isSuitable ? 40 : 0,
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
