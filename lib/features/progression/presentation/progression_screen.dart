import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/domain/character_definition.dart';
import '../../../game/domain/character_id.dart';
import '../application/progression_controller.dart';
import '../domain/progression_models.dart';

class ProgressionScreen extends ConsumerWidget {
  const ProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(progressionControllerProvider);
    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _LoadFailure(
        onRetry: () => ref.invalidate(progressionControllerProvider),
      ),
      data: (state) => _ProgressionContent(state: state),
    );
  }
}

class _ProgressionContent extends ConsumerWidget {
  const _ProgressionContent({required this.state});

  final ProgressionViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = state.snapshot;
    final controller = ref.read(progressionControllerProvider.notifier);
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 20,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Progresión del personaje',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<CharacterId>(
                        key: ValueKey(snapshot.characterId),
                        initialValue: snapshot.characterId,
                        decoration: const InputDecoration(
                          labelText: 'Personaje',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final character in CharacterId.values)
                            DropdownMenuItem(
                              value: character,
                              child: Text(character.definition.displayName),
                            ),
                        ],
                        onChanged: state.isBusy
                            ? null
                            : (value) {
                                if (value != null) {
                                  controller.selectCharacter(value);
                                }
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ProgressSummary(snapshot: snapshot),
                if (!snapshot.storeUnlocked) ...[
                  const SizedBox(height: 12),
                  const _MessageBanner(
                    icon: Icons.lock_outline,
                    message:
                        'Puedes explorar todo el catálogo. Para comprar, completa los 10 niveles con este personaje.',
                  ),
                ],
                if (state.noticeMessage != null) ...[
                  const SizedBox(height: 12),
                  _MessageBanner(
                    icon: Icons.check_circle_outline,
                    message: state.noticeMessage!,
                    success: true,
                  ),
                ],
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _MessageBanner(
                    icon: Icons.warning_amber_outlined,
                    message: state.errorMessage!,
                  ),
                ],
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.trending_up), text: 'Mejoras'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'Habilidades'),
              Tab(icon: Icon(Icons.palette_outlined), text: 'Paletas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _StatsTab(state: state),
                _SkillsTab(state: state),
                _PalettesTab(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.snapshot});

  final ProgressionSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryChip(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Maestría ${snapshot.masteryLevel}/30',
                ),
                _SummaryChip(
                  icon: Icons.savings_outlined,
                  label: '${_coins(snapshot.bankedCurrency)} guardadas',
                ),
                _SummaryChip(
                  icon: Icons.warning_amber_outlined,
                  label: '${_coins(snapshot.temporaryCurrency)} en riesgo',
                ),
                const _SummaryChip(
                  icon: Icons.balance_outlined,
                  label: 'Estándar normalizado',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label:
                  'Progreso de maestría, nivel ${snapshot.masteryLevel} de 30',
              child: LinearProgressIndicator(value: snapshot.masteryProgress),
            ),
            const SizedBox(height: 8),
            Text(
              snapshot.masteryLevel >= 30
                  ? 'Maestría máxima alcanzada.'
                  : '${_coins(snapshot.masteryXp)} / ${_coins(snapshot.nextLevelXp)} XP para el siguiente nivel.',
            ),
            const SizedBox(height: 8),
            Text(
              'Las mejoras y skills funcionan sólo en Progresión y Boss Rush. Las paletas son visuales y no cambian hitboxes.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab({required this.state});

  final ProgressionViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = state.snapshot;
    final controller = ref.read(progressionControllerProvider.notifier);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        itemCount: snapshot.stats.length,
        itemBuilder: (context, index) {
          final stat = snapshot.stats[index];
          final masteryReady =
              snapshot.masteryLevel >= (stat.nextUnlockLevel ?? 0);
          final balanceReady = snapshot.bankedCurrency >= (stat.nextCost ?? 0);
          final canBuy =
              !state.isBusy &&
              snapshot.storeUnlocked &&
              !stat.isCapped &&
              masteryReady &&
              balanceReady;
          final busy = state.busyAction == 'stat:${stat.id}';
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stat.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Chip(label: Text('Rango ${stat.rank}/${stat.maxRank}')),
                    ],
                  ),
                  Text(stat.description),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: stat.rank / stat.maxRank),
                  const SizedBox(height: 10),
                  Text(
                    'Efecto actual: +${_percent(stat.effectiveBasisPoints)}',
                  ),
                  if (!stat.isCapped) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Siguiente: ${stat.nextBonusLives > 0 ? '+1 vida y ' : ''}+${_percent(stat.nextBonusBasisPoints ?? 0)} · Maestría ${stat.nextUnlockLevel} · ${_coins(stat.nextCost ?? 0)} monedas',
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: canBuy
                          ? () => controller.purchaseUpgrade(stat)
                          : null,
                      icon: busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(stat.isCapped ? Icons.check : Icons.add),
                      label: Text(_statActionLabel(snapshot, stat)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SkillsTab extends ConsumerWidget {
  const _SkillsTab({required this.state});

  final ProgressionViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = state.snapshot;
    final controller = ref.read(progressionControllerProvider.notifier);
    final definition = snapshot.characterId.definition;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Identidad innata'),
              subtitle: Text(
                '${definition.description}\nLas habilidades originales nunca se venden ni ocupan un slot pasivo.',
              ),
              trailing: definition.defaultActive == null
                  ? const Chip(label: Text('Sin activa inicial'))
                  : FilledButton.tonal(
                      onPressed:
                          state.isBusy ||
                              snapshot.authorizedBuild.activeSkillId == null
                          ? null
                          : () => controller.equipActive(null),
                      child: const Text('Usar predeterminada'),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          const _MessageBanner(
            icon: Icons.info_outline,
            message:
                'Hay un slot activo y dos pasivos. Al comprar ambos pasivos no existe una tercera opción excluida en V6.',
          ),
          const SizedBox(height: 8),
          for (final skill in snapshot.skills)
            _SkillCard(state: state, skill: skill),
        ],
      ),
    );
  }
}

