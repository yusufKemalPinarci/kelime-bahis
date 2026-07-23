import 'dart:convert';
import 'dart:io';

import 'package:kelime_bahis/crew/crew.dart';

Future<void> main() async {
  final crew = buildDebateCrew();
  final result = await crew.kickoff();

  final outDir = Directory('crew/output');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final file = File('crew/output/debate_decisions.json');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(result.toJson()),
  );

  stdout.writeln('=== Tartışma turu ===');
  for (final r in result.results) {
    stdout.writeln('[${r.agentRole}] ${r.output}');
  }
  stdout.writeln('\nONAYLANAN:');
  final decisions = result.context.get<List<dynamic>>('decisions') ?? [];
  for (final d in decisions) {
    stdout.writeln('- ${d['id']}: ${d['title']} (skor ${d['score']})');
  }
  stdout.writeln('\nRapor: ${file.path}');
}
