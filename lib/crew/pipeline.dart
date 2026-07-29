/// Uygulama geliştirme / içerik üretimi aşama sırası.
/// Her aşamada yalnızca listedeki agent çalışır; çıktı bir sonraki aşamaya geçer.
enum CrewStage {
  /// Öncelik tartışması — özellik backlog'u
  debate,

  /// Mekanik ve seviye parametreleri
  design,

  /// Türkçe sözlük filtre / doğrulama
  dictionary,

  /// Harf puanı, hedef skor, ekonomi
  balance,

  /// Joker + boss JSON ve metinler
  content,

  /// lib/game motoruna bağlama (skor, torba, controller)
  engine,

  /// lib/views ekran ve widget'lar
  ui,
}

class StageSpec {
  const StageSpec({
    required this.stage,
    required this.order,
    required this.agentRole,
    required this.taskName,
    required this.goal,
    required this.ownsPaths,
    required this.produces,
    this.script,
  });

  final CrewStage stage;
  final int order;
  final String agentRole;
  final String taskName;
  final String goal;
  final List<String> ownsPaths;
  final String produces;
  final String? script;
}

/// Sabit pipeline — Cursor ve `run_crew` / `run_debate` aynı sırayı kullanır.
const kAppPipeline = <StageSpec>[
  StageSpec(
    stage: CrewStage.debate,
    order: 0,
    agentRole: 'Facilitator (+ Designer, Sözlük, Denge, İçerik)',
    taskName: 'facilitate',
    goal: 'Özellik önerilerini oyla; onaylı backlog üret',
    ownsPaths: ['crew/output/debate_decisions.json', 'lib/crew/agents/debate_agents.dart'],
    produces: 'approved feature id listesi',
    script: 'dart run scripts/run_debate.dart',
  ),
  StageSpec(
    stage: CrewStage.design,
    order: 1,
    agentRole: 'Oyun Tasarımcısı',
    taskName: 'design_loop',
    goal: 'El boyutu, tur/atım hakkı, seviye ritmi, mağaza seçim sayısı',
    ownsPaths: [
      'lib/crew/agents/designer_agent.dart',
      'lib/game/game_controller.dart',
      'lib/views/screens/home_screen.dart',
    ],
    produces: 'design map (handSize, maxHands, targets baz)',
  ),
  StageSpec(
    stage: CrewStage.dictionary,
    order: 2,
    agentRole: 'Sözlük Uzmanı',
    taskName: 'prepare_dictionary',
    goal: 'tr_words filtrele; 2–8 harf; yalnızca TR harfler; offline doğrulama',
    ownsPaths: [
      'assets/dictionary/',
      'lib/game/word_dictionary.dart',
      'lib/game/turkish.dart',
      'lib/crew/agents/dictionary_agent.dart',
    ],
    produces: 'wordCount + geçerli kelime kümesi',
  ),
  StageSpec(
    stage: CrewStage.balance,
    order: 3,
    agentRole: 'Denge Mühendisi',
    taskName: 'balance_economy',
    goal: 'Harf puanları, seviye hedefleri, joker çarpan üst sınırları',
    ownsPaths: [
      'lib/game/scoring.dart',
      'lib/game/letter_bag.dart',
      'lib/crew/agents/balance_agent.dart',
    ],
    produces: 'letterPoints + levelTargets',
  ),
  StageSpec(
    stage: CrewStage.content,
    order: 4,
    agentRole: 'İçerik Üreticisi',
    taskName: 'generate_content',
    goal: 'Joker/boss JSON, Türkçe isim ve kısıt metinleri',
    ownsPaths: [
      'assets/content/',
      'lib/crew/agents/content_agent.dart',
    ],
    produces: 'jokers.json + bosses.json',
  ),
  StageSpec(
    stage: CrewStage.engine,
    order: 5,
    agentRole: 'Oyun Tasarımcısı + Denge Mühendisi',
    taskName: 'wire_engine',
    goal: 'design/balance/content çıktısını GameController ve skor motoruna bağla',
    ownsPaths: [
      'lib/game/',
      'lib/models/',
    ],
    produces: 'çalışan offline oyun döngüsü',
  ),
  StageSpec(
    stage: CrewStage.ui,
    order: 6,
    agentRole: 'İçerik Üreticisi + Oyun Tasarımcısı',
    taskName: 'polish_ui',
    goal: 'Material 3 ekranlar; tek CTA; hedef/skor okunabilirliği',
    ownsPaths: [
      'lib/views/',
      'lib/main.dart',
    ],
    produces: 'home + game ekranları',
  ),
];

/// İçerik crew'unun sıralı görevleri (debate/engine/ui hariç).
List<StageSpec> get contentCrewStages => kAppPipeline
    .where(
      (s) =>
          s.stage == CrewStage.design ||
          s.stage == CrewStage.dictionary ||
          s.stage == CrewStage.balance ||
          s.stage == CrewStage.content,
    )
    .toList();

Map<String, dynamic> pipelineToJson() => {
      'process': 'sequential',
      'stages': kAppPipeline
          .map(
            (s) => {
              'order': s.order,
              'stage': s.stage.name,
              'agent': s.agentRole,
              'task': s.taskName,
              'goal': s.goal,
              'owns': s.ownsPaths,
              'produces': s.produces,
              if (s.script != null) 'script': s.script,
            },
          )
          .toList(),
    };
