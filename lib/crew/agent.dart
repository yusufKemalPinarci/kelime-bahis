import 'context.dart';

typedef AgentExecutor = Future<String> Function(CrewContext context);

/// Role-based worker — mirrors CrewAI Agent without remote LLMs.
class Agent {
  const Agent({
    required this.role,
    required this.goal,
    required this.backstory,
    required this.execute,
  });

  final String role;
  final String goal;
  final String backstory;
  final AgentExecutor execute;

  Map<String, String> describe() => {
        'role': role,
        'goal': goal,
        'backstory': backstory,
      };
}
