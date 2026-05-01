// Verifica que todos los `.dart` bajo `lib/` decodifiquen como UTF-8 estricto.
// Uso (desde la raíz del proyecto): dart run tool/verify_utf8.dart

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final root = Directory('lib');
  if (!await root.exists()) {
    stderr.writeln('No existe la carpeta lib/. Ejecuta desde la raíz de Vetgo.');
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
    stdout.writeln('OK: todos los archivos lib/**/*.dart son UTF-8 válidos.');
    return;
  }

  stderr.writeln('UTF-8 inválido en ${errors.length} archivo(s):');
  for (final line in errors) {
    stderr.writeln('  $line');
  }
  exitCode = 1;
}
