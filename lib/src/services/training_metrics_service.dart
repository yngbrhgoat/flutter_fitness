/// Relative pace state against recommended tempo.
enum TempoPaceStatus { ahead, onPace, behind }

/// Live training metric calculations.
class TrainingMetricsService {
  /// Creates a metrics service.
  const TrainingMetricsService();

  /// Returns completion percentage in range 0..100.
  double calculateCompletionPercentage({
    required final int completedUnits,
    required final int totalUnits,
  }) {
    if (totalUnits <= 0) {
      return 0;
    }
    final double ratio = completedUnits / totalUnits;
    final double boundedRatio = ratio.clamp(0.0, 1.0);
    return boundedRatio * 100.0;
  }

  /// Computes expected repetition index for elapsed set time.
  int expectedRepetitionNumber({
    required final int elapsedSeconds,
    required final int totalDurationSeconds,
    required final int totalRepetitions,
  }) {
    if (totalDurationSeconds <= 0 || totalRepetitions <= 0) {
      return 0;
    }

    final int boundedElapsed = elapsedSeconds.clamp(0, totalDurationSeconds);
    final double progress = boundedElapsed / totalDurationSeconds;
    final int expected = (progress * totalRepetitions).ceil();
    return expected.clamp(1, totalRepetitions);
  }

  /// Evaluates the user's pace against expected repetition.
  TempoPaceStatus evaluateTempoPace({
    required final int currentRepetition,
    required final int expectedRepetition,
    final int toleranceRepetitions = 1,
  }) {
    if (currentRepetition > expectedRepetition + toleranceRepetitions) {
      return TempoPaceStatus.ahead;
    }
    if (currentRepetition < expectedRepetition - toleranceRepetitions) {
      return TempoPaceStatus.behind;
    }
    return TempoPaceStatus.onPace;
  }

  /// Human-readable pace message for [status].
  String paceLabel(final TempoPaceStatus status) {
    switch (status) {
      case TempoPaceStatus.ahead:
        return 'Ahead of pace';
      case TempoPaceStatus.onPace:
        return 'On pace';
      case TempoPaceStatus.behind:
        return 'Behind pace';
    }
  }
}
