import 'agents/balance_agent.dart';
import 'agents/content_agent.dart';
import 'agents/debate_agents.dart';
import 'agents/designer_agent.dart';
import 'agents/dictionary_agent.dart';
import 'crew_runtime.dart';
import 'pipeline.dart';
import 'task.dart';

/// Prefabricated sequential crew for Kelime Bahis content pipeline (aşama 1–4).
Crew buildKelimeBahisCrew() {
  final designer = createDesignerAgent();
  final dictionary = createDictionaryAgent();
  final balance = createBalanceAgent();
  final content = createContentAgent();

  final designStage = contentCrewStages[0];
  final dictStage = contentCrewStages[1];
  final balanceStage = contentCrewStages[2];
  final contentStage = contentCrewStages[3];

  return Crew(
    name: 'KelimeBahisCrew',
    agents: [designer, dictionary, balance, content],
    tasks: [
      Task(
        name: designStage.taskName,
        description:
            '[aşama ${designStage.order}:${designStage.stage.name}] ${designStage.goal}',
        expectedOutput: designStage.produces,
        agent: designer,
        stage: designStage.stage,
      ),
      Task(
        name: dictStage.taskName,
        description:
            '[aşama ${dictStage.order}:${dictStage.stage.name}] ${dictStage.goal}',
        expectedOutput: dictStage.produces,
        agent: dictionary,
        stage: dictStage.stage,
      ),
      Task(
        name: balanceStage.taskName,
        description:
            '[aşama ${balanceStage.order}:${balanceStage.stage.name}] ${balanceStage.goal}',
        expectedOutput: balanceStage.produces,
        agent: balance,
        stage: balanceStage.stage,
      ),
      Task(
        name: contentStage.taskName,
        description:
            '[aşama ${contentStage.order}:${contentStage.stage.name}] ${contentStage.goal}',
        expectedOutput: contentStage.produces,
        agent: content,
        stage: contentStage.stage,
      ),
    ],
  );
}

/// Agents debate improvements, facilitator approves a backlog (aşama 0).
Crew buildDebateCrew() {
  final designer = createDebateDesignerAgent();
  final dictionary = createDebateDictionaryAgent();
  final balance = createDebateBalanceAgent();
  final content = createDebateContentAgent();
  final facilitator = createFacilitatorAgent();

  return Crew(
    name: 'KelimeBahisDebateCrew',
    agents: [designer, dictionary, balance, content, facilitator],
    tasks: [
      Task(
        name: 'designer_pitch',
        description: '[aşama 0:debate] UX/oynanış önerileri',
        expectedOutput: 'debate_designer',
        agent: designer,
        stage: CrewStage.debate,
      ),
      Task(
        name: 'dictionary_pitch',
        description: '[aşama 0:debate] Sözlük/ipucu önerileri',
        expectedOutput: 'debate_dictionary',
        agent: dictionary,
        stage: CrewStage.debate,
      ),
      Task(
        name: 'balance_pitch',
        description: '[aşama 0:debate] Denge/meta önerileri',
        expectedOutput: 'debate_balance',
        agent: balance,
        stage: CrewStage.debate,
      ),
      Task(
        name: 'content_pitch',
        description: '[aşama 0:debate] İçerik önceliği',
        expectedOutput: 'debate_content',
        agent: content,
        stage: CrewStage.debate,
      ),
      Task(
        name: 'facilitate',
        description: '[aşama 0:debate] Oyla ve backlog onayla',
        expectedOutput: 'decisions',
        agent: facilitator,
        stage: CrewStage.debate,
      ),
    ],
  );
}
