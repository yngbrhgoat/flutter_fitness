import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../models/domain_models.dart';
import '../services/training_metrics_service.dart';

/// Root widget for the training application.
class TrainingApp extends StatefulWidget {
  /// Creates the app with a shared [AppController].
  const TrainingApp({required this.controller, super.key});

  /// Shared controller instance.
  final AppController controller;

  @override
  State<TrainingApp> createState() => _TrainingAppState();
}

class _TrainingAppState extends State<TrainingApp> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.initialize());
  }

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      title: 'Training App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E7A5D),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0.5,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F8F7),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9E5E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9E5E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E7A5D), width: 1.3),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1E7A5D),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: AnimatedBuilder(
        animation: widget.controller,
        builder: (final BuildContext context, final Widget? child) {
          if (widget.controller.isInitializing) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (widget.controller.currentUser == null) {
            return LoginScreen(controller: widget.controller);
          }

          return ExerciseBrowserScreen(controller: widget.controller);
        },
      ),
    );
  }
}

/// Login screen with recent-user quick selection and new-username creation.
class LoginScreen extends StatefulWidget {
  /// Creates the login screen.
  const LoginScreen({required this.controller, super.key});

  /// Shared app controller.
  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  UserProfile? _selectedUser;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String typedUsername = _usernameController.text.trim();
    if (typedUsername.isNotEmpty) {
      await widget.controller.loginOrCreateUser(typedUsername);
      return;
    }

    if (_selectedUser != null) {
      await widget.controller.loginWithExistingUser(_selectedUser!);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enter a username or choose a recent user.'),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training App Login')),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (final BuildContext context, final Widget? child) {
          final List<UserProfile> recentUsers = widget.controller.recentUsers;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter new or existing username',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserProfile>(
                      isExpanded: true,
                      initialValue: _selectedUser,
                      decoration: const InputDecoration(
                        labelText: 'Recent users',
                      ),
                      items: recentUsers
                          .map(
                            (final UserProfile user) =>
                                DropdownMenuItem<UserProfile>(
                                  value: user,
                                  child: Text(user.username),
                                ),
                          )
                          .toList(growable: false),
                      onChanged: (final UserProfile? user) {
                        setState(() {
                          _selectedUser = user;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: widget.controller.isBusy ? null : _submit,
                      child: widget.controller.isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login / Create Profile'),
                    ),
                    if (widget.controller.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        widget.controller.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _MainSection { browse, recommendations, history }

class _TopSectionMenu extends StatelessWidget implements PreferredSizeWidget {
  const _TopSectionMenu({
    required this.controller,
    required this.currentSection,
  });

  final AppController controller;
  final _MainSection currentSection;

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SegmentedButton<_MainSection>(
        showSelectedIcon: false,
        segments: const <ButtonSegment<_MainSection>>[
          ButtonSegment<_MainSection>(
            value: _MainSection.browse,
            icon: Icon(Icons.fitness_center),
            label: Text('Browse Exercises'),
          ),
          ButtonSegment<_MainSection>(
            value: _MainSection.recommendations,
            icon: Icon(Icons.auto_graph),
            label: Text('Training Recommendations'),
          ),
          ButtonSegment<_MainSection>(
            value: _MainSection.history,
            icon: Icon(Icons.history),
            label: Text('Training History'),
          ),
        ],
        selected: <_MainSection>{currentSection},
        onSelectionChanged: (final Set<_MainSection> selection) {
          if (selection.isEmpty) {
            return;
          }
          _navigateToSection(
            context: context,
            controller: controller,
            currentSection: currentSection,
            nextSection: selection.first,
          );
        },
      ),
    );
  }
}

void _navigateToSection({
  required final BuildContext context,
  required final AppController controller,
  required final _MainSection currentSection,
  required final _MainSection nextSection,
}) {
  if (currentSection == nextSection) {
    return;
  }

  final Widget destination = switch (nextSection) {
    _MainSection.browse => ExerciseBrowserScreen(controller: controller),
    _MainSection.recommendations => RecommendationScreen(
      controller: controller,
    ),
    _MainSection.history => HistoryScreen(controller: controller),
  };

  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (final BuildContext context) => destination,
    ),
  );
}

List<Exercise> _selectExercisesWithinBudget({
  required final List<RecommendationEntry> recommendations,
  required final int maxMinutes,
  required final TrainingGoal goal,
  required final int restSeconds,
}) {
  final int maxAllowedSeconds = (math.max(1, maxMinutes) * 60 * 1.1).round();
  final List<Exercise> selected = <Exercise>[];
  int total = 0;

  for (final RecommendationEntry recommendation in recommendations) {
    final Exercise exercise = recommendation.exercise;
    final int duration = exercise.estimatedDurationForGoalSeconds(
      goal: goal,
      restSecondsBetweenSets: restSeconds,
    );
    if (duration == 0) {
      continue;
    }
    if (total + duration <= maxAllowedSeconds) {
      selected.add(exercise);
      total += duration;
    }
  }

  return selected;
}