class _SkillCard extends ConsumerWidget {
  const _SkillCard({required this.state, required this.skill});

  final ProgressionViewState state;
  final ProgressionSkill skill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = state.snapshot;
    final controller = ref.read(progressionControllerProvider.notifier);
    final selected = skill.slot == SkillSlot.active
        ? snapshot.authorizedBuild.activeSkillId == skill.id
        : snapshot.authorizedBuild.passiveSkillIds.contains(skill.id);
    final masteryReady = snapshot.masteryLevel >= skill.unlockLevel;
    final balanceReady = snapshot.bankedCurrency >= skill.cost;
    final canPurchase =
        !state.isBusy &&
        snapshot.storeUnlocked &&
        !skill.owned &&
        masteryReady &&
        balanceReady;
    final canEquip = !state.isBusy && skill.owned;
    final busy = state.busyAction?.contains(skill.id) == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    skill.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text(skill.slot.label)),
                const SizedBox(width: 8),
                Chip(label: Text(skill.owned ? 'Propia' : 'Por desbloquear')),
              ],
            ),
            Text(skill.description),
            const SizedBox(height: 6),
            Text(skill.uiExplanation),
            const SizedBox(height: 8),
            Text(
              'Maestría ${skill.unlockLevel} · ${_coins(skill.cost)} monedas · Progresión/Boss Rush',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: skill.owned
                  ? FilledButton.tonalIcon(
                      onPressed: canEquip
                          ? () => skill.slot == SkillSlot.active
                                ? controller.equipActive(skill.id)
                                : controller.togglePassive(skill.id)
                          : null,
                      icon: busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(selected ? Icons.remove_circle : Icons.check),
                      label: Text(
                        selected
                            ? skill.slot == SkillSlot.active
                                  ? 'Equipada'
                                  : 'Retirar'
                            : 'Equipar',
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: canPurchase
                          ? () => controller.purchaseSkill(skill)
                          : null,
                      icon: busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.shopping_bag_outlined),
                      label: Text(_skillActionLabel(snapshot, skill)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PalettesTab extends ConsumerWidget {
  const _PalettesTab({required this.state});

  final ProgressionViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = state.snapshot;
    final controller = ref.read(progressionControllerProvider.notifier);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 360,
          mainAxisExtent: 390,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: snapshot.palettes.length,
        itemBuilder: (context, index) {
          final palette = snapshot.palettes[index];
          final masteryReady = snapshot.masteryLevel >= palette.unlockLevel;
          final balanceReady = snapshot.bankedCurrency >= palette.cost;
          final canPurchase =
              !state.isBusy &&
              snapshot.storeUnlocked &&
              !palette.owned &&
              masteryReady &&
              balanceReady;
          final busy = state.busyAction?.contains(palette.id) == true;
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: ColorFiltered(
                        colorFilter:
                            palette.transform.colorFilter ??
                            const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ),
                        child: Image.asset(
                          'assets/images/${snapshot.characterId.definition.assetName}',
                          fit: BoxFit.contain,
                          semanticLabel:
                              '${snapshot.characterId.definition.displayName}, paleta ${palette.displayName}',
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          palette.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (palette.equipped) const Chip(label: Text('Equipada')),
                    ],
                  ),
                  Text(
                    palette.cost == 0
                        ? 'Paleta original incluida.'
                        : 'Maestría ${palette.unlockLevel} · ${_coins(palette.cost)} monedas',
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: palette.owned
                        ? state.isBusy || palette.equipped
                              ? null
                              : () => controller.equipPalette(palette.id)
                        : canPurchase
                        ? () => controller.purchasePalette(palette)
                        : null,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            palette.owned
                                ? Icons.palette_outlined
                                : Icons.shopping_bag_outlined,
                          ),
                    label: Text(_paletteActionLabel(snapshot, palette)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.icon,
    required this.message,
    this.success = false,
  });

  final IconData icon;
  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: success ? scheme.primaryContainer : scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56),
            const SizedBox(height: 12),
            const Text('No se pudo cargar la progresión.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _statActionLabel(ProgressionSnapshot snapshot, ProgressionStat stat) {
  if (stat.isCapped) return 'Máximo';
  if (!snapshot.storeUnlocked) return 'Requiere clear';
  if (snapshot.masteryLevel < (stat.nextUnlockLevel ?? 0)) {
    return 'Maestría ${stat.nextUnlockLevel}';
  }
  if (snapshot.bankedCurrency < (stat.nextCost ?? 0)) {
    return 'Faltan ${_coins((stat.nextCost ?? 0) - snapshot.bankedCurrency)}';
  }
  return 'Comprar por ${_coins(stat.nextCost ?? 0)}';
}

String _skillActionLabel(ProgressionSnapshot snapshot, ProgressionSkill skill) {
  if (!snapshot.storeUnlocked) return 'Requiere clear';
  if (snapshot.masteryLevel < skill.unlockLevel) {
    return 'Maestría ${skill.unlockLevel}';
  }
  if (snapshot.bankedCurrency < skill.cost) {
    return 'Faltan ${_coins(skill.cost - snapshot.bankedCurrency)}';
  }
  return 'Comprar por ${_coins(skill.cost)}';
}

String _paletteActionLabel(
  ProgressionSnapshot snapshot,
  PaletteVariant palette,
) {
  if (palette.equipped) return 'Equipada';
  if (palette.owned) return 'Equipar';
  if (!snapshot.storeUnlocked) return 'Requiere clear';
  if (snapshot.masteryLevel < palette.unlockLevel) {
    return 'Maestría ${palette.unlockLevel}';
  }
  if (snapshot.bankedCurrency < palette.cost) {
    return 'Faltan ${_coins(palette.cost - snapshot.bankedCurrency)}';
  }
  return 'Comprar por ${_coins(palette.cost)}';
}

String _percent(int basisPoints) {
  final value = basisPoints / 100;
  return value == value.roundToDouble()
      ? '${value.toInt()}%'
      : '${value.toStringAsFixed(1)}%';
}

String _coins(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(' ');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
