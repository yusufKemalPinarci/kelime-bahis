import 'dart:convert';
import 'dart:io';

import 'package:kelime_bahis/crew/crew.dart';

/// Runs the local multi-agent crew (no API keys) and writes a report.
Future<void> main(List<String> args) async {
  final crew = buildKelimeBahisCrew();
  final result = await crew.kickoff(
    inputs: {
      'dictionaryPath': 'assets/dictionary/tr_words.txt',
    },
  );

  final outDir = Directory('crew/output');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final report = result.toJson();
  final file = File('crew/output/crew_report.json');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
  );

  // Persist content snapshots produced by ContentAgent.
  final jokers = result.context.get<List<dynamic>>('jokers');
  final bosses = result.context.get<List<dynamic>>('bosses');
  if (jokers != null) {
    await File('assets/content/jokers.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(jokers),
    );
  }
  if (bosses != null) {
    await File('assets/content/bosses.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(bosses),
    );
  }

  stdout.writeln('=== KelimeBahisCrew tamamlandı ===');
  for (final r in result.results) {
    stdout.writeln('[${r.agentRole}] ${r.taskName}: ${r.output}');
  }
  stdout.writeln('Rapor: ${file.path}');
}