Future<void> _runLiveTrainingFlow({
  required final BuildContext context,
  required final AppController controller,
  required final TrainingGoal goal,
  required final List<Exercise> exercises,
  required final int restSecondsBetweenSets,
}) async {
  if (exercises.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No exercises fit the selected setup.')),
    );
    return;
  }

  final UserProfile? currentUser = controller.currentUser;
  if (currentUser == null) {
    return;
  }

  final TrainingSession? session = await Navigator.of(context)
      .push<TrainingSession>(
        MaterialPageRoute<TrainingSession>(
          builder: (final BuildContext context) {
            return LiveTrainingScreen(
              userId: currentUser.id,
              goal: goal,
              exercises: List<Exercise>.from(exercises),
              restSecondsBetweenSets: restSecondsBetweenSets,
            );
          },
        ),
      );

  if (session == null || !context.mounted) {
    return;
  }

  await controller.saveSession(session);
  if (!context.mounted) {
    return;
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (final BuildContext context) {
        return SessionSummaryScreen(session: session);
      },
    ),
  );
}

Future<void> _startWorkoutNow({
  required final BuildContext context,
  required final AppController controller,
}) async {
  final TrainingGoal goal = controller.preferredGoal;
  final List<RecommendationEntry> recommendations = controller
      .buildRecommendations(goal: goal)
      .toList(growable: false);
  final List<Exercise> selected = _selectExercisesWithinBudget(
    recommendations: recommendations,
    maxMinutes: 30,
    goal: goal,
    restSeconds: 45,
  );
  await _runLiveTrainingFlow(
    context: context,
    controller: controller,
    goal: goal,
    exercises: selected,
    restSecondsBetweenSets: 45,
  );
}

