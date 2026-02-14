import '../models/domain_models.dart';

/// Builds aggregate user statistics from training sessions.
class StatisticsService {
  /// Creates a statistics service.
  const StatisticsService();

  /// Computes summary statistics for [sessions].
  TrainingStatistics calculate({
    required final List<TrainingSession> sessions,
    required final DateTime now,
  }) {
    int totalExerciseTimeSeconds = 0;
    final Map<String, int> exerciseFrequency = <String, int>{};

    final DateTime weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final DateTime weekEnd = weekStart.add(const Duration(days: 7));
    final Set<String> exercisesThisWeek = <String>{};

    for (final TrainingSession session in sessions) {
      for (final SessionExerciseEntry entry in session.exerciseEntries) {
        totalExerciseTimeSeconds += entry.durationSeconds;
        if (!entry.skipped && entry.completedSets > 0) {
          exerciseFrequency.update(
            entry.exerciseName,
            (final int count) => count + 1,
            ifAbsent: () => 1,
          );

          final bool isCurrentWeek =
              !session.startedAt.isBefore(weekStart) &&
              session.startedAt.isBefore(weekEnd);
          if (isCurrentWeek) {
            exercisesThisWeek.add(entry.exerciseName);
          }
        }
      }
    }

    final List<MapEntry<String, int>> sortedFrequency =
        exerciseFrequency.entries.toList(growable: false)..sort((
          final MapEntry<String, int> a,
          final MapEntry<String, int> b,
        ) {
          final int countComparison = b.value.compareTo(a.value);
          if (countComparison != 0) {
            return countComparison;
          }
          return a.key.compareTo(b.key);
        });

    return TrainingStatistics(
      totalSessions: sessions.length,
      totalExerciseTimeSeconds: totalExerciseTimeSeconds,
      mostFrequentExercises: sortedFrequency.take(3).toList(growable: false),
      exercisesThisWeek: exercisesThisWeek.toList(growable: false)..sort(),
    );
  }
}
