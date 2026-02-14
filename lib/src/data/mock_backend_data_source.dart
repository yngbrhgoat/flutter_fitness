import '../models/domain_models.dart';
import 'backend_data_source.dart';

/// In-memory backend that mirrors a server API contract for local runs/tests.
class MockBackendDataSource implements BackendDataSource {
  /// Creates a seeded backend with starter exercises and sample users.
  MockBackendDataSource.seeded()
    : _exercisesById = <String, Exercise>{
        for (final Exercise exercise in _seedExercises()) exercise.id: exercise,
      },
      _usersById = <String, UserProfile>{},
      _sessionsByUserId = <String, List<TrainingSession>>{},
      _recentUserIds = <String>[] {
    _seedUsersAndHistory();
  }

  final Map<String, Exercise> _exercisesById;
  final Map<String, UserProfile> _usersById;
  final Map<String, List<TrainingSession>> _sessionsByUserId;
  final List<String> _recentUserIds;

  @override
  Future<List<Exercise>> fetchExercises() async {
    final List<Exercise> exercises = _exercisesById.values.toList(
      growable: false,
    )..sort((final Exercise a, final Exercise b) => a.name.compareTo(b.name));
    return exercises;
  }

  @override
  Future<void> addExercise(final Exercise exercise) async {
    _exercisesById[exercise.id] = exercise;
  }

  @override
  Future<List<UserProfile>> fetchRecentUsers({final int limit = 3}) async {
    final List<UserProfile> users = _recentUserIds
        .take(limit)
        .map((final String id) => _usersById[id])
        .whereType<UserProfile>()
        .toList(growable: false);
    return users;
  }

  @override
  Future<UserProfile> loginOrCreateUser({
    required final String username,
  }) async {
    final String normalizedUsername = username.trim();
    final DateTime now = DateTime.now();

    UserProfile? existingUser;
    for (final UserProfile user in _usersById.values) {
      if (user.username.toLowerCase() == normalizedUsername.toLowerCase()) {
        existingUser = user;
        break;
      }
    }

    if (existingUser != null) {
      final UserProfile updated = UserProfile(
        id: existingUser.id,
        username: existingUser.username,
        lastLoginAt: now,
      );
      _usersById[updated.id] = updated;
      _touchRecentUser(updated.id);
      return updated;
    }

    final String userId = 'user_${now.microsecondsSinceEpoch}';
    final UserProfile created = UserProfile(
      id: userId,
      username: normalizedUsername,
      lastLoginAt: now,
    );
    _usersById[userId] = created;
    _sessionsByUserId[userId] = <TrainingSession>[];
    _touchRecentUser(userId);
    return created;
  }

  @override
  Future<List<TrainingSession>> fetchSessionsForUser({
    required final String userId,
  }) async {
    final List<TrainingSession> sessions =
        List<TrainingSession>.from(
          _sessionsByUserId[userId] ?? <TrainingSession>[],
        )..sort(
          (final TrainingSession a, final TrainingSession b) =>
              b.startedAt.compareTo(a.startedAt),
        );
    return sessions;
  }

  @override
  Future<void> saveTrainingSession({
    required final TrainingSession session,
  }) async {
    final List<TrainingSession> sessions = _sessionsByUserId.putIfAbsent(
      session.userId,
      () => <TrainingSession>[],
    );
    sessions.add(session);
  }

  void _touchRecentUser(final String userId) {
    _recentUserIds.remove(userId);
    _recentUserIds.insert(0, userId);
  }

