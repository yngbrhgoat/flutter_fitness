import 'package:flutter/foundation.dart';

/// Supported user training goals.
enum TrainingGoal {
  muscleGain,
  weightLoss,
  strengthIncrease,
  enduranceIncrease,
}

/// Helpers for [TrainingGoal] labels and serialization values.
extension TrainingGoalExtension on TrainingGoal {
  /// Human readable label.
  String get label {
    switch (this) {
      case TrainingGoal.muscleGain:
        return 'Muscle Gain';
      case TrainingGoal.weightLoss:
        return 'Weight Loss';
      case TrainingGoal.strengthIncrease:
        return 'Strength Increase';
      case TrainingGoal.enduranceIncrease:
        return 'Endurance Increase';
    }
  }

  /// Value used in backend payloads.
  String get apiValue {
    switch (this) {
      case TrainingGoal.muscleGain:
        return 'muscle_gain';
      case TrainingGoal.weightLoss:
        return 'weight_loss';
      case TrainingGoal.strengthIncrease:
        return 'strength_increase';
      case TrainingGoal.enduranceIncrease:
        return 'endurance_increase';
    }
  }
}

/// Parses an API value into a [TrainingGoal].
TrainingGoal trainingGoalFromApiValue(final String value) {
  for (final TrainingGoal goal in TrainingGoal.values) {
    if (goal.apiValue == value) {
      return goal;
    }
  }
  throw ArgumentError.value(value, 'value', 'Unknown training goal value');
}

/// Equipment requirements for an exercise.
enum Equipment {
  none,
  dumbbells,
  pullUpBar,
  kettlebell,
  barbell,
  resistanceBand,
  mat,
}

/// Helpers for [Equipment] labels and serialization values.
extension EquipmentExtension on Equipment {
  /// Human readable label.
  String get label {
    switch (this) {
      case Equipment.none:
        return 'None';
      case Equipment.dumbbells:
        return 'Dumbbells';
      case Equipment.pullUpBar:
        return 'Pull-up Bar';
      case Equipment.kettlebell:
        return 'Kettlebell';
      case Equipment.barbell:
        return 'Barbell';
      case Equipment.resistanceBand:
        return 'Resistance Band';
      case Equipment.mat:
        return 'Mat';
    }
  }

  /// Value used in backend payloads.
  String get apiValue {
    switch (this) {
      case Equipment.none:
        return 'none';
      case Equipment.dumbbells:
        return 'dumbbells';
      case Equipment.pullUpBar:
        return 'pull_up_bar';
      case Equipment.kettlebell:
        return 'kettlebell';
      case Equipment.barbell:
        return 'barbell';
      case Equipment.resistanceBand:
        return 'resistance_band';
      case Equipment.mat:
        return 'mat';
    }
  }
}

/// Parses an API value into [Equipment].
Equipment equipmentFromApiValue(final String value) {
  for (final Equipment equipment in Equipment.values) {
    if (equipment.apiValue == value) {
      return equipment;
    }
  }
  throw ArgumentError.value(value, 'value', 'Unknown equipment value');
}

/// Major muscle groups targeted by exercises.
enum MuscleGroup { chest, back, legs, core, arms, shoulders, glutes, fullBody }

/// Helpers for [MuscleGroup] labels and serialization values.
extension MuscleGroupExtension on MuscleGroup {
  /// Human readable label.
  String get label {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.legs:
        return 'Legs';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.arms:
        return 'Arms';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.fullBody:
        return 'Full Body';
    }
  }

  /// Value used in backend payloads.
  String get apiValue {
    switch (this) {
      case MuscleGroup.chest:
        return 'chest';
      case MuscleGroup.back:
        return 'back';
      case MuscleGroup.legs:
        return 'legs';
      case MuscleGroup.core:
        return 'core';
      case MuscleGroup.arms:
        return 'arms';
      case MuscleGroup.shoulders:
        return 'shoulders';
      case MuscleGroup.glutes:
        return 'glutes';
      case MuscleGroup.fullBody:
        return 'full_body';
    }
  }
}

/// Parses an API value into [MuscleGroup].
MuscleGroup muscleGroupFromApiValue(final String value) {
  for (final MuscleGroup group in MuscleGroup.values) {
    if (group.apiValue == value) {
      return group;
    }
  }
  throw ArgumentError.value(value, 'value', 'Unknown muscle group value');
}

/// Per-goal exercise guidance and suitability.
@immutable
class GoalConfiguration {
  /// Creates a goal configuration.
  const GoalConfiguration({
    required this.suitabilityRating,
    required this.recommendedSets,
    required this.recommendedRepetitions,
    required this.recommendedDurationSeconds,
  });

  /// Suitability score between 0 and 10.
  final int suitabilityRating;

  /// Recommended number of sets.
  final int recommendedSets;

  /// Recommended repetitions for each set.
  final int recommendedRepetitions;

