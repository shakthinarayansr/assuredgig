import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards TRD §11.
///
/// A missing Tamil string does not crash — it silently falls back to English,
/// which is exactly the failure a Tamil-first Partner would hit and nobody on
/// the team would notice. So it fails the build instead.
void main() {
  final english = _readArb('lib/l10n/app_en.arb');
  final tamil = _readArb('lib/l10n/app_ta.arb');

  test('every English string has a Tamil translation', () {
    final missing = english.keys.where((k) => !tamil.containsKey(k)).toList()
      ..sort();
    expect(
      missing,
      isEmpty,
      reason: 'Untranslated in app_ta.arb: ${missing.join(', ')}',
    );
  });

  test('Tamil has no strings English does not', () {
    final orphaned = tamil.keys.where((k) => !english.containsKey(k)).toList()
      ..sort();
    expect(
      orphaned,
      isEmpty,
      reason:
          'Stale keys in app_ta.arb, removed from the template: '
          '${orphaned.join(', ')}',
    );
  });

  test('no string is blank in either language', () {
    for (final entry in <String, Map<String, String>>{
      'app_en.arb': english,
      'app_ta.arb': tamil,
    }.entries) {
      final blank = entry.value.entries
          .where((e) => e.value.trim().isEmpty)
          .map((e) => e.key)
          .toList();
      expect(blank, isEmpty, reason: 'Blank values in ${entry.key}: $blank');
    }
  });

  test('every English string carries a description for the translator', () {
    final raw = _readRaw('lib/l10n/app_en.arb');
    final undocumented = english.keys.where((key) {
      final meta = raw['@$key'];
      return meta is! Map || (meta['description'] as String?)?.isEmpty != false;
    }).toList()..sort();
    expect(
      undocumented,
      isEmpty,
      reason:
          'Translating without context produces bad Tamil. Add an '
          '@key description for: ${undocumented.join(', ')}',
    );
  });
}

Map<String, dynamic> _readRaw(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    fail('Missing ARB file: $path (run tests from the project root)');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// Message keys only — drops `@@locale` and the `@key` metadata entries.
Map<String, String> _readArb(String path) {
  final raw = _readRaw(path);
  return <String, String>{
    for (final entry in raw.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}