  void _seedUsersAndHistory() {
    final DateTime now = DateTime.now();
    final List<UserProfile> seedUsers = <UserProfile>[
      UserProfile(
        id: 'user_alex',
        username: 'alex',
        lastLoginAt: now.subtract(const Duration(days: 1)),
      ),
      UserProfile(
        id: 'user_sam',
        username: 'sam',
        lastLoginAt: now.subtract(const Duration(days: 2)),
      ),
      UserProfile(
        id: 'user_jo',
        username: 'jo',
        lastLoginAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    for (final UserProfile user in seedUsers) {
      _usersById[user.id] = user;
      _sessionsByUserId[user.id] = <TrainingSession>[];
      _touchRecentUser(user.id);
    }

    final List<TrainingSession> alexSessions = <TrainingSession>[
      TrainingSession(
        id: 'session_1',
        userId: 'user_alex',
        goal: TrainingGoal.strengthIncrease,
        startedAt: now.subtract(const Duration(days: 4, minutes: 42)),
        endedAt: now.subtract(const Duration(days: 4, minutes: 10)),
        exerciseEntries: <SessionExerciseEntry>[
          const SessionExerciseEntry(
            exerciseId: 'pushups',
            exerciseName: 'Push-ups',
            completedSets: 4,
            plannedSets: 4,
            durationSeconds: 300,
            skipped: false,
          ),
          const SessionExerciseEntry(
            exerciseId: 'deadlift',
            exerciseName: 'Deadlift',
            completedSets: 4,
            plannedSets: 4,
            durationSeconds: 420,
            skipped: false,
          ),
          const SessionExerciseEntry(
            exerciseId: 'pullups',
            exerciseName: 'Pull-ups',
            completedSets: 3,
            plannedSets: 3,
            durationSeconds: 280,
            skipped: false,
          ),
        ],
      ),
      TrainingSession(
        id: 'session_2',
        userId: 'user_alex',
        goal: TrainingGoal.enduranceIncrease,
        startedAt: now.subtract(const Duration(days: 1, minutes: 35)),
        endedAt: now.subtract(const Duration(days: 1, minutes: 4)),
        exerciseEntries: <SessionExerciseEntry>[
          const SessionExerciseEntry(
            exerciseId: 'mountain_climbers',
            exerciseName: 'Mountain Climbers',
            completedSets: 4,
            plannedSets: 4,
            durationSeconds: 360,
            skipped: false,
          ),
          const SessionExerciseEntry(
            exerciseId: 'jump_rope',
            exerciseName: 'Jump Rope',
            completedSets: 5,
            plannedSets: 5,
            durationSeconds: 420,
            skipped: false,
          ),
          const SessionExerciseEntry(
            exerciseId: 'plank',
            exerciseName: 'Plank',
            completedSets: 3,
            plannedSets: 3,
            durationSeconds: 260,
            skipped: false,
          ),
        ],
      ),
    ];

    _sessionsByUserId['user_alex'] = alexSessions;
  }

  static GoalConfiguration _config(
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

  static Map<TrainingGoal, GoalConfiguration> _goals({
    required final GoalConfiguration muscleGain,
    required final GoalConfiguration weightLoss,
    required final GoalConfiguration strengthIncrease,
    required final GoalConfiguration enduranceIncrease,
  }) {
    return <TrainingGoal, GoalConfiguration>{
      TrainingGoal.muscleGain: muscleGain,
      TrainingGoal.weightLoss: weightLoss,
      TrainingGoal.strengthIncrease: strengthIncrease,
      TrainingGoal.enduranceIncrease: enduranceIncrease,
    };
  }

  static List<Exercise> _seedExercises() {
    return <Exercise>[
      Exercise(
        id: 'pushups',
        name: 'Push-ups',
        description:
            'Bodyweight pressing movement for chest, shoulders, and triceps.',
        mediaUrl: null,
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.chest,
          MuscleGroup.arms,
          MuscleGroup.shoulders,
        ],
        goalConfigurations: _goals(
          muscleGain: _config(8, 4, 12, 45),
          weightLoss: _config(7, 4, 15, 40),
          strengthIncrease: _config(8, 5, 8, 50),
          enduranceIncrease: _config(8, 4, 18, 40),
        ),
      ),
      Exercise(
        id: 'squats',
        name: 'Air Squats',
        description: 'Bodyweight squat variation to train legs and glutes.',
        mediaUrl: null,
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.legs,
          MuscleGroup.glutes,
          MuscleGroup.core,
        ],
        goalConfigurations: _goals(
          muscleGain: _config(7, 4, 14, 45),
          weightLoss: _config(8, 4, 16, 40),
          strengthIncrease: _config(6, 5, 10, 50),
          enduranceIncrease: _config(9, 5, 18, 40),
        ),
      ),
      Exercise(
        id: 'pullups',
        name: 'Pull-ups',
        description: 'Upper-body pulling exercise for back and arm strength.',
        mediaUrl: null,
        equipment: Equipment.pullUpBar,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.back,
          MuscleGroup.arms,
          MuscleGroup.shoulders,
        ],
        goalConfigurations: _goals(
          muscleGain: _config(9, 4, 8, 55),
          weightLoss: _config(5, 3, 8, 50),
          strengthIncrease: _config(10, 5, 6, 60),
          enduranceIncrease: _config(6, 4, 10, 50),
        ),
      ),
      Exercise(
        id: 'plank',
        name: 'Plank',
        description: 'Isometric core hold that improves trunk stability.',
        mediaUrl: null,
        equipment: Equipment.mat,
        targetMuscleGroups: const <MuscleGroup>[MuscleGroup.core],
        goalConfigurations: _goals(
          muscleGain: _config(4, 3, 1, 50),
          weightLoss: _config(6, 4, 1, 45),
          strengthIncrease: _config(5, 4, 1, 60),
          enduranceIncrease: _config(8, 4, 1, 60),
        ),
      ),
      Exercise(
        id: 'lunges',
        name: 'Lunges',
        description: 'Single-leg exercise to train legs, balance, and glutes.',
        mediaUrl: null,
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.legs,
          MuscleGroup.glutes,
          MuscleGroup.core,
        ],
        goalConfigurations: _goals(
          muscleGain: _config(7, 4, 12, 50),
          weightLoss: _config(8, 4, 14, 45),
          strengthIncrease: _config(6, 5, 8, 55),
          enduranceIncrease: _config(8, 4, 16, 45),
        ),
      ),
      Exercise(
        id: 'burpees',
        name: 'Burpees',
        description: 'Full-body conditioning movement with high cardio demand.',
        mediaUrl: null,
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.fullBody,
          MuscleGroup.core,
          MuscleGroup.legs,
        ],
        goalConfigurations: _goals(
          muscleGain: _config(4, 3, 10, 45),
          weightLoss: _config(10, 5, 12, 40),
          strengthIncrease: _config(3, 3, 8, 45),
          enduranceIncrease: _config(9, 5, 14, 35),
        ),
      ),
      Exercise(
        id: 'bench_press',
        name: 'Bench Press',
        description: 'Barbell chest press for strength and muscle development.',
        mediaUrl: null,
        equipment: Equipment.barbell,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.chest,
          MuscleGroup.arms,
          MuscleGroup.shoulders,
        ],
        goalConfigurations: _goals(
          muscleGain: _config(10, 5, 8, 60),
          weightLoss: _config(2, 3, 8, 55),
          strengthIncrease: _config(10, 5, 5, 70),
          enduranceIncrease: _config(2, 3, 10, 50),
        ),
      ),
      Exercise(
        id: 'deadlift',
        name: 'Deadlift',
        description: 'Compound barbell pull targeting posterior chain.',
        mediaUrl: null,
        equipment: Equipment.barbell,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.back,
          MuscleGroup.legs,
          MuscleGroup.glutes,
        ],
        goalConfigurations: _goals(
          muscleGain: _config(9, 4, 6, 65),
          weightLoss: _config(2, 3, 8, 55),
          strengthIncrease: _config(10, 5, 4, 75),
          enduranceIncrease: _config(1, 0, 0, 0),
        ),
      ),
      Exercise(
        id: 'mountain_climbers',
        name: 'Mountain Climbers',
        description:
            'Dynamic core and cardio drill performed in plank position.',
        mediaUrl: null,
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.core,
          MuscleGroup.legs,
          MuscleGroup.fullBody,
        ],
        goalConfigurations: _goals(
          muscleGain: _config(3, 3, 16, 40),
          weightLoss: _config(9, 5, 20, 35),
          strengthIncrease: _config(2, 3, 14, 40),
          enduranceIncrease: _config(10, 5, 22, 35),
        ),
      ),
      Exercise(
        id: 'bicep_curls',
        name: 'Bicep Curls',
        description: 'Isolation movement focusing on elbow flexors.',
        mediaUrl: null,
        equipment: Equipment.dumbbells,
        targetMuscleGroups: const <MuscleGroup>[MuscleGroup.arms],
        goalConfigurations: _goals(
          muscleGain: _config(8, 4, 12, 45),
          weightLoss: _config(4, 3, 14, 40),
          strengthIncrease: _config(7, 5, 8, 50),
          enduranceIncrease: _config(5, 4, 16, 40),
        ),
      ),
      Exercise(
        id: 'tricep_dips',
        name: 'Tricep Dips',
        description: 'Bodyweight dip variation for triceps and chest.',
        mediaUrl: null,
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.arms,
          MuscleGroup.chest,
        ],
        goalConfigurations: _goals(
          muscleGain: _config(7, 4, 10, 45),
          weightLoss: _config(6, 4, 12, 40),
          strengthIncrease: _config(8, 5, 8, 50),
          enduranceIncrease: _config(6, 4, 14, 40),
        ),
      ),
      Exercise(
        id: 'jump_rope',
        name: 'Jump Rope',
        description: 'Cardio-focused exercise for endurance and conditioning.',
        mediaUrl: null,
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.legs,
          MuscleGroup.fullBody,
        ],
        goalConfigurations: _goals(
          muscleGain: _config(1, 0, 0, 0),
          weightLoss: _config(10, 5, 30, 45),
          strengthIncrease: _config(1, 0, 0, 0),
          enduranceIncrease: _config(10, 6, 35, 40),
        ),
      ),
      Exercise(
        id: 'shoulder_press',
        name: 'Shoulder Press',
        description: 'Overhead dumbbell press for shoulder and arm strength.',
        mediaUrl: null,
        equipment: Equipment.dumbbells,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.shoulders,
          MuscleGroup.arms,
        ],
        goalConfigurations: _goals(
          muscleGain: _config(8, 4, 10, 50),
          weightLoss: _config(3, 3, 12, 45),
          strengthIncrease: _config(9, 5, 6, 60),
          enduranceIncrease: _config(4, 4, 14, 45),
        ),
      ),
      Exercise(
        id: 'russian_twists',
        name: 'Russian Twists',
        description: 'Rotational core movement that challenges trunk control.',
        mediaUrl: null,
        equipment: Equipment.mat,
        targetMuscleGroups: const <MuscleGroup>[MuscleGroup.core],
        goalConfigurations: _goals(
          muscleGain: _config(4, 3, 16, 45),
          weightLoss: _config(8, 4, 20, 40),
          strengthIncrease: _config(3, 3, 14, 45),
          enduranceIncrease: _config(9, 5, 22, 40),
        ),
      ),
      Exercise(
        id: 'kettlebell_swings',
        name: 'Kettlebell Swings',
        description:
            'Explosive hip hinge for power, cardio, and posterior chain.',
        mediaUrl: null,
        equipment: Equipment.kettlebell,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.glutes,
          MuscleGroup.back,
          MuscleGroup.fullBody,
        ],
        goalConfigurations: _goals(
          muscleGain: _config(7, 4, 14, 45),
          weightLoss: _config(9, 5, 16, 40),
          strengthIncrease: _config(8, 5, 10, 55),
          enduranceIncrease: _config(9, 5, 18, 40),
        ),
      ),
    ];
  }
}
