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
  Future<LoginResult> loginOrCreateUser({
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
        primaryGoal: existingUser.primaryGoal,
        lastLoginAt: now,
      );
      _usersById[updated.id] = updated;
      _touchRecentUser(updated.id);
      return LoginResult(user: updated, isNewUser: false);
    }

    final String userId = 'user_${now.microsecondsSinceEpoch}';
    final UserProfile created = UserProfile(
      id: userId,
      username: normalizedUsername,
      primaryGoal: TrainingGoal.muscleGain,
      lastLoginAt: now,
    );
    _usersById[userId] = created;
    _sessionsByUserId[userId] = <TrainingSession>[];
    _touchRecentUser(userId);
    return LoginResult(user: created, isNewUser: true);
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
  Future<UserProfile> updateUserPrimaryGoal({
    required final String userId,
    required final TrainingGoal primaryGoal,
  }) async {
    final UserProfile? existing = _usersById[userId];
    if (existing == null) {
      throw StateError('Unknown user id: $userId');
    }

    final UserProfile updated = UserProfile(
      id: existing.id,
      username: existing.username,
      primaryGoal: primaryGoal,
      lastLoginAt: existing.lastLoginAt,
    );
    _usersById[userId] = updated;
    _touchRecentUser(userId);
    return updated;
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
        primaryGoal: TrainingGoal.strengthIncrease,
        lastLoginAt: now.subtract(const Duration(days: 1)),
      ),
      UserProfile(
        id: 'user_sam',
        username: 'sam',
        primaryGoal: TrainingGoal.weightLoss,
        lastLoginAt: now.subtract(const Duration(days: 2)),
      ),
      UserProfile(
        id: 'user_jo',
        username: 'jo',
        primaryGoal: TrainingGoal.enduranceIncrease,
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

  static Exercise _exercise({
    required final String id,
    required final String name,
    required final String description,
    required final Equipment equipment,
    required final List<MuscleGroup> targetMuscleGroups,
    required final TrainingGoal goal,
    required final int suitability,
    required final int sets,
    required final int reps,
    required final int duration,
  }) {
    return Exercise(
      id: id,
      name: name,
      description: description,
      mediaUrl: null,
      equipment: equipment,
      targetMuscleGroups: targetMuscleGroups,
      goal: goal,
      goalConfiguration: _config(suitability, sets, reps, duration),
    );
  }

  static List<Exercise> _seedExercises() {
    return <Exercise>[
      _exercise(
        id: 'pushups',
        name: 'Push-ups',
        description:
            'Bodyweight pressing movement for chest, shoulders, and triceps.',
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.chest,
          MuscleGroup.arms,
          MuscleGroup.shoulders,
        ],
        goal: TrainingGoal.muscleGain,
        suitability: 8,
        sets: 4,
        reps: 12,
        duration: 45,
      ),
      _exercise(
        id: 'squats',
        name: 'Air Squats',
        description: 'Bodyweight squat variation to train legs and glutes.',
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.legs,
          MuscleGroup.glutes,
          MuscleGroup.core,
        ],
        goal: TrainingGoal.enduranceIncrease,
        suitability: 9,
        sets: 5,
        reps: 18,
        duration: 40,
      ),
      _exercise(
        id: 'pullups',
        name: 'Pull-ups',
        description: 'Upper-body pulling exercise for back and arm strength.',
        equipment: Equipment.pullUpBar,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.back,
          MuscleGroup.arms,
          MuscleGroup.shoulders,
        ],
        goal: TrainingGoal.strengthIncrease,
        suitability: 10,
        sets: 5,
        reps: 6,
        duration: 60,
      ),
      _exercise(
        id: 'plank',
        name: 'Plank',
        description: 'Isometric core hold that improves trunk stability.',
        equipment: Equipment.mat,
        targetMuscleGroups: const <MuscleGroup>[MuscleGroup.core],
        goal: TrainingGoal.enduranceIncrease,
        suitability: 8,
        sets: 4,
        reps: 1,
        duration: 60,
      ),
      _exercise(
        id: 'lunges',
        name: 'Lunges',
        description: 'Single-leg exercise to train legs, balance, and glutes.',
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.legs,
          MuscleGroup.glutes,
          MuscleGroup.core,
        ],
        goal: TrainingGoal.weightLoss,
        suitability: 8,
        sets: 4,
        reps: 14,
        duration: 45,
      ),
      _exercise(
        id: 'burpees',
        name: 'Burpees',
        description: 'Full-body conditioning movement with high cardio demand.',
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.fullBody,
          MuscleGroup.core,
          MuscleGroup.legs,
        ],
        goal: TrainingGoal.weightLoss,
        suitability: 10,
        sets: 5,
        reps: 12,
        duration: 40,
      ),
      _exercise(
        id: 'bench_press',
        name: 'Bench Press',
        description: 'Barbell chest press for strength and muscle development.',
        equipment: Equipment.barbell,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.chest,
          MuscleGroup.arms,
          MuscleGroup.shoulders,
        ],
        goal: TrainingGoal.strengthIncrease,
        suitability: 10,
        sets: 5,
        reps: 5,
        duration: 70,
      ),
      _exercise(
        id: 'deadlift',
        name: 'Deadlift',
        description: 'Compound barbell pull targeting posterior chain.',
        equipment: Equipment.barbell,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.back,
          MuscleGroup.legs,
          MuscleGroup.glutes,
        ],
        goal: TrainingGoal.strengthIncrease,
        suitability: 10,
        sets: 5,
        reps: 4,
        duration: 75,
      ),
      _exercise(
        id: 'mountain_climbers',
        name: 'Mountain Climbers',
        description:
            'Dynamic core and cardio drill performed in plank position.',
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.core,
          MuscleGroup.legs,
          MuscleGroup.fullBody,
        ],
        goal: TrainingGoal.enduranceIncrease,
        suitability: 10,
        sets: 5,
        reps: 22,
        duration: 35,
      ),
      _exercise(
        id: 'bicep_curls',
        name: 'Bicep Curls',
        description: 'Isolation movement focusing on elbow flexors.',
        equipment: Equipment.dumbbells,
        targetMuscleGroups: const <MuscleGroup>[MuscleGroup.arms],
        goal: TrainingGoal.muscleGain,
        suitability: 8,
        sets: 4,
        reps: 12,
        duration: 45,
      ),
      _exercise(
        id: 'tricep_dips',
        name: 'Tricep Dips',
        description: 'Bodyweight dip variation for triceps and chest.',
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.arms,
          MuscleGroup.chest,
        ],
        goal: TrainingGoal.muscleGain,
        suitability: 7,
        sets: 4,
        reps: 10,
        duration: 45,
      ),
      _exercise(
        id: 'jump_rope',
        name: 'Jump Rope',
        description: 'Cardio-focused exercise for endurance and conditioning.',
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.legs,
          MuscleGroup.fullBody,
        ],
        goal: TrainingGoal.weightLoss,
        suitability: 10,
        sets: 5,
        reps: 30,
        duration: 45,
      ),
      _exercise(
        id: 'shoulder_press',
        name: 'Shoulder Press',
        description: 'Overhead dumbbell press for shoulder and arm strength.',
        equipment: Equipment.dumbbells,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.shoulders,
          MuscleGroup.arms,
        ],
        goal: TrainingGoal.strengthIncrease,
        suitability: 9,
        sets: 5,
        reps: 6,
        duration: 60,
      ),
      _exercise(
        id: 'russian_twists',
        name: 'Russian Twists',
        description: 'Rotational core movement that challenges trunk control.',
        equipment: Equipment.mat,
        targetMuscleGroups: const <MuscleGroup>[MuscleGroup.core],
        goal: TrainingGoal.weightLoss,
        suitability: 8,
        sets: 4,
        reps: 20,
        duration: 40,
      ),
      _exercise(
        id: 'kettlebell_swings',
        name: 'Kettlebell Swings',
        description:
            'Explosive hip hinge for power, cardio, and posterior chain.',
        equipment: Equipment.kettlebell,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.glutes,
          MuscleGroup.back,
          MuscleGroup.fullBody,
        ],
        goal: TrainingGoal.enduranceIncrease,
        suitability: 9,
        sets: 5,
        reps: 18,
        duration: 40,
      ),
      _exercise(
        id: 'glute_bridge',
        name: 'Glute Bridge',
        description: 'Hip extension drill to build glute strength and control.',
        equipment: Equipment.mat,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.glutes,
          MuscleGroup.core,
        ],
        goal: TrainingGoal.muscleGain,
        suitability: 8,
        sets: 4,
        reps: 15,
        duration: 45,
      ),
      _exercise(
        id: 'bicycle_crunches',
        name: 'Bicycle Crunches',
        description: 'Alternating core movement for abs and obliques.',
        equipment: Equipment.mat,
        targetMuscleGroups: const <MuscleGroup>[MuscleGroup.core],
        goal: TrainingGoal.weightLoss,
        suitability: 8,
        sets: 4,
        reps: 24,
        duration: 35,
      ),
      _exercise(
        id: 'goblet_squat',
        name: 'Goblet Squat',
        description: 'Front-loaded squat with a kettlebell or dumbbell.',
        equipment: Equipment.kettlebell,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.legs,
          MuscleGroup.glutes,
          MuscleGroup.core,
        ],
        goal: TrainingGoal.muscleGain,
        suitability: 9,
        sets: 4,
        reps: 10,
        duration: 55,
      ),
      _exercise(
        id: 'resistance_band_row',
        name: 'Resistance Band Row',
        description: 'Horizontal pulling movement using a resistance band.',
        equipment: Equipment.resistanceBand,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.back,
          MuscleGroup.arms,
        ],
        goal: TrainingGoal.strengthIncrease,
        suitability: 8,
        sets: 5,
        reps: 10,
        duration: 50,
      ),
      _exercise(
        id: 'incline_pushup',
        name: 'Incline Push-up',
        description: 'Upper-body pressing with reduced load and higher volume.',
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.chest,
          MuscleGroup.arms,
          MuscleGroup.shoulders,
        ],
        goal: TrainingGoal.enduranceIncrease,
        suitability: 8,
        sets: 4,
        reps: 16,
        duration: 40,
      ),
      _exercise(
        id: 'walking_lunges',
        name: 'Walking Lunges',
        description: 'Continuous lunge pattern with strong leg/cardio demand.',
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.legs,
          MuscleGroup.glutes,
        ],
        goal: TrainingGoal.weightLoss,
        suitability: 9,
        sets: 4,
        reps: 20,
        duration: 40,
      ),
      _exercise(
        id: 'high_knees',
        name: 'High Knees',
        description: 'Fast, in-place running drill for cardio conditioning.',
        equipment: Equipment.none,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.legs,
          MuscleGroup.core,
          MuscleGroup.fullBody,
        ],
        goal: TrainingGoal.enduranceIncrease,
        suitability: 9,
        sets: 5,
        reps: 28,
        duration: 35,
      ),
      _exercise(
        id: 'romanian_deadlift',
        name: 'Romanian Deadlift',
        description: 'Hip hinge pattern focused on hamstrings and glutes.',
        equipment: Equipment.barbell,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.glutes,
          MuscleGroup.back,
          MuscleGroup.legs,
        ],
        goal: TrainingGoal.strengthIncrease,
        suitability: 9,
        sets: 5,
        reps: 6,
        duration: 65,
      ),
      _exercise(
        id: 'dumbbell_row',
        name: 'Dumbbell Row',
        description: 'Unilateral row to build upper-back and arm strength.',
        equipment: Equipment.dumbbells,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.back,
          MuscleGroup.arms,
        ],
        goal: TrainingGoal.muscleGain,
        suitability: 9,
        sets: 4,
        reps: 10,
        duration: 50,
      ),
      _exercise(
        id: 'lateral_raises',
        name: 'Lateral Raises',
        description: 'Shoulder isolation movement for deltoid development.',
        equipment: Equipment.dumbbells,
        targetMuscleGroups: const <MuscleGroup>[MuscleGroup.shoulders],
        goal: TrainingGoal.muscleGain,
        suitability: 8,
        sets: 4,
        reps: 14,
        duration: 40,
      ),
      _exercise(
        id: 'hip_thrust',
        name: 'Hip Thrust',
        description: 'Powerful glute-focused lift with barbell loading.',
        equipment: Equipment.barbell,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.glutes,
          MuscleGroup.core,
        ],
        goal: TrainingGoal.strengthIncrease,
        suitability: 9,
        sets: 5,
        reps: 8,
        duration: 60,
      ),
      _exercise(
        id: 'farmer_carry',
        name: 'Farmer Carry',
        description:
            'Loaded carry improving grip, core, and total-body stamina.',
        equipment: Equipment.dumbbells,
        targetMuscleGroups: const <MuscleGroup>[
          MuscleGroup.core,
          MuscleGroup.arms,
          MuscleGroup.fullBody,
        ],
        goal: TrainingGoal.enduranceIncrease,
        suitability: 8,
        sets: 4,
        reps: 1,
        duration: 50,
      ),
    ];
  }
}
