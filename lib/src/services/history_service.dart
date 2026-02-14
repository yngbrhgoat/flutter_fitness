import '../models/domain_models.dart';

/// Filtering helpers for training session history.
class HistoryService {
  /// Creates a history service.
  const HistoryService();

  /// Returns sessions whose start date is inside [start]..[end] inclusive.
  List<TrainingSession> filterByDateRange({
    required final List<TrainingSession> sessions,
    required final DateTime? start,
    required final DateTime? end,
  }) {
    final DateTime? normalizedStart = start == null
        ? null
        : DateTime(start.year, start.month, start.day);
    final DateTime? normalizedEnd = end == null
        ? null
        : DateTime(end.year, end.month, end.day, 23, 59, 59, 999, 999);

    return sessions
        .where((final TrainingSession session) {
          final DateTime started = session.startedAt;
          final bool afterStart =
              normalizedStart == null || !started.isBefore(normalizedStart);
          final bool beforeEnd =
              normalizedEnd == null || !started.isAfter(normalizedEnd);
          return afterStart && beforeEnd;
        })
        .toList(growable: false)
      ..sort(
        (final TrainingSession a, final TrainingSession b) =>
            b.startedAt.compareTo(a.startedAt),
      );
  }
}
