import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';

/// Converts Android instrumentation runner output + optional device logcat
/// to Allure-compatible JSON.
///
/// --input is optional. When omitted, --logcat alone is enough to produce
/// a full Allure report (logcat-only mode: derives test names, pass/fail,
/// steps and parameters entirely from the device logcat).
///
/// Typical one-step workflow after a patrol run:
///
///   adb logcat -d > reports/logcat_<id>.txt
///   dart run tool/convert_to_allure.dart \
///     --logcat reports/logcat_<id>.txt \
///     --output reports/allure-results/ \
///     --suite  gameplay \
///     --api-level 34
///
/// Legacy workflow (instrumentation output file):
///
///   dart run tool/convert_to_allure.dart \
///     --input  reports/raw_output.txt \
///     --output reports/allure-results/ \
///     --suite  gameplay \
///     --api-level 34 \
///     --logcat reports/logcat_<id>.txt   # enriches steps + params
void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('input',     abbr: 'i', help: 'Instrumentation output file (optional when --logcat is provided)')
    ..addOption('output',    abbr: 'o', mandatory: true)
    ..addOption('suite',     abbr: 's', defaultsTo: 'unknown')
    ..addOption('api-level', abbr: 'a', defaultsTo: 'unknown')
    ..addOption('logcat',    abbr: 'l', help: 'Device logcat file (adb logcat -d > file.txt)');

  final opts       = parser.parse(args);
  final inputPath  = opts['input']     as String?;
  final outputDir  = opts['output']    as String;
  final suite      = opts['suite']     as String;
  final apiLevel   = opts['api-level'] as String;
  final logcatPath = opts['logcat']    as String?;

  if (inputPath == null && logcatPath == null) {
    stderr.writeln('ERROR: Provide --input, --logcat, or both.');
    exit(1);
  }

  Directory(outputDir).createSync(recursive: true);

  List<Map<String, dynamic>> results;

  if (inputPath != null) {
    // Legacy / CI mode: instrumentation output as primary source.
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      stderr.writeln('ERROR: Input file not found: $inputPath');
      exit(1);
    }
    final logcatMap = logcatPath != null ? _parseLogcat(logcatPath) : <String, _TestLogs>{};
    results = _parseInstrumentationOutput(inputFile.readAsLinesSync(), suite, apiLevel, logcatMap);
  } else {
    // Logcat-only mode: derive everything from the device logcat.
    results = _parseLogcatOnly(logcatPath!, suite, apiLevel);
  }

  for (final result in results) {
    final id = _uuid();
    File('$outputDir/$id-result.json').writeAsStringSync(jsonEncode(result));
  }

  _writeCategoriesJson(outputDir);
  final mode = inputPath != null
      ? (logcatPath != null ? 'instrumentation + logcat' : 'instrumentation only')
      : 'logcat only';
  stdout.writeln('Converted ${results.length} tests → $outputDir [$mode]');
}

// ── Instrumentation output parsing ─────────────────────────────────────────

List<Map<String, dynamic>> _parseInstrumentationOutput(
  List<String> lines,
  String suite,
  String apiLevel,
  Map<String, _TestLogs> logcatMap,
) {
  final results  = <Map<String, dynamic>>[];
  String? testName;
  String  status  = 'passed';
  final   trace   = StringBuffer();
  final   start   = DateTime.now().millisecondsSinceEpoch;

  for (final line in lines) {
    if (line.startsWith('INSTRUMENTATION_STATUS: test=')) {
      testName = line.split('=').last.trim();
      status   = 'passed';
      trace.clear();
    } else if (line.startsWith('INSTRUMENTATION_STATUS: stack=')) {
      trace.writeln(line.replaceFirst('INSTRUMENTATION_STATUS: stack=', ''));
      status = 'failed';
    } else if (line.startsWith('INSTRUMENTATION_STATUS_CODE: -2')) {
      status = 'skipped';
    } else if (line.startsWith('INSTRUMENTATION_STATUS_CODE: -1')) {
      status = 'broken';
    } else if (line.startsWith('INSTRUMENTATION_STATUS_CODE: 0') && testName != null) {
      final logs = logcatMap[testName] ??
          logcatMap.entries
              .where((e) => e.key.contains(testName!))
              .map((e) => e.value)
              .firstOrNull;
      results.add(_buildResult(
        name:     testName,
        suite:    suite,
        apiLevel: apiLevel,
        status:   status,
        trace:    trace.toString(),
        start:    start,
        logs:     logs,
      ));
      testName = null;
    }
  }

  return results;
}

