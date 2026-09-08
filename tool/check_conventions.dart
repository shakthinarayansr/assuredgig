// Convention checks that the analyzer cannot express, run in CI.
//
//   1. No hardcoded user-facing strings (TRD §11).
//   2. Layer dependencies point downward only (TRD §4).
//
// Run: dart run tool/check_conventions.dart
//
// Both checks are deliberately syntactic. They will not catch every violation,
// and they are not meant to — they catch the ones that happen by accident,
// which is nearly all of them. Escape a genuine false positive with a trailing
// `// i18n-ignore` comment on the offending line.

import 'dart:io';

const String _ignoreMarker = 'i18n-ignore';

/// Widget parameters whose value is read aloud by, or shown to, a Partner.
const List<String> _userFacingParams = <String>[
  'label',
  'labelText',
  'hintText',
  'helperText',
  'errorText',
  'tooltip',
  'semanticsLabel',
  'title',
  'subtitle',
  'message',
];

/// What each layer is allowed to import. The direction is
/// presentation → domain → data → sources, with `core` available to all and
/// `app` as the composition root that is allowed to see everything.
const Map<String, Set<String>> _allowedImports = <String, Set<String>>{
  'presentation': <String>{'presentation', 'domain', 'core', 'l10n', 'app'},
  'domain': <String>{'domain', 'core'},
  'data': <String>{'data', 'domain', 'sources', 'core'},
  'sources': <String>{'sources', 'core'},
  'core': <String>{'core'},
  'app': <String>{
    'app',
    'presentation',
    'domain',
    'data',
    'sources',
    'core',
    'l10n',
  },
  'l10n': <String>{'l10n'},
};

void main() {
  final violations = <String>[
    ..._checkHardcodedStrings(),
    ..._checkLayerImports(),
  ];

  if (violations.isEmpty) {
    stdout.writeln('Conventions OK.');
    return;
  }

  stderr.writeln('Convention violations (${violations.length}):\n');
  for (final v in violations) {
    stderr.writeln('  $v');
  }
  stderr.writeln(
    '\nHardcoded strings: move the text to lib/l10n/app_en.arb and read it '
    'via AppL10n.of(context).\n'
    'Layer violations: a layer may only import downward — see TRD §4.',
  );
  exitCode = 1;
}

List<String> _checkHardcodedStrings() {
  final violations = <String>[];
  final textLiteral = RegExp(r'''\bText\(\s*(?:const\s+)?(['"])(.*?)\1''');
  final paramLiteral = RegExp(
    '''\\b(${_userFacingParams.join('|')})\\s*:\\s*(['"])(.*?)\\2''',
  );

  for (final file in _dartFiles()) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains(_ignoreMarker)) continue;

      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;

      for (final match in textLiteral.allMatches(line)) {
        final value = match.group(2)!;
        if (_isTranslatable(value)) {
          violations.add('${_rel(file)}:${i + 1}  hardcoded Text("$value")');
        }
      }
      for (final match in paramLiteral.allMatches(line)) {
        final value = match.group(3)!;
        if (_isTranslatable(value)) {
          violations.add(
            '${_rel(file)}:${i + 1}  hardcoded ${match.group(1)}: "$value"',
          );
        }
      }
    }
  }
  return violations;
}

/// A literal is worth translating only if it contains letters. Punctuation,
/// separators, numbers and format placeholders are locale-independent.
bool _isTranslatable(String value) {
  if (value.trim().isEmpty) return false;
  return RegExp(r'[A-Za-z]{2,}').hasMatch(value);
}

List<String> _checkLayerImports() {
  final violations = <String>[];
  final importLine = RegExp(r'''^\s*import\s+(['"])([^'"]+)\1''');

  for (final file in _dartFiles()) {
    final layer = _layerOf(_rel(file));
    if (layer == null) continue;
    final allowed = _allowedImports[layer];
    if (allowed == null) continue;

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final match = importLine.firstMatch(lines[i]);
      if (match == null) continue;

      final target = _resolveLayer(match.group(2)!, file);
      if (target == null || allowed.contains(target)) continue;

      violations.add('${_rel(file)}:${i + 1}  $layer/ may not import $target/');
    }
  }
  return violations;
}

/// Maps an import URI to the lib/ subdirectory it lands in, or null if it is a
/// package or dart: import that layering does not govern.
String? _resolveLayer(String uri, File from) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:')) {
    const selfPrefix = 'package:assuredgig/';
    if (!uri.startsWith(selfPrefix)) return null;
    return _layerOf('lib/${uri.substring(selfPrefix.length)}');
  }
  // Uri.directory, not Uri.file: the latter treats the final segment as a
  // filename and resolves relative imports one directory too high.
  final resolved = File(
    Uri.directory(from.parent.absolute.path).resolve(uri).toFilePath(),
  ).absolute.path;
  final root = Directory.current.absolute.path;
  if (!resolved.startsWith(root)) return null;
  return _layerOf(resolved.substring(root.length + 1));
}

String? _layerOf(String relativePath) {
  final parts = relativePath.split(Platform.pathSeparator).join('/').split('/');
  if (parts.length < 2 || parts.first != 'lib') return null;
  return parts[1];
}

Iterable<File> _dartFiles() sync* {
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('No lib/ directory — run from the project root.');
    exit(2);
  }
  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final name = entity.uri.pathSegments.last;
    // Generated code is not ours to police.
    if (name.endsWith('.g.dart') ||
        name.endsWith('.freezed.dart') ||
        name.endsWith('.config.dart') ||
        name.startsWith('app_localizations') ||
        name == 'firebase_options.dart') {
      continue;
    }
    yield entity;
  }
}

String _rel(File file) {
  final root = Directory.current.absolute.path;
  final path = file.absolute.path;
  return path.startsWith(root) ? path.substring(root.length + 1) : path;
}
