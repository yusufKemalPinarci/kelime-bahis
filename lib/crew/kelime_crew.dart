import 'agents/balance_agent.dart';
import 'agents/content_agent.dart';
import 'agents/debate_agents.dart';
import 'agents/designer_agent.dart';
import 'agents/dictionary_agent.dart';
import 'crew_runtime.dart';
import 'task.dart';

/// Prefabricated sequential crew for Kelime Bahis content pipeline.
Crew buildKelimeBahisCrew() {
  final designer = createDesignerAgent();
  final dictionary = createDictionaryAgent();
  final balance = createBalanceAgent();
  final content = createContentAgent();

  return Crew(
    name: 'KelimeBahisCrew',
    agents: [designer, dictionary, balance, content],
    tasks: [
      Task(
        name: 'design_loop',
        description: 'Temel oyun döngüsü parametrelerini belirle',
        expectedOutput: 'design map in context',
        agent: designer,
      ),
      Task(
        name: 'prepare_dictionary',
        description: 'Türkçe sözlüğü filtrele ve say',
        expectedOutput: 'wordCount + sample',
        agent: dictionary,
      ),
      Task(
        name: 'balance_economy',
        description: 'Harf puanı ve seviye hedeflerini hesapla',
        expectedOutput: 'letterPoints + levelTargets',
        agent: balance,
      ),
      Task(
        name: 'generate_content',
        description: 'Joker ve boss içeriklerini üret',
        expectedOutput: 'jokers + bosses lists',
        agent: content,
      ),
    ],
  );
}

/// Agents debate improvements, facilitator approves a backlog.
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
        description: 'UX/oynanış önerileri',
        expectedOutput: 'debate_designer',
        agent: designer,
      ),
      Task(
        name: 'dictionary_pitch',
        description: 'Sözlük/ipucu önerileri',
        expectedOutput: 'debate_dictionary',
        agent: dictionary,
      ),
      Task(
        name: 'balance_pitch',
        description: 'Denge/meta önerileri',
        expectedOutput: 'debate_balance',
        agent: balance,
      ),
      Task(
        name: 'content_pitch',
        description: 'İçerik önceliği',
        expectedOutput: 'debate_content',
        agent: content,
      ),
      Task(
        name: 'facilitate',
        description: 'Oyla ve backlog onayla',
        expectedOutput: 'decisions',
        agent: facilitator,
      ),
    ],
  );
}