// ── Logcat-only mode ────────────────────────────────────────────────────────

/// Derives complete Allure results from a device logcat file alone — no
/// instrumentation output file required.
///
/// Robust to incomplete captures: when the Dart test runner's `00:00 +N:`
/// boundary marker is absent (e.g. `adb logcat -c` wasn't run before the
/// test), all `🃏` lines are still collected and the test name is inferred
/// from the final `🃏 PASS | GP-XXX … PASSED` line.
List<Map<String, dynamic>> _parseLogcatOnly(
  String path,
  String suite,
  String apiLevel,
) {
  final logsMap   = _parseLogcat(path);
  final statusMap = _deriveTestStatuses(path);

  // ── Fallback: boundary marker was missing ─────────────────────────────
  // When the logcat was captured without clearing first, the `00:00 +N:`
  // line is not present, so _parseLogcat returns an empty map even though
  // the 🃏 lines exist. Collect them into a fallback entry keyed by the
  // test name extracted from the final PASS message.
  if (logsMap.isEmpty) {
    final fallback = _parseLogcatFallback(path);
    if (fallback != null) {
      logsMap[fallback.key] = fallback.value;
      stderr.writeln(
        'INFO: test boundary marker missing — inferred test name '
        '"${fallback.key}" from 🃏 PASS line. Fix: use run_test.sh which '
        'runs `adb logcat -c` before every test.',
      );
    } else {
      stderr.writeln('WARNING: No 🃏 log lines found in $path');
    }
  }

  final results = <Map<String, dynamic>>[];
  for (final entry in logsMap.entries) {
    final fullName = entry.key;
    final logs     = entry.value;

    final shortName = _formatTestName(fullName);

    // Our own 🃏 VIOLATION / PASS markers are explicit, semantic signals
    // written by the test itself — they always outrank the numeric +N/-M
    // pass-fail counter parsed by _deriveTestStatuses, which is fragile:
    // Patrol's "[E]" error-recap line doesn't always carry a matching "-M"
    // delta, so a genuinely-failing (violation-logged) run can otherwise be
    // misreported as "passed". Only fall back to the counter (then to
    // 'broken', e.g. a watchdog-killed run with no clean resolution either
    // way) when the test logged neither a violation nor an explicit pass.
    final hasViolation = logs.steps.any((s) => s.type == 'violation');
    final hasExplicitPass = logs.steps.any((s) =>
        s.type == 'pass' &&
        (s.message.contains('PASSED') || s.message.contains('passed')));
    final status = hasViolation
        ? 'failed'
        : hasExplicitPass
            ? 'passed'
            : statusMap[fullName] ?? 'broken';

    final startMs = logs.startMs ?? DateTime.now().millisecondsSinceEpoch;
    final stopMs  = logs.stopMs  ?? DateTime.now().millisecondsSinceEpoch;

    results.add(_buildResult(
      name:     shortName,
      suite:    suite,
      apiLevel: apiLevel,
      status:   status,
      trace:    '',
      start:    startMs,
      stop:     stopMs,
      logs:     logs,
    ));
  }
  return results;
}

/// Fallback parser used when no `00:00 +N:` boundary marker is present.
/// Scans all Flutter log lines and infers the test name from the final
/// `🃏 PASS | GP-XXX … PASSED` message.
/// Returns a `MapEntry(testName, _TestLogs)` or null if nothing useful found.
MapEntry<String, _TestLogs>? _parseLogcatFallback(String path) {
  final logs = _TestLogs();
  String? inferredName;

  for (final line in File(path).readAsLinesSync()) {
    final msg = _flutterMessage(line);
    if (msg == null) continue;

    final tsMs = _logcatLineMs(line);

    if (msg.startsWith('🃏 PARAM | ')) {
      final rest = msg.substring('🃏 PARAM | '.length);
      final sep  = rest.indexOf(' :: ');
      if (sep >= 0) {
        logs.params.add(_LogParam(rest.substring(0, sep).trim(), rest.substring(sep + 4).trim()));
      }
    } else if (msg.startsWith('🃏 STEP | ')) {
      logs.steps.add(_LogStep('step', msg.substring('🃏 STEP | '.length)));
    } else if (msg.startsWith('🃏 PASS | ')) {
      final text = msg.substring('🃏 PASS | '.length);
      logs.steps.add(_LogStep('pass', text));
      // Infer full name: "GP-DROP-002 points-2p PASSED — ..." so converter formats it.
      final passMatch = RegExp(r'^(GP-[A-Z]+-\d{3}\s+\S+\s+.+?)\s+PASSED').firstMatch(text);
      if (passMatch != null) inferredName = passMatch.group(1)?.trim();
    } else if (msg.startsWith('🃏 VIOLATION | ')) {
      logs.steps.add(_LogStep('violation', msg.substring('🃏 VIOLATION | '.length)));
    } else if (msg.startsWith('🃏 SCREENSHOT | ')) {
      final rest = msg.substring('🃏 SCREENSHOT | '.length);
      final sep  = rest.indexOf(' :: ');
      if (sep >= 0) {
        logs.screenshots.add(_LogShot(
          rest.substring(0, sep).trim(),
          rest.substring(sep + 4).trim(),
        ));
      }
    } else {
      continue;
    }
    if (tsMs != null) { logs.startMs ??= tsMs; logs.stopMs = tsMs; }
  }

  if (logs.steps.isEmpty && logs.params.isEmpty) return null;
  return MapEntry(inferredName ?? 'unknown-test', logs);
}

