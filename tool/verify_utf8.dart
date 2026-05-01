// Strict UTF-8 check for all Dart sources under lib/.
// Run from project root: dart run tool/verify_utf8.dart

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final root = Directory('lib');
  if (!await root.exists()) {
    stderr.writeln('Missing lib/. Run from Vetgo project root.');
    exitCode = 2;
    return;
  }

  final errors = <String>[];

  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final bytes = await entity.readAsBytes();
    try {
      utf8.decode(bytes, allowMalformed: false);
    } on FormatException catch (e) {
      errors.add('${entity.path}: ${e.message}');
    }
  }

  if (errors.isEmpty) {
    stdout.writeln('OK: all lib/**/*.dart files are valid UTF-8.');
    return;
  }

  stderr.writeln('Invalid UTF-8 in ${errors.length} file(s):');
  for (final line in errors) {
    stderr.writeln('  $line');
  }
  exitCode = 1;
}
