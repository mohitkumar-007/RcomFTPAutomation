import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Seeds a pre-configured test account via REST before test execution.
/// Ensures the account always starts in a known state (chips, username, etc.).
///
/// Usage: dart run tool/seed_test_account.dart
void main() async {
  final baseUrl  = Platform.environment['BASE_URL']   ?? 'https://qa.rummy.internal';
  final phone    = Platform.environment['TEST_PHONE'] ?? '+919000000001';
  final apiKey   = Platform.environment['SEED_API_KEY'];

  if (apiKey == null) {
    stderr.writeln('ERROR: SEED_API_KEY env var is required');
    exit(1);
  }

  final client = http.Client();
  try {
    stdout.writeln('Seeding test account for $phone ...');

    final response = await client.post(
      Uri.parse('$baseUrl/internal/test/seed-account'),
      headers: {
        'Content-Type': 'application/json',
        'X-Internal-Api-Key': apiKey,
      },
      body: jsonEncode({
        'phone':    phone,
        'chips':    5000,
        'username': 'AutoTestUser',
        'resetKyc': true,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      stdout.writeln('Account seeded successfully.');
    } else {
      stderr.writeln('Seed failed: ${response.statusCode} — ${response.body}');
      exit(1);
    }
  } finally {
    client.close();
  }
}