/// Parses Dart test runner lines to produce a map from full test name
/// → `'passed'` or `'failed'`. Uses the `+N -M:` counter format:
/// - A test passes when the `+N` counter increments in the next runner line.
/// - A test fails when the `-M` counter is non-zero for that test.
/// - `All tests passed!` at the end confirms all remaining tests passed.
Map<String, String> _deriveTestStatuses(String path) {
  final statuses = <String, String>{};
  String? prev;
  int prevFails = 0;

  for (final line in File(path).readAsLinesSync()) {
    final msg = _flutterMessage(line);
    if (msg == null) continue;

    final m = RegExp(r'^\d{2}:\d{2} \+(\d+)(?:\s*-(\d+))?:\s+(.+)$').firstMatch(msg);
    if (m == null) continue;

    final fails = int.tryParse(m.group(2) ?? '') ?? 0;
    final label = m.group(3)?.trim() ?? '';

    if (label == 'patrol_test_explorer') { prev = null; prevFails = 0; continue; }
    if (label.startsWith('All tests passed')) {
      if (prev != null) statuses[prev] = 'passed';
      break;
    }

    if (prev != null) {
      statuses[prev] = fails > prevFails ? 'failed' : 'passed';
    }
    prev = label;
    prevFails = fails;
  }
  return statuses;
}

/// Formats test name to include config badge: extracts the group path prefix,
/// extracts GP-ID and config (e.g. "points-2p"), then reconstructs as:
///   GP-DECL-003 [2P Points] — Valid declaration chip-gain verification
String _formatTestName(String fullName) {
  final spaceIdx = fullName.indexOf(' ');
  if (spaceIdx < 0) return fullName;

  final prefix = fullName.substring(0, spaceIdx);
  final rest   = fullName.substring(spaceIdx + 1);

  // Prefix is all lowercase dots-and-underscores → it's the Dart group path.
  // Strip it to get the human-readable test description.
  final testDesc = RegExp(r'^[a-z0-9_.]+$').hasMatch(prefix) ? rest : fullName;

  // Extract GP-ID and config from testDesc.
  // Pattern: "GP-XXX-NNN points-2p description..."
  final match = RegExp(r'^(GP-[A-Z]+-\d{3})\s+(points-2p|points-6p|deals-2p)\s+(.*)$')
      .firstMatch(testDesc);

  if (match == null) return testDesc; // fallback if pattern doesn't match

  final gpId = match.group(1) ?? 'GP-???';
  final config = match.group(2) ?? 'unknown';
  final desc = match.group(3) ?? '';

  // Convert config to badge: points-2p → 2P Points, points-6p → 6P Points, etc.
  final badge = _configBadge(config);

  // Reconstruct: GP-DECL-003 [2P Points] — Valid declaration...
  return '$gpId [$badge] — $desc';
}

/// Converts config string to a human-readable badge.
String _configBadge(String config) {
  return switch(config) {
    'points-2p' => '2P Points',
    'points-6p' => '6P Points',
    'deals-2p'  => '2P Deals',
    _ => config,
  };
}

// ── Allure result builder ───────────────────────────────────────────────────

