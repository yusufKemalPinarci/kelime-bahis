import 'agent.dart';
import 'pipeline.dart';

class Task {
  const Task({
    required this.name,
    required this.description,
    required this.expectedOutput,
    required this.agent,
    this.stage,
  });

  final String name;
  final String description;
  final String expectedOutput;
  final Agent agent;

  /// Pipeline aşaması — hangi sırada bu task çalışır.
  final CrewStage? stage;
}
