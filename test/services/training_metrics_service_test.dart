import 'package:fitness_app/src/services/training_metrics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrainingMetricsService', () {
    const TrainingMetricsService service = TrainingMetricsService();

    test('calculates completion percentage', () {
      final double completion = service.calculateCompletionPercentage(
        completedUnits: 3,
        totalUnits: 5,
      );
      final double bounded = service.calculateCompletionPercentage(
        completedUnits: 9,
        totalUnits: 5,
      );

      expect(completion, 60);
      expect(bounded, 100);
    });

    test('computes expected repetition by elapsed time', () {
      final int expectedAtHalfway = service.expectedRepetitionNumber(
        elapsedSeconds: 30,
        totalDurationSeconds: 60,
        totalRepetitions: 12,
      );
      final int expectedAtEnd = service.expectedRepetitionNumber(
        elapsedSeconds: 70,
        totalDurationSeconds: 60,
        totalRepetitions: 12,
      );

      expect(expectedAtHalfway, 6);
      expect(expectedAtEnd, 12);
    });

    test('evaluates tempo pace state', () {
      final TempoPaceStatus onPace = service.evaluateTempoPace(
        currentRepetition: 6,
        expectedRepetition: 6,
      );
      final TempoPaceStatus ahead = service.evaluateTempoPace(
        currentRepetition: 10,
        expectedRepetition: 6,
      );
      final TempoPaceStatus behind = service.evaluateTempoPace(
        currentRepetition: 2,
        expectedRepetition: 6,
      );

      expect(onPace, TempoPaceStatus.onPace);
      expect(ahead, TempoPaceStatus.ahead);
      expect(behind, TempoPaceStatus.behind);
    });
  });
}
