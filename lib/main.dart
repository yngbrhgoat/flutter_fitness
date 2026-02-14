import 'package:flutter/widgets.dart';

import 'src/app_controller.dart';
import 'src/config/app_config.dart';
import 'src/data/app_repository.dart';
import 'src/data/backend_data_source.dart';
import 'src/data/mock_backend_data_source.dart';
import 'src/data/rest_backend_data_source.dart';
import 'src/ui/training_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final BackendDataSource dataSource = AppConfig.useMockBackend
      ? MockBackendDataSource.seeded()
      : RestBackendDataSource(baseUrl: AppConfig.backendBaseUrl);

  final AppRepository repository = AppRepository(dataSource: dataSource);
  final AppController controller = AppController(repository: repository);

  runApp(TrainingApp(controller: controller));
}