Map<String, dynamic> _buildResult({
  required String name,
  required String suite,
  required String apiLevel,
  required String status,
  required String trace,
  required int    start,
  int?            stop,
  _TestLogs?      logs,
}) {
  final result = <String, dynamic>{
    'uuid':   _uuid(),
    'name':   name,
    'status': status,
    'labels': [
      {'name': 'suite',   'value': suite},
      {'name': 'feature', 'value': suite},
      {'name': 'tag',     'value': 'android-api-$apiLevel'},
    ],
    'start': start,
    'stop':  stop ?? DateTime.now().millisecondsSinceEpoch,
  };

  if (status == 'failed' || status == 'broken') {
    result['statusDetails'] = {
      'message': 'Test $status on Android API $apiLevel',
      'trace':   trace,
    };
  }

  if (logs != null) {
    // Parameters — named metrics surfaced in the Allure "Parameters" tab.
    if (logs.params.isNotEmpty) {
      result['parameters'] = logs.params
          .map((p) => {'name': p.key, 'value': p.value})
          .toList();
    }

    // Steps — the 🃏 STEP / PASS / VIOLATION log lines become drill-down
    // steps in the Allure "Execution" tab.
    if (logs.steps.isNotEmpty) {
      result['steps'] = logs.steps.map((s) {
        return <String, dynamic>{
          'name':   s.message,
          'status': s.type == 'violation' ? 'failed' : 'passed',
          'start':  start,
          'stop':   start,
          'steps':  <dynamic>[],
        };
      }).toList();
    }

    // Attachments — 🃏 SCREENSHOT lines become image attachments in the
    // Allure "Attachments" tab. The PNG file must be present in the same
    // allure-results directory (pulled from the device by run_test.sh).
    if (logs.screenshots.isNotEmpty) {
      result['attachments'] = logs.screenshots.map((s) {
        // Patrol saves as <name>.png; fall back to <name>_*.png match below.
        final filename = '${s.name}.png';
        return <String, dynamic>{
          'name':   s.label,
          'source': filename,
          'type':   'image/png',
        };
      }).toList();
    }
  }

  return result;
}

// ── Logcat parsing ──────────────────────────────────────────────────────────

class _LogParam  { _LogParam(this.key, this.value); final String key, value; }
class _LogStep   { _LogStep(this.type, this.message); final String type, message; }
class _LogShot   { _LogShot(this.label, this.name); final String label, name; }
class _TestLogs  {
  final params      = <_LogParam>[];
  final steps       = <_LogStep>[];
  final screenshots = <_LogShot>[];
  int?  startMs; // wall-clock ms of first 🃏 line for this test
  int?  stopMs;  // wall-clock ms of last  🃏 line for this test
}

