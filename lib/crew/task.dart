import 'agent.dart';

class Task {
  const Task({
    required this.name,
    required this.description,
    required this.expectedOutput,
    required this.agent,
  });

  final String name;
  final String description;
  final String expectedOutput;
  final Agent agent;
}