  /// Recommended duration per set in seconds.
  final int recommendedDurationSeconds;

  /// Returns whether this exercise is suitable for the goal.
  bool get isSuitable => suitabilityRating > 0;

  /// Serializes this object to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'suitability_rating': suitabilityRating,
      'recommended_sets': recommendedSets,
      'recommended_repetitions': recommendedRepetitions,
      'recommended_duration_seconds': recommendedDurationSeconds,
    };
  }

  /// Deserializes a configuration from JSON.
  factory GoalConfiguration.fromJson(final Map<String, dynamic> json) {
    return GoalConfiguration(
      suitabilityRating: (json['suitability_rating'] as num?)?.toInt() ?? 0,
      recommendedSets: (json['recommended_sets'] as num?)?.toInt() ?? 0,
      recommendedRepetitions:
          (json['recommended_repetitions'] as num?)?.toInt() ?? 0,
      recommendedDurationSeconds:
          (json['recommended_duration_seconds'] as num?)?.toInt() ?? 0,
    );
  }

  /// Returns an all-zero configuration.
  static GoalConfiguration zero() {
    return const GoalConfiguration(
      suitabilityRating: 0,
      recommendedSets: 0,
      recommendedRepetitions: 0,
      recommendedDurationSeconds: 0,
    );
  }
}

/// Exercise reference data used for recommendations and live mode.
@immutable
class Exercise {
  /// Creates an exercise.
  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.mediaUrl,
    required this.equipment,
    required this.targetMuscleGroups,
    required this.goalConfigurations,
  });

  /// Database identifier.
  final String id;

  /// Display name.
  final String name;

  /// Short exercise description.
  final String description;

  /// Optional image/icon/animation URL.
  final String? mediaUrl;

  /// Required equipment.
  final Equipment equipment;

  /// Target muscle groups.
  final List<MuscleGroup> targetMuscleGroups;

  /// Per-goal suitability and guidance.
  final Map<TrainingGoal, GoalConfiguration> goalConfigurations;

  /// Returns per-goal configuration.
  GoalConfiguration configurationForGoal(final TrainingGoal goal) {
    return goalConfigurations[goal] ?? GoalConfiguration.zero();
  }

  /// Returns whether this exercise is suitable for [goal].
  bool isSuitableForGoal(final TrainingGoal goal) {
    return configurationForGoal(goal).isSuitable;
  }

  /// Estimates the total exercise duration in seconds for a goal.
  int estimatedDurationForGoalSeconds({
    required final TrainingGoal goal,
    required final int restSecondsBetweenSets,
  }) {
    final GoalConfiguration config = configurationForGoal(goal);
    if (!config.isSuitable) {
      return 0;
    }

    final int activeDuration =
        config.recommendedSets * config.recommendedDurationSeconds;
    final int restDuration =
        (config.recommendedSets > 1 ? config.recommendedSets - 1 : 0) *
        restSecondsBetweenSets;
    return activeDuration + restDuration;
  }

  /// Serializes this exercise to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'media_url': mediaUrl,
      'equipment': equipment.apiValue,
      'target_muscle_groups': targetMuscleGroups
          .map((final MuscleGroup group) => group.apiValue)
          .toList(growable: false),
      'goal_configurations': <String, dynamic>{
        for (final MapEntry<TrainingGoal, GoalConfiguration> entry
            in goalConfigurations.entries)
          entry.key.apiValue: entry.value.toJson(),
      },
    };
  }

  /// Deserializes an exercise from JSON.
  factory Exercise.fromJson(final Map<String, dynamic> json) {
    final Map<String, dynamic> rawConfigurations =
        json['goal_configurations'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    final Map<TrainingGoal, GoalConfiguration> configurations =
        <TrainingGoal, GoalConfiguration>{
          for (final MapEntry<String, dynamic> entry
              in rawConfigurations.entries)
            trainingGoalFromApiValue(entry.key): GoalConfiguration.fromJson(
              (entry.value as Map<String, dynamic>?) ?? <String, dynamic>{},
            ),
        };

    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      mediaUrl: json['media_url'] as String?,
      equipment: equipmentFromApiValue(json['equipment'] as String),
      targetMuscleGroups:
          ((json['target_muscle_groups'] as List<dynamic>?) ?? <dynamic>[])
              .map(
                (final dynamic value) =>
                    muscleGroupFromApiValue(value as String),
              )
              .toList(growable: false),
      goalConfigurations: configurations,
    );
  }
}

/// User account information.
@immutable
class UserProfile {
  /// Creates a user profile.
  const UserProfile({
    required this.id,
    required this.username,
    required this.lastLoginAt,
  });

  /// User identifier.
  final String id;

  /// Username shown in the UI.
  final String username;

  /// Last login timestamp.
  final DateTime lastLoginAt;