/// Parses a logcat file for `🃏` lines and returns a map from
/// **full Dart test name** (as printed by the Dart test runner, e.g.
/// `integration_test.suites.gameplay.first_drop_test GP-DROP-001 …`)
/// to the steps and parameters collected during that test.
///
/// Test boundaries are detected by the pattern:
///   `I flutter : 00:00 +N: FULL_TEST_NAME`
/// which the Dart test runner prints at the start of each test.
Map<String, _TestLogs> _parseLogcat(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('WARNING: Logcat file not found: $path — skipping enrichment');
    return {};
  }

  final map         = <String, _TestLogs>{};
  _TestLogs? current;
  bool       done = false; // true once "All tests passed!" seen — post-summary lines ignored

  for (final line in file.readAsLinesSync()) {
    final msg = _flutterMessage(line);
    if (msg == null) continue;

    // Detect test-start marker emitted by the Dart test runner.
    // Matches "00:00 +N: FULL_TEST_NAME" (also "00:00 +N ~M: ..." variants).
    final testMatch = RegExp(r'^\d{2}:\d{2} \+\d+(?:\s*~\d+)?:\s+(.+)$')
        .firstMatch(msg);
    if (testMatch != null) {
      var fullName = testMatch.group(1)?.trim() ?? '';
      if (fullName == 'patrol_test_explorer') continue;
      if (fullName.startsWith('All tests passed') ||
          fullName.startsWith('Some tests failed')) {
        done = true; // Patrol prints test-name recap lines AFTER this — ignore them
        continue;
      }
      if (done) continue; // post-summary recap line, not a real test start
      // Dart's test runner appends " [E]" to a test's own name when it
      // reprints the line as an error recap at completion — that's the SAME
      // test finishing, not a new one starting. Strip the suffix so this
      // doesn't spawn a second, empty map entry alongside the real one that
      // already collected this test's 🃏 steps.
      if (fullName.endsWith(' [E]')) {
        fullName = fullName.substring(0, fullName.length - 4);
      }
      current = map.putIfAbsent(fullName, _TestLogs.new);
      continue;
    }

    if (current == null) continue;

    // Extract the wall-clock timestamp from the logcat line prefix
    // (format: "MM-DD HH:MM:SS.mmm") for accurate Allure start/stop times.
    final tsMs = _logcatLineMs(line);

    if (msg.startsWith('🃏 PARAM | ')) {
      final rest = msg.substring('🃏 PARAM | '.length);
      final sep  = rest.indexOf(' :: ');
      if (sep >= 0) {
        current.params.add(_LogParam(
          rest.substring(0, sep).trim(),
          rest.substring(sep + 4).trim(),
        ));
      }
    } else if (msg.startsWith('🃏 STEP | ')) {
      current.steps.add(_LogStep('step', msg.substring('🃏 STEP | '.length)));
    } else if (msg.startsWith('🃏 PASS | ')) {
      current.steps.add(_LogStep('pass', msg.substring('🃏 PASS | '.length)));
    } else if (msg.startsWith('🃏 VIOLATION | ')) {
      current.steps.add(_LogStep('violation', msg.substring('🃏 VIOLATION | '.length)));
    } else if (msg.startsWith('🃏 SCREENSHOT | ')) {
      final rest = msg.substring('🃏 SCREENSHOT | '.length);
      final sep  = rest.indexOf(' :: ');
      if (sep >= 0) {
        current.screenshots.add(_LogShot(
          rest.substring(0, sep).trim(),
          rest.substring(sep + 4).trim(),
        ));
      }
    } else {
      continue; // not a 🃏 line — skip timestamp update
    }
    if (tsMs != null) {
      current.startMs ??= tsMs;
      current.stopMs   = tsMs;
    }
  }
  return map;
}

/// Parses the wall-clock milliseconds from a logcat line timestamp.
/// Logcat format: `MM-DD HH:MM:SS.mmm PID TID TAG: ...`
/// Returns null when the format doesn't match.
int? _logcatLineMs(String line) {
  final m = RegExp(r'^(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})\.(\d{3})').firstMatch(line);
  if (m == null) return null;
  final now = DateTime.now();
  return DateTime(
    now.year,
    int.parse(m.group(1)!),  // month
    int.parse(m.group(2)!),  // day
    int.parse(m.group(3)!),  // hour
    int.parse(m.group(4)!),  // minute
    int.parse(m.group(5)!),  // second
    int.parse(m.group(6)!),  // millisecond
  ).millisecondsSinceEpoch;
}

/// Extracts the message payload from a logcat line, or returns null if the
/// line isn't a Flutter log line.
///
/// Logcat format: `MM-DD HH:MM:SS.mmm PID TID I flutter : MESSAGE`
String? _flutterMessage(String line) {
  const tag = 'I flutter :';
  final idx = line.indexOf(tag);
  if (idx < 0) return null;
  return line.substring(idx + tag.length).trim();
}

// ── Allure categories ───────────────────────────────────────────────────────

void _writeCategoriesJson(String outputDir) {
  final categories = [
    {
      'name': 'Authentication Failures',
      'matchedStatuses': ['failed'],
      'traceRegex': '.*loginPage.*|.*otpPage.*|.*signupPage.*',
    },
    {
      'name': 'Lobby / Profile Failures',
      'matchedStatuses': ['failed'],
      'traceRegex': '.*profilePage.*|.*lobbyPage.*|.*walletPage.*',
    },
    {
      'name': 'Gameplay / Table Failures',
      'matchedStatuses': ['failed'],
      'traceRegex': '.*tablePage.*|.*FlameGameBridge.*|.*declarationPage.*',
    },
    {
      'name': 'Infrastructure Flakes',
      'matchedStatuses': ['broken'],
      'traceRegex': '.*TimeoutException.*|.*SocketException.*|.*WebSocketChannelException.*',
    },
  ];

  File('$outputDir/categories.json').writeAsStringSync(jsonEncode(categories));
}

// ── Utilities ───────────────────────────────────────────────────────────────

String _uuid() {
  final rng   = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6]    = (bytes[6] & 0x0f) | 0x40;
  bytes[8]    = (bytes[8] & 0x3f) | 0x80;
  final hex   = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