Future<void> _showProfileSettings({
  required final BuildContext context,
  required final AppController controller,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (final BuildContext context) {
      return AnimatedBuilder(
        animation: controller,
        builder: (final BuildContext context, final Widget? child) {
          final UserProfile? user = controller.currentUser;
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Profile & Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text('User: ${user?.username ?? '-'}'),
                const SizedBox(height: 14),
                DropdownButtonFormField<TrainingGoal>(
                  initialValue: controller.preferredGoal,
                  decoration: const InputDecoration(
                    labelText: 'Primary training goal',
                  ),
                  items: TrainingGoal.values
                      .map(
                        (final TrainingGoal goal) =>
                            DropdownMenuItem<TrainingGoal>(
                              value: goal,
                              child: Text(goal.label),
                            ),
                      )
                      .toList(growable: false),
                  onChanged: (final TrainingGoal? value) {
                    if (value == null) {
                      return;
                    }
                    unawaited(controller.updateCurrentUserPrimaryGoal(value));
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Updates apply immediately to browsing and recommendations.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (controller.isBusy) ...<Widget>[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

List<Widget> _buildAppBarActions({
  required final BuildContext context,
  required final AppController controller,
}) {
  return <Widget>[
    IconButton(
      onPressed: () {
        unawaited(_startWorkoutNow(context: context, controller: controller));
      },
      icon: const Icon(Icons.play_circle_fill_rounded),
      tooltip: 'Start Workout Now',
    ),
    IconButton(
      onPressed: () {
        unawaited(
          _showProfileSettings(context: context, controller: controller),
        );
      },
      icon: const Icon(Icons.tune),
      tooltip: 'Profile & Settings',
    ),
    TextButton(onPressed: controller.logout, child: const Text('Switch User')),
  ];
}

/// Exercise list + filter screen.
class ExerciseBrowserScreen extends StatefulWidget {
  /// Creates the exercise browser.
  const ExerciseBrowserScreen({required this.controller, super.key});

  /// Shared app controller.
  final AppController controller;

  @override
  State<ExerciseBrowserScreen> createState() => _ExerciseBrowserScreenState();
}

class _ExerciseBrowserScreenState extends State<ExerciseBrowserScreen> {
  TrainingGoal? _goalFilterOverride;
  MuscleGroup? _muscleFilter;
  Equipment? _equipmentFilter;

  List<Exercise> _filtered(
    final List<Exercise> source,
    final TrainingGoal goalFilter,
  ) {
    return source
        .where((final Exercise exercise) {
          final bool goalMatches = exercise.assignedGoal == goalFilter;
          final bool muscleMatches =
              _muscleFilter == null ||
              exercise.targetMuscleGroups.contains(_muscleFilter);
          final bool equipmentMatches =
              _equipmentFilter == null ||
              exercise.equipment == _equipmentFilter;
          return goalMatches && muscleMatches && equipmentMatches;
        })
        .toList(growable: false);
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Exercises'),
        actions: _buildAppBarActions(
          context: context,
          controller: widget.controller,
        ),
        bottom: _TopSectionMenu(
          controller: widget.controller,
          currentSection: _MainSection.browse,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bool? created = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (final BuildContext context) {
                return AddExerciseScreen(controller: widget.controller);
              },
            ),
          );
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exercise added successfully.')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (final BuildContext context, final Widget? child) {
          final TrainingGoal goalFilter =
              _goalFilterOverride ?? widget.controller.preferredGoal;
          final List<Exercise> filteredExercises = _filtered(
            widget.controller.exercises,
            goalFilter,
          );
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: <Widget>[
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<TrainingGoal>(
                        key: ValueKey<TrainingGoal>(goalFilter),
                        initialValue: goalFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Goal filter',
                        ),
                        items: TrainingGoal.values
                            .map(
                              (final TrainingGoal goal) =>
                                  DropdownMenuItem<TrainingGoal>(
                                    value: goal,
                                    child: Text(goal.label),
                                  ),
                            )
                            .toList(growable: false),
                        onChanged: (final TrainingGoal? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _goalFilterOverride = value;
                          });
                        },
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _goalFilterOverride = null;
                        });
                      },
                      child: Text(
                        'Use Primary (${widget.controller.preferredGoal.label})',
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<MuscleGroup?>(
                        initialValue: _muscleFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Muscle group',
                        ),
                        items: <DropdownMenuItem<MuscleGroup?>>[
                          const DropdownMenuItem<MuscleGroup?>(
                            value: null,
                            child: Text('All groups'),
                          ),
                          ...MuscleGroup.values.map(
                            (final MuscleGroup group) =>
                                DropdownMenuItem<MuscleGroup?>(
                                  value: group,
                                  child: Text(group.label),
                                ),
                          ),
                        ],
                        onChanged: (final MuscleGroup? value) {
                          setState(() {
                            _muscleFilter = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<Equipment?>(
                        initialValue: _equipmentFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Equipment',
                        ),
                        items: <DropdownMenuItem<Equipment?>>[
                          const DropdownMenuItem<Equipment?>(
                            value: null,
                            child: Text('All equipment'),
                          ),
                          ...Equipment.values.map(
                            (final Equipment equipment) =>
                                DropdownMenuItem<Equipment?>(
                                  value: equipment,
                                  child: Text(equipment.label),
                                ),
                          ),
                        ],
                        onChanged: (final Equipment? value) {
                          setState(() {
                            _equipmentFilter = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredExercises.length,
                  itemBuilder: (final BuildContext context, final int index) {
                    final Exercise exercise = filteredExercises[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(exercise.name),
                        subtitle: Text(
                          '${exercise.assignedGoal?.label ?? '-'} • '
                          '${exercise.equipment.label} • '
                          '${exercise.targetMuscleGroups.map((final MuscleGroup group) => group.label).join(', ')}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (final BuildContext context) {
                                return ExerciseDetailScreen(exercise: exercise);
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Exercise detail view with all goal-specific parameters.
class ExerciseDetailScreen extends StatelessWidget {
  /// Creates an exercise detail screen.
  const ExerciseDetailScreen({required this.exercise, super.key});

  /// Exercise shown in detail.
  final Exercise exercise;

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _ExerciseMediaPreview(mediaUrl: exercise.mediaUrl),
          const SizedBox(height: 12),
          Text(
            exercise.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text('Equipment: ${exercise.equipment.label}'),
          const SizedBox(height: 8),
          Text(
            'Muscle groups: '
            '${exercise.targetMuscleGroups.map((final MuscleGroup group) => group.label).join(', ')}',
          ),
          const SizedBox(height: 16),
          Text(
            'Goal configurations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...TrainingGoal.values.map((final TrainingGoal goal) {
            final GoalConfiguration config = exercise.configurationForGoal(
              goal,
            );
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      goal.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text('Suitability: ${config.suitabilityRating}/10'),
                    Text('Recommended sets: ${config.recommendedSets}'),
                    Text(
                      'Recommended repetitions: ${config.recommendedRepetitions}',
                    ),
                    Text(
                      'Recommended duration: ${config.recommendedDurationSeconds}s',
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Add-exercise form screen.
class AddExerciseScreen extends StatefulWidget {
  /// Creates the add-exercise screen.
  const AddExerciseScreen({required this.controller, super.key});

  /// Shared app controller.
  final AppController controller;

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _mediaUrlController = TextEditingController();

  Equipment _selectedEquipment = Equipment.none;
  final Set<MuscleGroup> _selectedMuscles = <MuscleGroup>{};
  bool _showMuscleError = false;

  late final Map<TrainingGoal, _GoalInputControllers> _goalControllers;

  @override
  void initState() {
    super.initState();
    _goalControllers = <TrainingGoal, _GoalInputControllers>{
      for (final TrainingGoal goal in TrainingGoal.values)
        goal: _GoalInputControllers(),
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _mediaUrlController.dispose();
    for (final _GoalInputControllers controllers in _goalControllers.values) {
      controllers.dispose();
    }
    super.dispose();
  }

  String? _validateRequiredInt(
    final String? value, {
    required final String fieldName,
    required final int min,
    required final int max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    final int? parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName must be a number.';
    }
    if (parsed < min || parsed > max) {
      return '$fieldName must be between $min and $max.';
    }
    return null;
  }

  Future<void> _submit() async {
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    if (_selectedMuscles.isEmpty) {
      setState(() {
        _showMuscleError = true;
      });
      return;
    }

    final Map<TrainingGoal, GoalConfiguration> configurations =
        <TrainingGoal, GoalConfiguration>{};
    int suitableGoalCount = 0;

    for (final TrainingGoal goal in TrainingGoal.values) {
      final _GoalInputControllers controllers = _goalControllers[goal]!;
      final int suitability = int.parse(controllers.suitability.text.trim());
      final int sets = int.parse(controllers.sets.text.trim());
      final int repetitions = int.parse(controllers.repetitions.text.trim());
      final int duration = int.parse(controllers.duration.text.trim());

      if (suitability == 0) {
        final bool hasNonZeroValues =
            sets != 0 || repetitions != 0 || duration != 0;
        if (hasNonZeroValues) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${goal.label}: sets/repetitions/duration must be 0 when suitability is 0.',
              ),
            ),
          );
          return;
        }
      } else {
        final bool hasMissingValues =
            sets <= 0 || repetitions <= 0 || duration <= 0;
        if (hasMissingValues) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${goal.label}: sets/repetitions/duration must be > 0 when suitability > 0.',
              ),
            ),
          );
          return;
        }
      }

      if (suitability > 0) {
        suitableGoalCount += 1;
      }
      configurations[goal] = GoalConfiguration(
        suitabilityRating: suitability,
        recommendedSets: sets,
        recommendedRepetitions: repetitions,
        recommendedDurationSeconds: duration,
      );
    }

    if (suitableGoalCount != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Each exercise must be assigned to exactly one goal.'),
        ),
      );
      return;
    }

    final Exercise exercise = Exercise(
      id: 'exercise_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      mediaUrl: _mediaUrlController.text.trim().isEmpty
          ? null
          : _mediaUrlController.text.trim(),
      equipment: _selectedEquipment,
      targetMuscleGroups: _selectedMuscles.toList(growable: false),
      goalConfigurations: configurations,
    );

    await widget.controller.addExercise(exercise);
    if (!mounted) {
      return;
    }

    if (widget.controller.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.controller.errorMessage!)));
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Exercise')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (final String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
              validator: (final String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mediaUrlController,
              decoration: const InputDecoration(
                labelText: 'Image/Icon URL (optional)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Equipment>(
              initialValue: _selectedEquipment,
              decoration: const InputDecoration(labelText: 'Equipment'),
              items: Equipment.values
                  .map(
                    (final Equipment equipment) => DropdownMenuItem<Equipment>(
                      value: equipment,
                      child: Text(equipment.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (final Equipment? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedEquipment = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Target muscle groups',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MuscleGroup.values
                  .map((final MuscleGroup group) {
                    final bool selected = _selectedMuscles.contains(group);
                    return FilterChip(
                      label: Text(group.label),
                      selected: selected,
                      onSelected: (final bool value) {
                        setState(() {
                          _showMuscleError = false;
                          if (value) {
                            _selectedMuscles.add(group);
                          } else {
                            _selectedMuscles.remove(group);
                          }
                        });
                      },
                    );
                  })
                  .toList(growable: false),
            ),
            if (_showMuscleError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Select at least one muscle group.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Goal configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Set suitability > 0 for exactly one goal. All others must stay 0.',
            ),
            const SizedBox(height: 8),
            ...TrainingGoal.values.map((final TrainingGoal goal) {
              final _GoalInputControllers controllers = _goalControllers[goal]!;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        goal.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controllers.suitability,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Suitability (0-10)',
                        ),
                        validator: (final String? value) {
                          return _validateRequiredInt(
                            value,
                            fieldName: '${goal.label} suitability',
                            min: 0,
                            max: 10,
                          );
                        },
                      ),
                      TextFormField(
                        controller: controllers.sets,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Recommended sets',
                        ),
                        validator: (final String? value) {
                          return _validateRequiredInt(
                            value,
                            fieldName: '${goal.label} sets',
                            min: 0,
                            max: 99,
                          );
                        },
                      ),
                      TextFormField(
                        controller: controllers.repetitions,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Recommended repetitions',
                        ),
                        validator: (final String? value) {
                          return _validateRequiredInt(
                            value,
                            fieldName: '${goal.label} repetitions',
                            min: 0,
                            max: 999,
                          );
                        },
                      ),
                      TextFormField(
                        controller: controllers.duration,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Recommended duration (seconds)',
                        ),
                        validator: (final String? value) {
                          return _validateRequiredInt(
                            value,
                            fieldName: '${goal.label} duration',
                            min: 0,
                            max: 9999,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.controller.isBusy ? null : _submit,
              child: const Text('Save Exercise'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recommendation + workout assembly screen.
class RecommendationScreen extends StatefulWidget {
  /// Creates the recommendation screen.
  const RecommendationScreen({required this.controller, super.key});

  /// Shared app controller.
  final AppController controller;

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final TextEditingController _maxMinutesController = TextEditingController(
    text: '30',
  );

  int _restSeconds = 45;

  List<RecommendationEntry> _recommendations = <RecommendationEntry>[];
  List<Exercise> _selectedExercises = <Exercise>[];

  TrainingGoal get _selectedGoal => widget.controller.preferredGoal;

  @override
  void initState() {
    super.initState();
    _maxMinutesController.addListener(_refreshRecommendations);
    widget.controller.addListener(_handleControllerChange);
    _refreshRecommendations();
  }

  void _handleControllerChange() {
    if (!mounted) {
      return;
    }
    _refreshRecommendations();
  }

  @override
  void dispose() {
    _maxMinutesController.removeListener(_refreshRecommendations);
    widget.controller.removeListener(_handleControllerChange);
    _maxMinutesController.dispose();
    super.dispose();
  }

  int _readMaxMinutes() {
    final int parsed = int.tryParse(_maxMinutesController.text.trim()) ?? 30;
    return parsed.clamp(1, 240).toInt();
  }

  void _refreshRecommendations() {
    final int maxMinutes = _readMaxMinutes();
    final TrainingGoal goal = _selectedGoal;
    final List<RecommendationEntry> recommendations = widget.controller
        .buildRecommendations(goal: goal)
        .toList(growable: false);

    final List<Exercise> autoSelected = _selectExercisesWithinBudget(
      recommendations: recommendations,
      maxMinutes: maxMinutes,
      goal: goal,
      restSeconds: _restSeconds,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _recommendations = recommendations;
      _selectedExercises = autoSelected;
    });
  }

  int get _estimatedTotalDurationSeconds {
    return widget.controller.estimateDurationSeconds(
      exercises: _selectedExercises,
      goal: _selectedGoal,
      restSecondsBetweenSets: _restSeconds,
    );
  }

  Future<void> _startTraining() async {
    await _runLiveTrainingFlow(
      context: context,
      controller: widget.controller,
      goal: _selectedGoal,
      exercises: _selectedExercises,
      restSecondsBetweenSets: _restSeconds,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final int maxMinutes = _readMaxMinutes();
    final bool isOverBudget = widget.controller.isOverBudget(
      estimatedDurationSeconds: _estimatedTotalDurationSeconds,
      maxDurationMinutes: maxMinutes,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Recommendations'),
        actions: _buildAppBarActions(
          context: context,
          controller: widget.controller,
        ),
        bottom: _TopSectionMenu(
          controller: widget.controller,
          currentSection: _MainSection.recommendations,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFF5F8F7),
                  ),
                  child: Text('Primary goal: ${_selectedGoal.label}'),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _maxMinutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max duration (minutes)',
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int>(
                    initialValue: _restSeconds,
                    decoration: const InputDecoration(
                      labelText: 'Rest between sets',
                    ),
                    items: const <DropdownMenuItem<int>>[
                      DropdownMenuItem<int>(
                        value: 30,
                        child: Text('30 seconds'),
                      ),
                      DropdownMenuItem<int>(
                        value: 45,
                        child: Text('45 seconds'),
                      ),
                      DropdownMenuItem<int>(
                        value: 60,
                        child: Text('60 seconds'),
                      ),
                    ],
                    onChanged: (final int? value) {
                      if (value == null) {
                        return;
                      }
                      _restSeconds = value;
                      _refreshRecommendations();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Estimated duration: ${(_estimatedTotalDurationSeconds / 60).toStringAsFixed(1)} min',
            ),
            if (isOverBudget)
              Text(
                'Warning: selected exercises exceed your time budget significantly.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (final BuildContext context, final BoxConstraints constraints) {
                  final Widget recommendationsPanel = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _recommendations.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching exercises for your current goal.',
                              ),
                            )
                          : ListView.builder(
                              itemCount: _recommendations.length,
                              itemBuilder: (final BuildContext context, final int index) {
                                final RecommendationEntry entry =
                                    _recommendations[index];
                                final bool selected = _selectedExercises.any(
                                  (final Exercise ex) =>
                                      ex.id == entry.exercise.id,
                                );
                                return CheckboxListTile(
                                  value: selected,
                                  title: Text(entry.exercise.name),
                                  subtitle: Text(
                                    'Score ${entry.finalScore.toStringAsFixed(2)} '
                                    '(Suitability ${entry.suitabilityScore.toStringAsFixed(1)} '
                                    '• Novelty ${entry.noveltyScore.toStringAsFixed(1)})',
                                  ),
                                  onChanged: (final bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        final bool alreadySelected =
                                            _selectedExercises.any(
                                              (final Exercise exercise) =>
                                                  exercise.id ==
                                                  entry.exercise.id,
                                            );
                                        if (!alreadySelected) {
                                          _selectedExercises.add(
                                            entry.exercise,
                                          );
                                        }
                                      } else {
                                        _selectedExercises.removeWhere(
                                          (final Exercise exercise) =>
                                              exercise.id == entry.exercise.id,
                                        );
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  );

                  final Widget selectedPanel = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Selected Order',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ReorderableListView.builder(
                              itemCount: _selectedExercises.length,
                              onReorder:
                                  (final int oldIndex, final int newIndex) {
                                    setState(() {
                                      final int targetIndex =
                                          oldIndex < newIndex
                                          ? newIndex - 1
                                          : newIndex;
                                      final Exercise moved = _selectedExercises
                                          .removeAt(oldIndex);
                                      _selectedExercises.insert(
                                        targetIndex,
                                        moved,
                                      );
                                    });
                                  },
                              itemBuilder:
                                  (
                                    final BuildContext context,
                                    final int index,
                                  ) {
                                    final Exercise exercise =
                                        _selectedExercises[index];
                                    final int estimated = exercise
                                        .estimatedDurationForGoalSeconds(
                                          goal: _selectedGoal,
                                          restSecondsBetweenSets: _restSeconds,
                                        );
                                    return ListTile(
                                      key: ValueKey<String>(
                                        'selected_${exercise.id}',
                                      ),
                                      title: Text(exercise.name),
                                      subtitle: Text(
                                        '${(estimated / 60).toStringAsFixed(1)} min',
                                      ),
                                    );
                                  },
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _startTraining,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Training'),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: <Widget>[
                        Expanded(child: recommendationsPanel),
                        const SizedBox(height: 10),
                        Expanded(child: selectedPanel),
                      ],
                    );
                  }

                  return Row(
                    children: <Widget>[
                      Expanded(child: recommendationsPanel),
                      const SizedBox(width: 10),
                      Expanded(child: selectedPanel),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live training screen with sequential execution and timer controls.
class LiveTrainingScreen extends StatefulWidget {
  /// Creates a live training screen.
  const LiveTrainingScreen({
    required this.userId,
    required this.goal,
    required this.exercises,
    required this.restSecondsBetweenSets,
    super.key,
  });

  /// Current user id.
  final String userId;

  /// Training goal.
  final TrainingGoal goal;

  /// Ordered exercise list.
  final List<Exercise> exercises;

  /// Initial rest duration between sets.
  final int restSecondsBetweenSets;

  @override
  State<LiveTrainingScreen> createState() => _LiveTrainingScreenState();
}

class _LiveTrainingScreenState extends State<LiveTrainingScreen> {
  static const TrainingMetricsService _metrics = TrainingMetricsService();

  final Map<String, _ExerciseRuntimeProgress> _progressByExerciseId =
      <String, _ExerciseRuntimeProgress>{};

  Timer? _ticker;
  DateTime? _sessionStartedAt;

  int _currentExerciseIndex = 0;
  int _currentSetNumber = 1;
  int _elapsedSetSeconds = 0;
  int _totalElapsedSeconds = 0;

  bool _isPaused = false;
  bool _inRest = false;
  bool _finished = false;

  int _restSeconds = 45;
  int _restRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _restSeconds = widget.restSecondsBetweenSets.clamp(30, 60);
    _restRemainingSeconds = _restSeconds;

    for (final Exercise exercise in widget.exercises) {
      _progressByExerciseId[exercise.id] = _ExerciseRuntimeProgress(
        exercise: exercise,
        plannedSets: exercise.configurationForGoal(widget.goal).recommendedSets,
      );
    }

    _sessionStartedAt = DateTime.now();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  Exercise get _currentExercise => widget.exercises[_currentExerciseIndex];

  GoalConfiguration get _currentConfiguration {
    return _currentExercise.configurationForGoal(widget.goal);
  }

  _ExerciseRuntimeProgress get _currentProgress {
    return _progressByExerciseId[_currentExercise.id]!;
  }

  int get _plannedSetCountTotal {
    int total = 0;
    for (final _ExerciseRuntimeProgress progress
        in _progressByExerciseId.values) {
      total += progress.plannedSets;
    }
    return total;
  }

  int get _completedSetCountTotal {
    int total = 0;
    for (final _ExerciseRuntimeProgress progress
        in _progressByExerciseId.values) {
      total += progress.completedSets;
    }
    return total;
  }

  String _formatElapsedClock(final int totalSeconds) {
    final Duration duration = Duration(seconds: math.max(0, totalSeconds));
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onTick(final Timer timer) {
    if (!mounted || _finished || _isPaused) {
      return;
    }

    setState(() {
      _totalElapsedSeconds += 1;
      _currentProgress.durationSeconds += 1;

      if (_inRest) {
        _restRemainingSeconds -= 1;
        if (_restRemainingSeconds <= 0) {
          _inRest = false;
          _elapsedSetSeconds = 0;
          _signalTransition('Set $_currentSetNumber started');
        }
        return;
      }

      _elapsedSetSeconds += 1;
      final int targetSetDuration =
          _currentConfiguration.recommendedDurationSeconds;
      if (targetSetDuration > 0 && _elapsedSetSeconds >= targetSetDuration) {
        _completeCurrentSetInternal();
      }
    });
  }

  void _signalTransition(final String message) {
    unawaited(SystemSound.play(SystemSoundType.alert));
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 850),
      ),
    );
  }

  void _completeCurrentSetInternal() {
    final _ExerciseRuntimeProgress progress = _currentProgress;
    final int plannedSets = _currentConfiguration.recommendedSets;

    if (plannedSets <= 0) {
      _moveToNextExerciseInternal(markSkipped: true);
      return;
    }

    if (progress.completedSets < plannedSets) {
      progress.completedSets += 1;
    }

    if (progress.completedSets >= plannedSets) {
      _moveToNextExerciseInternal();
      return;
    }

    _currentSetNumber = progress.completedSets + 1;
    _elapsedSetSeconds = 0;
    _inRest = true;
    _restRemainingSeconds = _restSeconds;
    _signalTransition('Rest $_restSeconds s');
  }

  void _moveToNextExerciseInternal({final bool markSkipped = false}) {
    final _ExerciseRuntimeProgress progress = _currentProgress;
    if (markSkipped) {
      progress.skipped = true;
    }

    if (_currentExerciseIndex + 1 >= widget.exercises.length) {
      _finishSessionInternal();
      return;
    }

    _currentExerciseIndex += 1;
    _currentSetNumber = 1;
    _elapsedSetSeconds = 0;
    _inRest = false;
    _restRemainingSeconds = _restSeconds;

    _signalTransition('Next: ${_currentExercise.name}');
  }

  int _currentExpectedRepetition() {
    return _metrics.expectedRepetitionNumber(
      elapsedSeconds: _elapsedSetSeconds,
      totalDurationSeconds: _currentConfiguration.recommendedDurationSeconds,
      totalRepetitions: _currentConfiguration.recommendedRepetitions,
    );
  }

  void _finishSessionInternal() {
    if (_finished) {
      return;
    }
    _finished = true;
    _ticker?.cancel();

    final DateTime endedAt = DateTime.now();
    final DateTime startedAt = _sessionStartedAt ?? endedAt;

    final List<SessionExerciseEntry> entries = widget.exercises
        .map((final Exercise exercise) {
          final _ExerciseRuntimeProgress progress =
              _progressByExerciseId[exercise.id]!;
          final bool skipped = progress.skipped || progress.completedSets == 0;
          return SessionExerciseEntry(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            completedSets: progress.completedSets,
            plannedSets: progress.plannedSets,
            durationSeconds: progress.durationSeconds,
            skipped: skipped,
          );
        })
        .toList(growable: false);

    final TrainingSession session = TrainingSession(
      id: 'session_${endedAt.microsecondsSinceEpoch}',
      userId: widget.userId,
      goal: widget.goal,
      startedAt: startedAt,
      endedAt: endedAt,
      exerciseEntries: entries,
    );

    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    Navigator.of(context).pop(session);
  }

  @override
  Widget build(final BuildContext context) {
    final int expectedRepetition = _currentExpectedRepetition();
    final int displayedRepetition = expectedRepetition;
    final TempoPaceStatus pace = _metrics.evaluateTempoPace(
      currentRepetition: displayedRepetition,
      expectedRepetition: expectedRepetition,
    );
    final double completionPercent = _metrics.calculateCompletionPercentage(
      completedUnits: _completedSetCountTotal,
      totalUnits: _plannedSetCountTotal,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Mode'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              setState(() {
                _isPaused = !_isPaused;
              });
            },
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            tooltip: _isPaused ? 'Resume' : 'Pause',
          ),
          IconButton(
            onPressed: _finishSessionInternal,
            icon: const Icon(Icons.stop),
            tooltip: 'End Training',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Elapsed Time',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatElapsedClock(_totalElapsedSeconds),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _inRest
                                ? 'Rest: $_restRemainingSeconds s remaining'
                                : 'Set timer: ${_formatElapsedClock(_elapsedSetSeconds)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PieProgressIndicator(
                      progress: completionPercent / 100.0,
                      label:
                          '${completionPercent.clamp(0, 100).toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Exercise ${_currentExerciseIndex + 1} of ${widget.exercises.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: completionPercent / 100.0),
            const SizedBox(height: 8),
            Text('Overall progress: ${completionPercent.toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _ExerciseMediaPreview(mediaUrl: _currentExercise.mediaUrl),
                    const SizedBox(height: 10),
                    Text(
                      _currentExercise.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(_currentExercise.description),
                    const SizedBox(height: 8),
                    Text('Equipment: ${_currentExercise.equipment.label}'),
                    Text(
                      'Muscles: ${_currentExercise.targetMuscleGroups.map((final MuscleGroup group) => group.label).join(', ')}',
                    ),
                    Text('Goal: ${widget.goal.label}'),
                    Text(
                      'Set $_currentSetNumber of ${_currentConfiguration.recommendedSets}',
                    ),
                    Text(
                      'Repetition $displayedRepetition of ${_currentConfiguration.recommendedRepetitions}',
                    ),
                    Text('Set timer: $_elapsedSetSeconds s'),
                    Text('Tempo: ${_metrics.paceLabel(pace)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: _inRest
                      ? null
                      : () {
                          setState(() {
                            _completeCurrentSetInternal();
                          });
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Next Set'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      final bool markSkipped =
                          _currentProgress.completedSets == 0;
                      _moveToNextExerciseInternal(markSkipped: markSkipped);
                    });
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Next Exercise'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _moveToNextExerciseInternal(markSkipped: true);
                    });
                  },
                  icon: const Icon(Icons.fast_forward),
                  label: const Text('Skip Exercise'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isPaused = !_isPaused;
                    });
                  },
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(_isPaused ? 'Resume' : 'Pause'),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int>(
                    initialValue: _restSeconds,
                    decoration: const InputDecoration(
                      labelText: 'Rest seconds',
                    ),
                    items: const <DropdownMenuItem<int>>[
                      DropdownMenuItem<int>(value: 30, child: Text('30 sec')),
                      DropdownMenuItem<int>(value: 45, child: Text('45 sec')),
                      DropdownMenuItem<int>(value: 60, child: Text('60 sec')),
                    ],
                    onChanged: (final int? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _restSeconds = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Training session summary screen.
class SessionSummaryScreen extends StatelessWidget {
  /// Creates a session summary screen.
  const SessionSummaryScreen({required this.session, super.key});

  /// Session to summarize.
  final TrainingSession session;

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Goal: ${session.goal.label}'),
          const SizedBox(height: 6),
          Text('Total time: ${session.totalDurationSeconds} s'),
          Text('Completed sets: ${session.totalCompletedSets}'),
          const SizedBox(height: 10),
          Text(
            'Completed exercises: '
            '${session.completedExerciseNames.isEmpty ? '-' : session.completedExerciseNames.join(', ')}',
          ),
          const SizedBox(height: 6),
          Text(
            'Skipped exercises: '
            '${session.skippedExerciseNames.isEmpty ? '-' : session.skippedExerciseNames.join(', ')}',
          ),
          const SizedBox(height: 16),
          ...session.exerciseEntries.map((final SessionExerciseEntry entry) {
            return Card(
              child: ListTile(
                title: Text(entry.exerciseName),
                subtitle: Text(
                  'Sets ${entry.completedSets}/${entry.plannedSets} '
                  '• ${entry.durationSeconds}s',
                ),
                trailing: Icon(
                  entry.skipped ? Icons.cancel : Icons.check_circle_outline,
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Start New Training Session'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).popUntil((final Route<dynamic> route) {
                return route.isFirst;
              });
            },
            child: const Text('Return to Home'),
          ),
        ],
      ),
    );
  }
}

/// User history screen with date filtering and statistics.
class HistoryScreen extends StatefulWidget {
  /// Creates the history screen.
  const HistoryScreen({required this.controller, super.key});

  /// Shared app controller.
  final AppController controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.refreshCurrentUserHistory());
  }

  Future<void> _pickStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime initialDate = (_start ?? today).isAfter(today)
        ? today
        : (_start ?? today);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: today,
    );
    if (picked != null) {
      setState(() {
        _start = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime initialDate = (_end ?? today).isAfter(today)
        ? today
        : (_end ?? today);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: today,
    );
    if (picked != null) {
      setState(() {
        _end = picked;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training History'),
        actions: _buildAppBarActions(
          context: context,
          controller: widget.controller,
        ),
        bottom: _TopSectionMenu(
          controller: widget.controller,
          currentSection: _MainSection.history,
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (final BuildContext context, final Widget? child) {
          final List<TrainingSession> sessions = widget.controller
              .filteredSessions(start: _start, end: _end);
          final TrainingStatistics stats = widget.controller.statistics;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text('Total sessions: ${stats.totalSessions}'),
                      Text(
                        'Total exercise time: ${stats.totalExerciseTimeSeconds} s',
                      ),
                      Text(
                        'Most frequent: '
                        '${stats.mostFrequentExercises.isEmpty ? '-' : stats.mostFrequentExercises.map((final MapEntry<String, int> item) => '${item.key} (${item.value})').join(', ')}',
                      ),
                      Text(
                        'This week: '
                        '${stats.exercisesThisWeek.isEmpty ? '-' : stats.exercisesThisWeek.join(', ')}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _start == null
                          ? 'Start date'
                          : '${_start!.year}-${_start!.month.toString().padLeft(2, '0')}-${_start!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickEndDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _end == null
                          ? 'End date'
                          : '${_end!.year}-${_end!.month.toString().padLeft(2, '0')}-${_end!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _start = null;
                        _end = null;
                      });
                    },
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...sessions.map((final TrainingSession session) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${session.startedAt.year}-${session.startedAt.month.toString().padLeft(2, '0')}-${session.startedAt.day.toString().padLeft(2, '0')} '
                          '${session.startedAt.hour.toString().padLeft(2, '0')}:${session.startedAt.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text('Goal: ${session.goal.label}'),
                        Text('Duration: ${session.totalDurationSeconds} s'),
                        Text(
                          'Exercises: ${session.exerciseEntries.map((final SessionExerciseEntry entry) => entry.exerciseName).join(', ')}',
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('No sessions in selected range.'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ExerciseMediaPreview extends StatelessWidget {
  const _ExerciseMediaPreview({required this.mediaUrl});

  final String? mediaUrl;

  @override
  Widget build(final BuildContext context) {
    if (mediaUrl == null || mediaUrl!.trim().isEmpty) {
      return Container(
        height: 160,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_not_supported, size: 42),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        mediaUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (
              final BuildContext context,
              final Object error,
              final StackTrace? stackTrace,
            ) {
              return Container(
                height: 180,
                width: double.infinity,
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image, size: 42),
              );
            },
      ),
    );
  }
}

class _PieProgressIndicator extends StatelessWidget {
  const _PieProgressIndicator({
    required this.progress,
    required this.label,
    this.size = 96,
  });

  final double progress;
  final String label;
  final double size;

  @override
  Widget build(final BuildContext context) {
    final double safeProgress = progress.clamp(0.0, 1.0);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size.square(size),
            painter: _PieProgressPainter(
              progress: safeProgress,
              progressColor: colors.primary,
              backgroundColor: colors.primary.withOpacity(0.14),
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PieProgressPainter extends CustomPainter {
  _PieProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  @override
  void paint(final Canvas canvas, final Size size) {
    final Rect rect = Offset.zero & size;
    final Offset center = rect.center;
    final double radius = math.min(size.width, size.height) / 2;

    final Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress <= 0) {
      return;
    }

    final Paint progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      true,
      progressPaint,
    );

    final Paint centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.45, centerPaint);
  }

  @override
  bool shouldRepaint(covariant final _PieProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _GoalInputControllers {
  _GoalInputControllers()
    : suitability = TextEditingController(text: '0'),
      sets = TextEditingController(text: '0'),
      repetitions = TextEditingController(text: '0'),
      duration = TextEditingController(text: '0');

  final TextEditingController suitability;
  final TextEditingController sets;
  final TextEditingController repetitions;
  final TextEditingController duration;

  void dispose() {
    suitability.dispose();
    sets.dispose();
    repetitions.dispose();
    duration.dispose();
  }
}

class _ExerciseRuntimeProgress {
  _ExerciseRuntimeProgress({required this.exercise, required this.plannedSets});

  final Exercise exercise;
  final int plannedSets;

  int completedSets = 0;
  int durationSeconds = 0;
  bool skipped = false;
}
