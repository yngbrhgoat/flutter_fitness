import 'package:fitness_app/src/models/domain_models.dart';
import 'package:fitness_app/src/services/history_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_fixtures.dart';

void main() {
  group('HistoryService', () {
    const HistoryService service = HistoryService();

    test('filters user history by date range inclusively', () {
      final List<TrainingSession> sessions = <TrainingSession>[
        buildSession(
          id: 's1',
          started: DateTime(2026, 1, 1, 9),
          ended: DateTime(2026, 1, 1, 9, 30),
          entries: const <SessionExerciseEntry>[],
        ),
        buildSession(
          id: 's2',
          started: DateTime(2026, 1, 10, 9),
          ended: DateTime(2026, 1, 10, 9, 30),
          entries: const <SessionExerciseEntry>[],
        ),
        buildSession(
          id: 's3',
          started: DateTime(2026, 2, 1, 9),
          ended: DateTime(2026, 2, 1, 9, 30),
          entries: const <SessionExerciseEntry>[],
        ),
      ];

      final List<TrainingSession> filtered = service.filterByDateRange(
        sessions: sessions,
        start: DateTime(2026, 1, 10),
        end: DateTime(2026, 2, 1),
      );

      expect(
        filtered.map((final TrainingSession session) => session.id),
        <String>['s3', 's2'],
      );
    });
  });
}
