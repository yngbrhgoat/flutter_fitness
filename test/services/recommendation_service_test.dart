import 'package:fitness_app/src/models/domain_models.dart';
import 'package:fitness_app/src/services/recommendation_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_fixtures.dart';

void main() {
  group('RecommendationService', () {
    test('excludes exercises with suitability 0 for selected goal', () {
      const RecommendationService service = RecommendationService();
      final List<Exercise> exercises = <Exercise>[
        buildExercise(id: 'a', name: 'A', suitability: 8),
        buildExercise(id: 'b', name: 'B', suitability: 0),
      ];

      final List<RecommendationEntry> recommendations = service
          .buildRecommendations(
            exercises: exercises,
            history: const <TrainingSession>[],
            goal: TrainingGoal.muscleGain,
            referenceTime: DateTime(2026, 2, 14),
          );

      expect(recommendations, hasLength(1));
      expect(recommendations.single.exercise.id, 'a');
    });

    test('applies novelty factor using user history recency', () {
      const RecommendationService service = RecommendationService(
        suitabilityWeight: 0.5,
        noveltyWeight: 0.5,
      );

      final Exercise frequent = buildExercise(
        id: 'frequent',
        name: 'Frequent',
        suitability: 9,
      );
      final Exercise novel = buildExercise(
        id: 'novel',
        name: 'Novel',
        suitability: 8,
      );

      final DateTime now = DateTime(2026, 2, 14);
      final TrainingSession recentSession = buildSession(
        id: 'session_1',
        started: now.subtract(const Duration(days: 1, minutes: 40)),
        ended: now.subtract(const Duration(days: 1, minutes: 10)),
        entries: const <SessionExerciseEntry>[
          SessionExerciseEntry(
            exerciseId: 'frequent',
            exerciseName: 'Frequent',
            completedSets: 4,
            plannedSets: 4,
            durationSeconds: 250,
            skipped: false,
          ),
        ],
      );

      final List<RecommendationEntry> recommendations = service
          .buildRecommendations(
            exercises: <Exercise>[frequent, novel],
            history: <TrainingSession>[recentSession],
            goal: TrainingGoal.muscleGain,
            referenceTime: now,
          );

      expect(recommendations.first.exercise.id, 'novel');
      expect(
        recommendations.first.noveltyScore,
        greaterThan(recommendations.last.noveltyScore),
      );
    });

    test('combines suitability and novelty into final score', () {
      const RecommendationService service = RecommendationService(
        suitabilityWeight: 0.75,
        noveltyWeight: 0.25,
      );

      final Exercise exercise = buildExercise(
        id: 'x',
        name: 'Exercise X',
        suitability: 8,
      );

      final List<RecommendationEntry> recommendations = service
          .buildRecommendations(
            exercises: <Exercise>[exercise],
            history: const <TrainingSession>[],
            goal: TrainingGoal.muscleGain,
            referenceTime: DateTime(2026, 2, 14),
          );

      expect(recommendations, hasLength(1));
      final RecommendationEntry entry = recommendations.single;
      expect(entry.suitabilityScore, 8);
      expect(entry.noveltyScore, 10);
      expect(entry.finalScore, closeTo(8.5, 0.0001));
    });
  });
}