  /// Serializes this user profile to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'last_login_at': lastLoginAt.toIso8601String(),
    };
  }

  /// Deserializes a user profile from JSON.
  factory UserProfile.fromJson(final Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      lastLoginAt: DateTime.parse(json['last_login_at'] as String),
    );
  }
}

/// Per-exercise execution result within a session.
@immutable
class SessionExerciseEntry {
  /// Creates a session exercise entry.
  const SessionExerciseEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.completedSets,
    required this.plannedSets,
    required this.durationSeconds,
    required this.skipped,
  });

  /// Exercise identifier.
  final String exerciseId;

  /// Exercise name captured at session time.
  final String exerciseName;

  /// Number of sets completed.
  final int completedSets;

  /// Number of planned sets.
  final int plannedSets;

  /// Time spent on this exercise.
  final int durationSeconds;

  /// Indicates if this exercise was skipped.
  final bool skipped;

  /// Serializes this entry to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'completed_sets': completedSets,
      'planned_sets': plannedSets,
      'duration_seconds': durationSeconds,
      'skipped': skipped,
    };
  }

  /// Deserializes a session exercise entry from JSON.
  factory SessionExerciseEntry.fromJson(final Map<String, dynamic> json) {
    return SessionExerciseEntry(
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String,
      completedSets: (json['completed_sets'] as num?)?.toInt() ?? 0,
      plannedSets: (json['planned_sets'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      skipped: json['skipped'] as bool? ?? false,
    );
  }
}

/// Training session record stored in user history.
@immutable
class TrainingSession {
  /// Creates a training session.
  const TrainingSession({
    required this.id,
    required this.userId,
    required this.goal,
    required this.startedAt,
    required this.endedAt,
    required this.exerciseEntries,
  });

  /// Session identifier.
  final String id;

  /// User identifier.
  final String userId;

  /// Goal selected when the session started.
  final TrainingGoal goal;

  /// Session start timestamp.
  final DateTime startedAt;

  /// Session end timestamp.
  final DateTime endedAt;

  /// Per-exercise session details.
  final List<SessionExerciseEntry> exerciseEntries;

  /// Total session duration in seconds.
  int get totalDurationSeconds {
    return endedAt.difference(startedAt).inSeconds;
  }

  /// Number of completed sets in this session.
  int get totalCompletedSets {
    return exerciseEntries.fold<int>(
      0,
      (final int sum, final SessionExerciseEntry entry) =>
          sum + entry.completedSets,
    );
  }

  /// Names of completed exercises.
  List<String> get completedExerciseNames {
    return exerciseEntries
        .where((final SessionExerciseEntry entry) => !entry.skipped)
        .map((final SessionExerciseEntry entry) => entry.exerciseName)
        .toList(growable: false);
  }

  /// Names of skipped exercises.
  List<String> get skippedExerciseNames {
    return exerciseEntries
        .where((final SessionExerciseEntry entry) => entry.skipped)
        .map((final SessionExerciseEntry entry) => entry.exerciseName)
        .toList(growable: false);
  }

  /// Serializes this session to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'goal': goal.apiValue,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'exercise_entries': exerciseEntries
          .map((final SessionExerciseEntry entry) => entry.toJson())
          .toList(growable: false),
    };
  }

  /// Deserializes a training session from JSON.
  factory TrainingSession.fromJson(final Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goal: trainingGoalFromApiValue(json['goal'] as String),
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: DateTime.parse(json['ended_at'] as String),
      exerciseEntries:
          ((json['exercise_entries'] as List<dynamic>?) ?? <dynamic>[])
              .map(
                (final dynamic value) => SessionExerciseEntry.fromJson(
                  (value as Map<String, dynamic>?) ?? <String, dynamic>{},
                ),
              )
              .toList(growable: false),
    );
  }
}

/// Recommendation result with transparent scoring details.
@immutable
class RecommendationEntry {
  /// Creates a recommendation entry.
  const RecommendationEntry({
    required this.exercise,
    required this.suitabilityScore,
    required this.noveltyScore,
    required this.finalScore,
  });

  /// Exercise being recommended.
  final Exercise exercise;

  /// Suitability score component.
  final double suitabilityScore;

  /// Novelty score component.
  final double noveltyScore;

  /// Combined ranking score.
  final double finalScore;
}

/// Aggregated user statistics for history overview.
@immutable
class TrainingStatistics {
  /// Creates statistics for a user.
  const TrainingStatistics({
    required this.totalSessions,
    required this.totalExerciseTimeSeconds,
    required this.mostFrequentExercises,
    required this.exercisesThisWeek,
  });

  /// Number of sessions.
  final int totalSessions;

  /// Total tracked exercise time in seconds.
  final int totalExerciseTimeSeconds;

  /// Exercise names with frequency counts sorted descending.
  final List<MapEntry<String, int>> mostFrequentExercises;

  /// Exercises performed within the current week.
  final List<String> exercisesThisWeek;
}
