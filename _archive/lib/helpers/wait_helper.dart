import 'package:patrol/patrol.dart';

extension WaitHelpers on PatrolIntegrationTester {
  /// Polls [condition] every [pollInterval] until it returns true or [timeout] elapses.
  Future<void> waitUntil(
    Future<bool> Function() condition, {
    Duration timeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(milliseconds: 500),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await condition()) return;
      await Future<void>.delayed(pollInterval);
    }
    throw TimeoutException(
      'Condition not met within ${timeout.inSeconds}s',
      timeout,
    );
  }
}
