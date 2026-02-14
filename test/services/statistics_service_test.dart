import 'package:fitness_app/src/models/domain_models.dart';
import 'package:fitness_app/src/services/statistics_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_fixtures.dart';

void main() {
  group('StatisticsService', () {
    const StatisticsService service = StatisticsService();

    test('computes aggregate statistics and current week exercises', () {
      final DateTime now = DateTime(2026, 2, 14, 12);
      final List<TrainingSession> sessions = <TrainingSession>[
        buildSession(
          id: 's1',
          started: DateTime(2026, 2, 10, 9),
          ended: DateTime(2026, 2, 10, 9, 30),
          entries: const <SessionExerciseEntry>[
            SessionExerciseEntry(
              exerciseId: 'pushups',
              exerciseName: 'Push-ups',
              completedSets: 4,
              plannedSets: 4,
              durationSeconds: 300,
              skipped: false,
            ),
            SessionExerciseEntry(
              exerciseId: 'squats',
              exerciseName: 'Air Squats',
              completedSets: 4,
              plannedSets: 4,
              durationSeconds: 280,
              skipped: false,
            ),
          ],
        ),
        buildSession(
          id: 's2',
          started: DateTime(2026, 2, 13, 18),
          ended: DateTime(2026, 2, 13, 18, 25),
          entries: const <SessionExerciseEntry>[
            SessionExerciseEntry(
              exerciseId: 'pushups',
              exerciseName: 'Push-ups',
              completedSets: 4,
              plannedSets: 4,
              durationSeconds: 260,
              skipped: false,
            ),
            SessionExerciseEntry(
              exerciseId: 'plank',
              exerciseName: 'Plank',
              completedSets: 0,
              plannedSets: 3,
              durationSeconds: 0,
              skipped: true,
            ),
          ],
        ),
        buildSession(
          id: 's3',
          started: DateTime(2026, 1, 30, 8),
          ended: DateTime(2026, 1, 30, 8, 22),
          entries: const <SessionExerciseEntry>[
            SessionExerciseEntry(
              exerciseId: 'deadlift',
              exerciseName: 'Deadlift',
              completedSets: 4,
              plannedSets: 4,
              durationSeconds: 320,
              skipped: false,
            ),
          ],
        ),
      ];

      final TrainingStatistics stats = service.calculate(
        sessions: sessions,
        now: now,
      );

      expect(stats.totalSessions, 3);
      expect(stats.totalExerciseTimeSeconds, 1160);
      expect(stats.mostFrequentExercises.first.key, 'Push-ups');
      expect(stats.mostFrequentExercises.first.value, 2);
      expect(
        stats.exercisesThisWeek,
        containsAll(<String>['Push-ups', 'Air Squats']),
      );
      expect(stats.exercisesThisWeek, isNot(contains('Deadlift')));
    });
  });
}
