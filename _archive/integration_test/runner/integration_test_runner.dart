import 'package:integration_test/integration_test_driver_extended.dart';

/// Entry point for the Flutter integration test driver.
/// Run via: flutter drive --driver=integration_test/runner/integration_test_runner.dart
Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        // data map contains any values returned from tests via
        // IntegrationTestWidgetsFlutterBinding.instance.reportData
        if (data != null) {
          for (final entry in data.entries) {
            print('[TestRunner] ${entry.key}: ${entry.value}');
          }
        }
      },
    );
