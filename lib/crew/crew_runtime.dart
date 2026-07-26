import 'agent.dart';
import 'context.dart';
import 'pipeline.dart';
import 'task.dart';

enum CrewProcess { sequential }

class TaskResult {
  const TaskResult({
    required this.taskName,
    required this.agentRole,
    required this.output,
    this.stage,
  });

  final String taskName;
  final String agentRole;
  final String output;
  final CrewStage? stage;

  Map<String, dynamic> toJson() => {
        'task': taskName,
        'agent': agentRole,
        'output': output,
        if (stage != null) 'stage': stage!.name,
      };
}

class CrewResult {
  const CrewResult({
    required this.results,
    required this.context,
  });

  final List<TaskResult> results;
  final CrewContext context;

  Map<String, dynamic> toJson() => {
        'results': results.map((r) => r.toJson()).toList(),
        'context': context.toJson(),
      };
}

/// Crew kickoff — sequential collaboration like CrewAI Crews.
class Crew {
  Crew({
    required this.agents,
    required this.tasks,
    this.process = CrewProcess.sequential,
    this.name = 'KelimeBahisCrew',
  });

  final String name;
  final List<Agent> agents;
  final List<Task> tasks;
  final CrewProcess process;

  Future<CrewResult> kickoff({Map<String, dynamic>? inputs}) async {
    final context = CrewContext(seed: inputs);
    final results = <TaskResult>[];

    for (final task in tasks) {
      context.set('current_task', task.name);
      context.set('task_description', task.description);
      if (task.stage != null) {
        context.set('current_stage', task.stage!.name);
      }
      final output = await task.agent.execute(context);
      results.add(
        TaskResult(
          taskName: task.name,
          agentRole: task.agent.role,
          output: output,
          stage: task.stage,
        ),
      );
      context.set('last_output', output);
    }

    return CrewResult(results: results, context: context);
  }
}
