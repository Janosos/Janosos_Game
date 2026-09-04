import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../game/domain/character_definition.dart';
import '../../../game/domain/character_id.dart';
import '../../leaderboard/application/leaderboard_controller.dart';
import '../domain/campaign_content.dart';
import '../domain/campaign_repository.dart';

class CampaignScreen extends ConsumerStatefulWidget {
  const CampaignScreen({super.key});

  @override
  ConsumerState<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends ConsumerState<CampaignScreen> {
  CharacterId _selectedCharacter = CharacterId.jano;
  String? _syncMessage;
  late Future<CampaignProgress?> _progress;
  late Future<bool> _bossRushUnlocked;

  @override
  void initState() {
    super.initState();
    _progress = _loadProgress();
    _bossRushUnlocked = _loadBossRushEntitlement(_selectedCharacter);
    Future<void>.microtask(_synchronizePending);
  }

  Future<CampaignProgress?> _loadProgress() =>
      ref.read(campaignRepositoryProvider).loadActiveCampaign();

  Future<bool> _loadBossRushEntitlement(CharacterId character) async {
    final environment = ref.read(appEnvironmentProvider);
    final snapshot = await ref
        .read(progressionRepositoryProvider)
        .loadSnapshot(
          characterId: character,
          contentVersion: environment.contentVersion,
        );
    return snapshot.storeUnlocked;
  }

  Future<void> _synchronizePending() async {
    try {
      final campaignCount = await ref
          .read(campaignResultCoordinatorProvider)
          .synchronizePending();
      final bossRushCount = await ref
          .read(bossRushCoordinatorProvider)
          .synchronizePending();
      final count = campaignCount + bossRushCount;
      if (!mounted || count == 0) return;
      ref.invalidate(leaderboardControllerProvider);
      setState(() {
        _syncMessage = count == 1
            ? 'Se sincronizó 1 resultado pendiente.'
            : 'Se sincronizaron $count resultados pendientes.';
        _progress = _loadProgress();
        _bossRushUnlocked = _loadBossRushEntitlement(_selectedCharacter);
      });
    } on Object {
      // Offline or unavailable protected storage is an expected practice state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CampaignProgress?>(
      future: _progress,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildMap(context, snapshot.data);
      },
    );
  }

  Widget _buildMap(BuildContext context, CampaignProgress? progress) {
    final selectedCharacter = progress?.characterId ?? _selectedCharacter;
    final currentLevel = progress?.currentLevel ?? 1;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Progresión mundial',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Supera diez niveles consecutivos. Si agotas todas las vidas, '
                  'regresas al nivel 1 y pierdes la moneda temporal; tus compras '
                  'y recompensas permanentes se conservan.',
                ),
                const SizedBox(height: 16),
                _CampaignNotice(progress: progress),
                const SizedBox(height: 12),
                FutureBuilder<bool>(
                  future: _bossRushUnlocked,
                  builder: (context, entitlement) => _BossRushCard(
                    unlocked: entitlement.data ?? false,
                    hasActiveCampaign: progress != null,
                    selectedCharacter: selectedCharacter,
                  ),
                ),
                if (_syncMessage != null) ...[
                  const SizedBox(height: 12),
                  Semantics(liveRegion: true, child: Text(_syncMessage!)),
                ],
                const SizedBox(height: 18),
                Semantics(
                  label: 'Personaje seleccionado para la campaña',
                  child: DropdownButtonFormField<CharacterId>(
                    initialValue: selectedCharacter,
                    decoration: const InputDecoration(
                      labelText: 'Personaje de la campaña',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final character in CharacterId.values)
                        DropdownMenuItem(
                          value: character,
                          child: Text(character.definition.displayName),
                        ),
                    ],
                    onChanged: progress == null
                        ? (character) {
                            if (character != null) {
                              setState(() {
                                _selectedCharacter = character;
                                _bossRushUnlocked = _loadBossRushEntitlement(
                                  character,
                                );
                              });
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 430,
              mainAxisExtent: 330,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: initialCampaignLevels.length,
            itemBuilder: (context, index) {
              final level = initialCampaignLevels[index];
              return _LevelCard(
                level: level,
                available: level.level == currentLevel,
                completed: level.level < currentLevel,
                selectedCharacter: selectedCharacter,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BossRushCard extends StatelessWidget {
  const _BossRushCard({
    required this.unlocked,
    required this.hasActiveCampaign,
    required this.selectedCharacter,
  });

  final bool unlocked;
  final bool hasActiveCampaign;
  final CharacterId selectedCharacter;

  @override
  Widget build(BuildContext context) {
    final description = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_fire_department_outlined),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            'Boss Rush encadena los diez jefes, recupera una vida entre '
            'combates y usa un ranking separado. No concede moneda de campaña. '
            '${hasActiveCampaign
                ? 'Termina primero la campaña activa.'
                : unlocked
                ? 'Modo desbloqueado para este personaje.'
                : 'Requiere haber completado la campaña.'}',
          ),
        ),
      ],
    );
    final button = FilledButton.tonalIcon(
      onPressed: unlocked && !hasActiveCampaign
          ? () => context.go(
              '/game?experience=boss_rush&character=${selectedCharacter.serialized}',
            )
          : null,
      icon: const Icon(Icons.whatshot_outlined),
      label: const Text('BOSS RUSH'),
    );
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [description, const SizedBox(height: 14), button],
              );
            }
            return Row(
              children: [
                Expanded(child: description),
                const SizedBox(width: 16),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CampaignNotice extends StatelessWidget {
  const _CampaignNotice({required this.progress});

  final CampaignProgress? progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(progress == null ? Icons.flag_outlined : Icons.route_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                progress == null
                    ? 'Comienza en el nivel 1. Cada victoria desbloquea la '
                          'siguiente etapa para este personaje.'
                    : 'Campaña activa · nivel ${progress!.currentLevel}/10 · '
                          '${progress!.temporaryCurrency} monedas en riesgo. '
                          'El personaje queda fijado hasta completar o perder.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.available,
    required this.completed,
    required this.selectedCharacter,
  });

  final CampaignLevelDefinition level;
  final bool available;
  final bool completed;
  final CharacterId selectedCharacter;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text('${level.level}')),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    level.scenario,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Icon(
                  completed
                      ? Icons.check_circle_outline
                      : available
                      ? Icons.lock_open_outlined
                      : Icons.lock_outline,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('JEFE', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(level.boss, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(level.mechanic),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.auto_awesome_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('${level.uniqueReward} · 1%')),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: available
                    ? () => context.go(
                        '/game?experience=campaign&character=${selectedCharacter.serialized}&level=${level.level}',
                      )
                    : null,
                icon: Icon(available ? Icons.play_arrow : Icons.construction),
                label: Text(
                  completed
                      ? 'COMPLETADO'
                      : available
                      ? 'JUGAR NIVEL ${level.level}'
                      : 'BLOQUEADO',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
