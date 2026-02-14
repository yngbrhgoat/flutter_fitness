import 'package:fitness_app/src/app_controller.dart';
import 'package:fitness_app/src/data/app_repository.dart';
import 'package:fitness_app/src/data/mock_backend_data_source.dart';
import 'package:fitness_app/src/ui/training_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows login screen after startup', (
    final WidgetTester tester,
  ) async {
    final AppController controller = AppController(
      repository: AppRepository(dataSource: MockBackendDataSource.seeded()),
    );

    await tester.pumpWidget(TrainingApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Training App Login'), findsOneWidget);
    expect(find.text('Login / Create Profile'), findsOneWidget);
  });

  testWidgets('shows top section menu after login', (
    final WidgetTester tester,
  ) async {
    final AppController controller = AppController(
      repository: AppRepository(dataSource: MockBackendDataSource.seeded()),
    );

    await tester.pumpWidget(TrainingApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'new_user');
    await tester.tap(find.text('Login / Create Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Browse Exercises'), findsWidgets);
    expect(find.text('Training Recommendations'), findsOneWidget);
    expect(find.text('Training History'), findsOneWidget);
  });
}
