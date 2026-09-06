import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/retro_pixel_widgets.dart';
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
      loading: () => const Center(
        child: CircularProgressIndicator(color: RetroColors.cyan),
      ),
      error: (error, stackTrace) => _LoadFailure(
        onRetry: () => ref.invalidate(progressionControllerProvider),
      ),
      data: (state) => _ProgressionContent(state: state),
    );
  }
}

class _ProgressionContent extends ConsumerStatefulWidget {
  const _ProgressionContent({required this.state});

  final ProgressionViewState state;

  @override
  ConsumerState<_ProgressionContent> createState() =>
      _ProgressionContentState();
}

class _ProgressionContentState extends ConsumerState<_ProgressionContent> {
  bool? _summaryExpanded;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isCompactHeight = media.height < 520;
    final isMobileWidth = media.width < 600;
    final showFullSummary = _summaryExpanded ?? !isCompactHeight;

    final snapshot = widget.state.snapshot;
    final controller = ref.read(progressionControllerProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobileWidth ? 12 : 20,
              isCompactHeight ? 8 : 16,
              isMobileWidth ? 12 : 20,
              isCompactHeight ? 4 : 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTopRow(
                  context,
                  snapshot,
                  controller,
                  isCompactHeight,
                  isMobileWidth,
                  showFullSummary,
                ),
                SizedBox(height: isCompactHeight ? 6 : 10),
                if (showFullSummary)
                  _ProgressSummary(
                    snapshot: snapshot,
                    isCompactHeight: isCompactHeight,
                  )
                else
                  _buildCompactBadgesRow(snapshot, isCompact: isCompactHeight),
                if (!snapshot.storeUnlocked) ...[
                  SizedBox(height: isCompactHeight ? 4 : 6),
                  _MessageBanner(
                    icon: Icons.lock_outline,
                    message:
                        'Puedes explorar todo el catálogo. Para comprar, completa los 10 niveles con este personaje.',
                    isCompact: isCompactHeight,
                  ),
                ],
                if (widget.state.noticeMessage != null) ...[
                  SizedBox(height: isCompactHeight ? 4 : 6),
                  _MessageBanner(
                    icon: Icons.check_circle_outline,
                    message: widget.state.noticeMessage!,
                    success: true,
                    isCompact: isCompactHeight,
                  ),
                ],
                if (widget.state.errorMessage != null) ...[
                  SizedBox(height: isCompactHeight ? 4 : 6),
                  _MessageBanner(
                    icon: Icons.warning_amber_outlined,
                    message: widget.state.errorMessage!,
                    isCompact: isCompactHeight,
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF070D16),
              border: Border(
                top: BorderSide(color: Color(0xFF1E354F), width: 1.5),
                bottom: BorderSide(color: Color(0xFF1E354F), width: 1.5),
              ),
            ),
            child: TabBar(
              indicatorColor: RetroColors.cyan,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: RetroColors.cyan,
              unselectedLabelColor: RetroColors.textMuted,
              labelStyle: GoogleFonts.pressStart2p(
                fontSize: isCompactHeight ? 8 : 10,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: GoogleFonts.pressStart2p(
                fontSize: isCompactHeight ? 8 : 10,
              ),
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.trending_up,
                    size: isCompactHeight ? 15 : 20,
                  ),
                  text: 'Mejoras',
                  height: isCompactHeight ? 36 : 48,
                ),
                Tab(
                  icon: Icon(
                    Icons.auto_awesome,
                    size: isCompactHeight ? 15 : 20,
                  ),
                  text: 'Habilidades',
                  height: isCompactHeight ? 36 : 48,
                ),
                Tab(
                  icon: Icon(
                    Icons.palette_outlined,
                    size: isCompactHeight ? 15 : 20,
                  ),
                  text: 'Paletas',
                  height: isCompactHeight ? 36 : 48,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _StatsTab(
                  state: widget.state,
                  isCompactHeight: isCompactHeight,
                ),
                _SkillsTab(
                  state: widget.state,
                  isCompactHeight: isCompactHeight,
                ),
                _PalettesTab(
                  state: widget.state,
                  isCompactHeight: isCompactHeight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRow(
    BuildContext context,
    ProgressionSnapshot snapshot,
    ProgressionController controller,
    bool isCompactHeight,
    bool isMobileWidth,
    bool showFullSummary,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Progresión del personaje',
            style: GoogleFonts.pressStart2p(
              fontSize: isCompactHeight ? 11 : 14,
              fontWeight: FontWeight.bold,
              color: RetroColors.cyan,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: isMobileWidth ? 180 : 220,
              child: DropdownButtonFormField<CharacterId>(
                key: ValueKey(snapshot.characterId),
                initialValue: snapshot.characterId,
                dropdownColor: const Color(0xFF0C1420),
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  labelText: 'Personaje',
                  labelStyle: GoogleFonts.pressStart2p(
                    fontSize: 9,
                    color: RetroColors.cyan,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0C1420),
                  isDense: isCompactHeight,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF1E354F),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: RetroColors.cyan,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: isCompactHeight ? 8 : 12,
                  ),
                ),
                items: [
                  for (final character in CharacterId.values)
                    DropdownMenuItem(
                      value: character,
                      child: Text(
                        character.definition.displayName,
                        style: GoogleFonts.pressStart2p(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
                onChanged: widget.state.isBusy
                    ? null
                    : (value) {
                        if (value != null) {
                          controller.selectCharacter(value);
                        }
                      },
              ),
            ),
            if (isCompactHeight) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: showFullSummary ? 'Ocultar detalles' : 'Ver detalles',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0C1420),
                  side: const BorderSide(
                    color: Color(0xFF1E354F),
                    width: 1.5,
                  ),
                ),
                icon: Icon(
                  showFullSummary
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: RetroColors.cyan,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _summaryExpanded = !showFullSummary;
                  });
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCompactBadgesRow(
    ProgressionSnapshot snapshot, {
    bool isCompact = false,
  }) {
    return Wrap(
      spacing: isCompact ? 6 : 8,
      runSpacing: isCompact ? 4 : 6,
      children: [
        _SummaryChip(
          icon: Icons.workspace_premium_outlined,
          pixelIconAsset: PixelIconAsset.trophy,
          label: 'Maestría ${snapshot.masteryLevel}/30',
          color: RetroColors.gold,
          isCompact: isCompact,
        ),
        _SummaryChip(
          icon: Icons.savings_outlined,
          pixelIconAsset: PixelIconAsset.coin,
          label: '${_coins(snapshot.bankedCurrency)} guardadas',
          color: RetroColors.goldLight,
          isCompact: isCompact,
        ),
        _SummaryChip(
          icon: Icons.warning_amber_outlined,
          label: '${_coins(snapshot.temporaryCurrency)} en riesgo',
          color: RetroColors.magenta,
          isCompact: isCompact,
        ),
        _SummaryChip(
          icon: Icons.balance_outlined,
          label: 'Estándar normalizado',
          color: RetroColors.cyan,
          isCompact: isCompact,
        ),
      ],
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.snapshot,
    required this.isCompactHeight,
  });

  final ProgressionSnapshot snapshot;
  final bool isCompactHeight;

  @override
  Widget build(BuildContext context) {
    return RetroArcadeCard(
      borderColor: const Color(0xFF1E354F),
      padding: EdgeInsets.all(isCompactHeight ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _SummaryChip(
                icon: Icons.workspace_premium_outlined,
                pixelIconAsset: PixelIconAsset.trophy,
                label: 'Maestría ${snapshot.masteryLevel}/30',
                color: RetroColors.gold,
              ),
              _SummaryChip(
                icon: Icons.savings_outlined,
                pixelIconAsset: PixelIconAsset.coin,
                label: '${_coins(snapshot.bankedCurrency)} guardadas',
                color: RetroColors.goldLight,
              ),
              _SummaryChip(
                icon: Icons.warning_amber_outlined,
                label: '${_coins(snapshot.temporaryCurrency)} en riesgo',
                color: RetroColors.magenta,
              ),
              const _SummaryChip(
                icon: Icons.balance_outlined,
                label: 'Estándar normalizado',
                color: RetroColors.cyan,
              ),
            ],
          ),
          SizedBox(height: isCompactHeight ? 6 : 12),
          Semantics(
            label:
                'Progreso de maestría, nivel ${snapshot.masteryLevel} de 30',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: snapshot.masteryProgress,
                minHeight: isCompactHeight ? 6 : 8,
                backgroundColor: const Color(0xFF132032),
                color: RetroColors.cyan,
              ),
            ),
          ),
          SizedBox(height: isCompactHeight ? 6 : 8),
          Text(
            snapshot.masteryLevel >= 30
                ? 'Maestría máxima alcanzada.'
                : '${_coins(snapshot.masteryXp)} / ${_coins(snapshot.nextLevelXp)} XP para el siguiente nivel.',
            style: GoogleFonts.vt323(
              fontSize: isCompactHeight ? 15 : 17,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isCompactHeight ? 4 : 6),
          Text(
            'Las mejoras y skills funcionan sólo en Progresión y Boss Rush. Las paletas son visuales y no cambian hitboxes.',
            style: GoogleFonts.vt323(
              fontSize: isCompactHeight ? 13 : 15,
              color: RetroColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab({
    required this.state,
    required this.isCompactHeight,
  });

  final ProgressionViewState state;
  final bool isCompactHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = state.snapshot;
    final controller = ref.read(progressionControllerProvider.notifier);
    return RefreshIndicator(
      color: RetroColors.cyan,
      backgroundColor: const Color(0xFF0C1420),
      onRefresh: controller.refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isCompactHeight ? 12 : 20),
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RetroArcadeCard(
              borderColor: stat.isCapped
                  ? RetroColors.green.withValues(alpha: 0.5)
                  : const Color(0xFF1E354F),
              accentHeaderColor: stat.isCapped
                  ? RetroColors.green
                  : (canBuy ? RetroColors.cyan : null),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stat.displayName,
                          style: GoogleFonts.pressStart2p(
                            fontSize: isCompactHeight ? 11 : 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      RetroBadge(
                        text: 'Rango ${stat.rank}/${stat.maxRank}',
                        color: stat.isCapped
                            ? RetroColors.green
                            : RetroColors.gold,
                        fontSize: 8,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stat.description,
                    style: GoogleFonts.vt323(
                      fontSize: 16,
                      color: RetroColors.textBright,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: stat.rank / stat.maxRank,
                      minHeight: 6,
                      backgroundColor: const Color(0xFF132032),
                      color: RetroColors.cyan,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, cardConstraints) {
                      final isWideCard = cardConstraints.maxWidth > 380;
                      final effectDetails = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Efecto actual: +${_percent(stat.effectiveBasisPoints)}',
                            style: GoogleFonts.vt323(
                              fontSize: isCompactHeight ? 15 : 16,
                              color: RetroColors.cyan,
                            ),
                          ),
                          if (!stat.isCapped) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Siguiente: ${stat.nextBonusLives > 0 ? '+1 vida y ' : ''}+${_percent(stat.nextBonusBasisPoints ?? 0)} · Maestría ${stat.nextUnlockLevel} · ${_coins(stat.nextCost ?? 0)} monedas',
                              style: GoogleFonts.vt323(
                                fontSize: isCompactHeight ? 14 : 15,
                                color: RetroColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      );

                      final buyButton = FilledButton.icon(
                        onPressed: canBuy
                            ? () => controller.purchaseUpgrade(stat)
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: Size(
                            isCompactHeight ? 120 : 130,
                            isCompactHeight ? 40 : 46,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompactHeight ? 12 : 16,
                            vertical: isCompactHeight ? 8 : 12,
                          ),
                          backgroundColor: RetroColors.cyan,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFF132032),
                          disabledForegroundColor: RetroColors.textMuted,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                            side: BorderSide(
                              color: Color(0xFF1E354F),
                              width: 1.5,
                            ),
                          ),
                        ),
                        icon: busy
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Icon(
                                stat.isCapped ? Icons.check : Icons.add,
                                size: isCompactHeight ? 16 : 18,
                              ),
                        label: Text(
                          _statActionLabel(snapshot, stat),
                          style: GoogleFonts.pressStart2p(
                            fontSize: isCompactHeight ? 8 : 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );

                      if (isWideCard) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: effectDetails),
                            const SizedBox(width: 12),
                            buyButton,
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          effectDetails,
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: buyButton,
                          ),
                        ],
                      );
                    },
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
  const _SkillsTab({
    required this.state,
    required this.isCompactHeight,
  });

  final ProgressionViewState state;
  final bool isCompactHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = state.snapshot;
    final controller = ref.read(progressionControllerProvider.notifier);
    final definition = snapshot.characterId.definition;
    return RefreshIndicator(
      color: RetroColors.cyan,
      backgroundColor: const Color(0xFF0C1420),
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isCompactHeight ? 12 : 20),
        children: [
          RetroArcadeCard(
            borderColor: const Color(0xFF1E354F),
            accentHeaderColor: RetroColors.cyan,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: RetroColors.cyan.withValues(alpha: 0.12),
                    border: Border.all(color: RetroColors.cyan, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    color: RetroColors.cyan,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identidad innata',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${definition.description}\nLas habilidades originales nunca se venden ni ocupan un slot pasivo.',
                        style: GoogleFonts.vt323(
                          fontSize: 16,
                          color: RetroColors.textBright,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                definition.defaultActive == null
                    ? const RetroBadge(
                        text: 'Sin activa inicial',
                        color: RetroColors.textMuted,
                        fontSize: 8,
                      )
                    : FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(110, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                            side: BorderSide(
                              color: Color(0xFF1E354F),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onPressed: state.isBusy ||
                                snapshot.authorizedBuild.activeSkillId == null
                            ? null
                            : () => controller.equipActive(null),
                        child: Text(
                          'Usar predeterminada',
                          style: GoogleFonts.vt323(fontSize: 15),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const _MessageBanner(
            icon: Icons.info_outline,
            message:
                'Hay un slot activo y dos pasivos. Al comprar ambos pasivos no existe una tercera opción excluida en V6.',
          ),
          const SizedBox(height: 10),
          for (final skill in snapshot.skills)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SkillCard(state: state, skill: skill),
            ),
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
    final isCompactHeight = MediaQuery.sizeOf(context).height < 520;

    return RetroArcadeCard(
      borderColor: selected ? RetroColors.cyan : const Color(0xFF1E354F),
      accentHeaderColor: selected ? RetroColors.cyan : null,
      padding: EdgeInsets.all(isCompactHeight ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  skill.displayName,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              RetroBadge(
                text: skill.slot.label,
                color: RetroColors.cyan,
                fontSize: 8,
              ),
              const SizedBox(width: 8),
              RetroBadge(
                text: skill.owned ? 'Propia' : 'Por desbloquear',
                color: skill.owned ? RetroColors.green : RetroColors.gold,
                fontSize: 8,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            skill.description,
            style: GoogleFonts.vt323(
              fontSize: 16,
              color: RetroColors.textBright,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            skill.uiExplanation,
            style: GoogleFonts.vt323(
              fontSize: 15,
              color: RetroColors.cyan,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, cardConstraints) {
              final isWideCard = cardConstraints.maxWidth > 380;
              final requirementText = Text(
                'Maestría ${skill.unlockLevel} · ${_coins(skill.cost)} monedas · Progresión/Boss Rush',
                style: GoogleFonts.vt323(
                  fontSize: isCompactHeight ? 13 : 14,
                  color: RetroColors.textMuted,
                ),
              );

              final actionButton = skill.owned
                  ? FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        minimumSize: Size(
                          isCompactHeight ? 110 : 120,
                          isCompactHeight ? 40 : 46,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompactHeight ? 12 : 16,
                          vertical: isCompactHeight ? 8 : 12,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(
                            color: Color(0xFF1E354F),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onPressed: canEquip
                          ? () => skill.slot == SkillSlot.active
                              ? controller.equipActive(skill.id)
                              : controller.togglePassive(skill.id)
                          : null,
                      icon: busy
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              selected ? Icons.remove_circle : Icons.check,
                              size: isCompactHeight ? 16 : 18,
                            ),
                      label: Text(
                        selected
                            ? skill.slot == SkillSlot.active
                                ? 'Equipada'
                                : 'Retirar'
                            : 'Equipar',
                        style: GoogleFonts.pressStart2p(
                          fontSize: isCompactHeight ? 8 : 9,
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: Size(
                          isCompactHeight ? 120 : 130,
                          isCompactHeight ? 40 : 46,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompactHeight ? 12 : 16,
                          vertical: isCompactHeight ? 8 : 12,
                        ),
                        backgroundColor: RetroColors.cyan,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: const Color(0xFF132032),
                        disabledForegroundColor: RetroColors.textMuted,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(
                            color: Color(0xFF1E354F),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onPressed: canPurchase
                          ? () => controller.purchaseSkill(skill)
                          : null,
                      icon: busy
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Icon(
                              Icons.shopping_bag_outlined,
                              size: isCompactHeight ? 16 : 18,
                            ),
                      label: Text(
                        _skillActionLabel(snapshot, skill),
                        style: GoogleFonts.pressStart2p(
                          fontSize: isCompactHeight ? 8 : 9,
                        ),
                      ),
                    );

              if (isWideCard) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: requirementText),
                    const SizedBox(width: 12),
                    actionButton,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  requirementText,
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: actionButton,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PalettesTab extends ConsumerWidget {
  const _PalettesTab({
    required this.state,
    required this.isCompactHeight,
  });

  final ProgressionViewState state;
  final bool isCompactHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = state.snapshot;
    final controller = ref.read(progressionControllerProvider.notifier);
    return RefreshIndicator(
      color: RetroColors.cyan,
      backgroundColor: const Color(0xFF0C1420),
      onRefresh: controller.refresh,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isCompactHeight ? 12 : 20),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 340,
          mainAxisExtent: isCompactHeight ? 280 : 320,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
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

          return RetroArcadeCard(
            borderColor: palette.equipped
                ? RetroColors.cyan
                : const Color(0xFF1E354F),
            accentHeaderColor: palette.equipped ? RetroColors.cyan : null,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: palette.transform.colorFilter ??
                          const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          ),
                      child: Image.asset(
                        'assets/images/${snapshot.characterId.definition.assetName}',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        semanticLabel:
                            '${snapshot.characterId.definition.displayName}, paleta ${palette.displayName}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        palette.displayName,
                        style: GoogleFonts.pressStart2p(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (palette.equipped)
                      const RetroBadge(
                        text: 'Equipada',
                        color: RetroColors.cyan,
                        fontSize: 8,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  palette.cost == 0
                      ? 'Paleta original incluida.'
                      : 'Maestría ${palette.unlockLevel} · ${_coins(palette.cost)} monedas',
                  style: GoogleFonts.vt323(
                    fontSize: 15,
                    color: RetroColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: palette.owned
                        ? (palette.equipped
                            ? const Color(0xFF132032)
                            : const Color(0xFF1E354F))
                        : RetroColors.cyan,
                    foregroundColor: palette.owned ? Colors.white : Colors.black,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(
                        color: Color(0xFF1E354F),
                        width: 1.5,
                      ),
                    ),
                  ),
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
                          size: 18,
                        ),
                  label: Text(
                    _paletteActionLabel(snapshot, palette),
                    style: GoogleFonts.pressStart2p(fontSize: 9),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    this.color = RetroColors.cyan,
    this.pixelIconAsset,
    this.isCompact = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String? pixelIconAsset;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1420),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7 : 10,
        vertical: isCompact ? 4 : 7,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pixelIconAsset != null)
            PixelIconAsset(assetName: pixelIconAsset!, size: isCompact ? 13 : 16)
          else
            Icon(icon, size: isCompact ? 13 : 16, color: color),
          SizedBox(width: isCompact ? 5 : 8),
          Text(
            label,
            style: GoogleFonts.vt323(
              fontSize: isCompact ? 14 : 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.icon,
    required this.message,
    this.success = false,
    this.isCompact = false,
  });

  final IconData icon;
  final String message;
  final bool success;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final borderColor = success ? RetroColors.green : RetroColors.gold;
    return Semantics(
      liveRegion: true,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C1420),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 4 : 8,
        ),
        child: Row(
          children: [
            Icon(icon, color: borderColor, size: isCompact ? 14 : 18),
            SizedBox(width: isCompact ? 6 : 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.vt323(
                  fontSize: isCompact ? 14 : 16,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
          ],
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
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: RetroColors.magenta,
            ),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar la progresión.',
              style: GoogleFonts.pressStart2p(
                fontSize: 11,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            RetroArcadeButton(
              text: 'Reintentar',
              onPressed: onRetry,
              primaryColor: RetroColors.cyan,
              icon: Icons.refresh,
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
