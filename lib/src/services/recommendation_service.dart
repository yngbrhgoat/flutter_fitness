import 'dart:math';

import '../models/domain_models.dart';

/// Builds ranked training recommendations using suitability + novelty.
class RecommendationService {
  /// Creates a recommendation service.
  const RecommendationService({
    this.suitabilityWeight = 0.75,
    this.noveltyWeight = 0.25,
  }) : assert(suitabilityWeight >= 0),
       assert(noveltyWeight >= 0);

  /// Relative importance of exercise suitability.
  final double suitabilityWeight;

  /// Relative importance of novelty from user history.
  final double noveltyWeight;

  /// Returns recommendations for [goal] sorted by final score descending.
  List<RecommendationEntry> buildRecommendations({
    required final List<Exercise> exercises,
    required final List<TrainingSession> history,
    required final TrainingGoal goal,
    final DateTime? referenceTime,
  }) {
    final DateTime now = referenceTime ?? DateTime.now();
    final Map<String, DateTime> lastPerformed = _findLastPerformedDates(
      history,
    );
    final List<RecommendationEntry> results = <RecommendationEntry>[];

    for (final Exercise exercise in exercises) {
      if (exercise.assignedGoal != goal) {
        continue;
      }
      final GoalConfiguration config = exercise.configurationForGoal(goal);
      if (!config.isSuitable) {
        continue;
      }

      final double suitabilityScore = config.suitabilityRating.toDouble();
      final double noveltyScore = _calculateNoveltyScore(
        lastPerformedAt: lastPerformed[exercise.id],
        now: now,
      );
      final double denominator = suitabilityWeight + noveltyWeight;
      final double weightedScore = denominator == 0
          ? 0
          : ((suitabilityScore * suitabilityWeight) +
                    (noveltyScore * noveltyWeight)) /
                denominator;

      results.add(
        RecommendationEntry(
          exercise: exercise,
          suitabilityScore: suitabilityScore,
          noveltyScore: noveltyScore,
          finalScore: weightedScore,
        ),
      );
    }

    results.sort((final RecommendationEntry a, final RecommendationEntry b) {
      final int scoreComparison = b.finalScore.compareTo(a.finalScore);
      if (scoreComparison != 0) {
        return scoreComparison;
      }
      return a.exercise.name.compareTo(b.exercise.name);
    });

    return results;
  }

  /// Returns a novelty score in range 0..10.
  double _calculateNoveltyScore({
    required final DateTime? lastPerformedAt,
    required final DateTime now,
  }) {
    if (lastPerformedAt == null) {
      return 10.0;
    }

    final int daysSinceLastUse = max(0, now.difference(lastPerformedAt).inDays);
    if (daysSinceLastUse >= 28) {
      return 10.0;
    }

    return (daysSinceLastUse / 28.0) * 10.0;
  }

  /// Finds the most recent completion timestamp for each exercise.
  Map<String, DateTime> _findLastPerformedDates(
    final List<TrainingSession> history,
  ) {
    final Map<String, DateTime> lastPerformed = <String, DateTime>{};

    for (final TrainingSession session in history) {
      for (final SessionExerciseEntry entry in session.exerciseEntries) {
        if (entry.skipped || entry.completedSets <= 0) {
          continue;
        }

        final DateTime? existing = lastPerformed[entry.exerciseId];
        if (existing == null || session.endedAt.isAfter(existing)) {
          lastPerformed[entry.exerciseId] = session.endedAt;
        }
      }
    }

    return lastPerformed;
  }
}
