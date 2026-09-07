import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/character_sprite_preview.dart';
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
      data: (state) => _LandscapeProgressionView(state: state),
    );
  }
}

enum _StoreCategory { stats, skills, palettes }

class _LandscapeProgressionView extends ConsumerStatefulWidget {
  const _LandscapeProgressionView({required this.state});

  final ProgressionViewState state;

  @override
  ConsumerState<_LandscapeProgressionView> createState() =>
      _LandscapeProgressionViewState();
}

class _LandscapeProgressionViewState
    extends ConsumerState<_LandscapeProgressionView> {
  _StoreCategory _selectedCategory = _StoreCategory.stats;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isLandscape = media.width > media.height || media.width >= 600;
    final isCompactHeight = media.height < 500;
    final snapshot = widget.state.snapshot;
    final controller = ref.read(progressionControllerProvider.notifier);

    if (!isLandscape) {
      return _buildPortraitLayout(
        context,
        snapshot,
        controller,
        isCompactHeight,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070D16),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PANEL LATERAL IZQUIERDO: HUD, Personaje, Billetera y Categorías
          Container(
            width: isCompactHeight ? 230 : 260,
            decoration: const BoxDecoration(
              color: Color(0xFF090F18),
              border: Border(
                right: BorderSide(color: Color(0xFF1E354F), width: 1.5),
              ),
            ),
            child: SafeArea(
              right: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isCompactHeight ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selector de Personaje
                    _CharacterSelector(
                      selectedId: snapshot.characterId,
                      onChanged: (id) => controller.selectCharacter(id),
                      isCompact: isCompactHeight,
                    ),
                    SizedBox(height: isCompactHeight ? 6 : 10),

                    // Billetera Arcade (Monedas guardadas)
                    _WalletCard(
                      bankedCurrency: snapshot.bankedCurrency,
                      masteryLevel: snapshot.masteryLevel,
                      masteryXp: snapshot.masteryXp,
                      nextLevelXp: snapshot.nextLevelXp,
                      isCompact: isCompactHeight,
                    ),
                    SizedBox(height: isCompactHeight ? 6 : 8),

                    // Estado de Tienda (Abierta / Bloqueada)
                    _StoreStatusBadge(
                      isUnlocked: snapshot.storeUnlocked,
                      isCompact: isCompactHeight,
                    ),
                    SizedBox(height: isCompactHeight ? 8 : 12),

                    // Selector de Categoría (Pestañas laterales)
                    _CategoryButton(
                      title: 'MEJORAS',
                      subtitle: 'Vidas y atributos',
                      icon: Icons.trending_up,
                      isSelected: _selectedCategory == _StoreCategory.stats,
                      color: RetroColors.cyan,
                      isCompact: isCompactHeight,
                      onTap: () => setState(
                        () => _selectedCategory = _StoreCategory.stats,
                      ),
                    ),
                    SizedBox(height: isCompactHeight ? 5 : 8),
                    _CategoryButton(
                      title: 'HABILIDADES',
                      subtitle: 'Activas y pasivas',
                      icon: Icons.auto_awesome,
                      isSelected: _selectedCategory == _StoreCategory.skills,
                      color: RetroColors.magenta,
                      isCompact: isCompactHeight,
                      onTap: () => setState(
                        () => _selectedCategory = _StoreCategory.skills,
                      ),
                    ),
                    SizedBox(height: isCompactHeight ? 5 : 8),
                    _CategoryButton(
                      title: 'PALETAS',
                      subtitle: 'Aspectos retro',
                      icon: Icons.palette_outlined,
                      isSelected: _selectedCategory == _StoreCategory.palettes,
                      color: RetroColors.gold,
                      isCompact: isCompactHeight,
                      onTap: () => setState(
                        () => _selectedCategory = _StoreCategory.palettes,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // PANEL PRINCIPAL DERECHO: Catálogo scrollable espacioso
          Expanded(
            child: SafeArea(
              left: false,
              child: Column(
                children: [
                  // Notificación temporal (si existe)
                  if (widget.state.noticeMessage != null ||
                      widget.state.errorMessage != null)
                    _StoreNoticeBar(
                      message: widget.state.noticeMessage ??
                          widget.state.errorMessage!,
                      isError: widget.state.errorMessage != null,
                    ),

                  // Contenido de la categoría seleccionada
                  Expanded(
                    child: switch (_selectedCategory) {
                      _StoreCategory.stats => _StatsCatalog(
                        state: widget.state,
                        isCompactHeight: isCompactHeight,
                      ),
                      _StoreCategory.skills => _SkillsCatalog(
                        state: widget.state,
                        isCompactHeight: isCompactHeight,
                      ),
                      _StoreCategory.palettes => _PalettesCatalog(
                        state: widget.state,
                        isCompactHeight: isCompactHeight,
                      ),
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    ProgressionSnapshot snapshot,
    ProgressionController controller,
    bool isCompactHeight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: _CharacterSelector(
                  selectedId: snapshot.characterId,
                  onChanged: (id) => controller.selectCharacter(id),
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1B2B),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: RetroColors.gold, width: 1.5),
                ),
                child: Row(
                  children: [
                    const PixelIconAsset(
                      assetName: PixelIconAsset.coin,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _coins(snapshot.bankedCurrency),
                      style: GoogleFonts.pressStart2p(
                        fontSize: 10,
                        color: RetroColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Barra de pestañas horizontal
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final cat in _StoreCategory.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedCategory == cat
                              ? const Color(0xFF1E354F)
                              : const Color(0xFF0C1420),
                          border: Border.all(
                            color: _selectedCategory == cat
                                ? RetroColors.cyan
                                : const Color(0xFF1E354F),
                          ),
                        ),
                        child: Text(
                          cat == _StoreCategory.stats
                              ? 'MEJORAS'
                              : (cat == _StoreCategory.skills
                                  ? 'SKILLS'
                                  : 'PALETAS'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 8,
                            color: _selectedCategory == cat
                                ? Colors.white
                                : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: switch (_selectedCategory) {
            _StoreCategory.stats => _StatsCatalog(
              state: widget.state,
              isCompactHeight: isCompactHeight,
            ),
            _StoreCategory.skills => _SkillsCatalog(
              state: widget.state,
              isCompactHeight: isCompactHeight,
            ),
            _StoreCategory.palettes => _PalettesCatalog(
              state: widget.state,
              isCompactHeight: isCompactHeight,
            ),
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// COMPONENTES DEL PANEL LATERAL
// ---------------------------------------------------------------------------

class _CharacterSelector extends StatelessWidget {
  const _CharacterSelector({
    required this.selectedId,
    required this.onChanged,
    required this.isCompact,
  });

  final CharacterId selectedId;
  final ValueChanged<CharacterId> onChanged;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1420),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF1E354F), width: 1.5),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 2 : 4,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CharacterId>(
          value: selectedId,
          dropdownColor: const Color(0xFF0F1724),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: RetroColors.cyan),
          items: [
            for (final character in CharacterId.values)
              DropdownMenuItem(
                value: character,
                child: Row(
                  children: [
                    CharacterIcon(
                      assetName: character.definition.assetName,
                      size: isCompact ? 22 : 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        character.definition.displayName.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.pressStart2p(
                          fontSize: isCompact ? 8 : 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.bankedCurrency,
    required this.masteryLevel,
    required this.masteryXp,
    required this.nextLevelXp,
    required this.isCompact,
  });

  final int bankedCurrency;
  final int masteryLevel;
  final int masteryXp;
  final int nextLevelXp;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final progress = nextLevelXp > 0
        ? (masteryXp / nextLevelXp).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: RetroColors.gold.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PixelIconAsset(
                assetName: PixelIconAsset.coin,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONEDAS',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 7,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _coins(bankedCurrency),
                      style: GoogleFonts.pressStart2p(
                        fontSize: isCompact ? 11 : 13,
                        fontWeight: FontWeight.bold,
                        color: RetroColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MAESTRÍA LVL $masteryLevel',
                style: GoogleFonts.pressStart2p(
                  fontSize: 7,
                  color: RetroColors.cyan,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.vt323(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFF070D16),
              color: RetroColors.cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreStatusBadge extends StatelessWidget {
  const _StoreStatusBadge({
    required this.isUnlocked,
    required this.isCompact,
  });

  final bool isUnlocked;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (isUnlocked) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: isCompact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0C241B),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: RetroColors.green, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: RetroColors.green, size: 12),
            const SizedBox(width: 6),
            Text(
              'TIENDA DESBLOQUEADA',
              style: GoogleFonts.pressStart2p(
                fontSize: 6.5,
                color: RetroColors.green,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2B190F),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: RetroColors.gold, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: RetroColors.gold, size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'CATÁLOGO · SUPERA CAMPAÑA',
              style: GoogleFonts.pressStart2p(
                fontSize: 6.5,
                color: RetroColors.gold,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.isCompact,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12,
            vertical: isCompact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : const Color(0xFF0C1420),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? color : const Color(0xFF1E354F),
              width: isSelected ? 2 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? color : Colors.white54, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.pressStart2p(
                        fontSize: isCompact ? 8 : 9,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.vt323(
                        fontSize: 13,
                        color: isSelected ? color : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.chevron_right, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreNoticeBar extends StatelessWidget {
  const _StoreNoticeBar({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? RetroColors.magenta : RetroColors.green;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: color.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(
            isError ? Icons.warning_amber : Icons.check_circle,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.vt323(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CATÁLOGO DE MEJORAS (STATS)
// ---------------------------------------------------------------------------

class _StatsCatalog extends ConsumerWidget {
  const _StatsCatalog({
    required this.state,
    required this.isCompactHeight,
  });

  final ProgressionViewState state;
  final bool isCompactHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = state.snapshot;
    final controller = ref.read(progressionControllerProvider.notifier);

    return ListView.builder(
      padding: EdgeInsets.all(isCompactHeight ? 10 : 16),
      itemCount: snapshot.stats.length,
      itemBuilder: (context, index) {
        final stat = snapshot.stats[index];
        final masteryReady =
            snapshot.masteryLevel >= (stat.nextUnlockLevel ?? 0);
        final balanceReady = snapshot.bankedCurrency >= (stat.nextCost ?? 0);
        final canBuy = !state.isBusy &&
            snapshot.storeUnlocked &&
            !stat.isCapped &&
            masteryReady &&
            balanceReady;
        final busy = state.busyAction == 'stat:${stat.id}';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(isCompactHeight ? 10 : 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1724),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: stat.isCapped
                  ? RetroColors.green.withValues(alpha: 0.6)
                  : (canBuy
                      ? RetroColors.cyan.withValues(alpha: 0.5)
                      : const Color(0xFF1E354F)),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono / Rango
              Container(
                width: isCompactHeight ? 40 : 48,
                height: isCompactHeight ? 40 : 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF070D16),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: stat.isCapped ? RetroColors.green : RetroColors.cyan,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _statIcon(stat.id),
                    color:
                        stat.isCapped ? RetroColors.green : RetroColors.cyan,
                    size: isCompactHeight ? 20 : 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Detalles y descripción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            stat.displayName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.pressStart2p(
                              fontSize: isCompactHeight ? 9 : 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RetroBadge(
                          text: stat.isCapped
                              ? 'MAX'
                              : '${stat.rank}/${stat.maxRank}',
                          color: stat.isCapped
                              ? RetroColors.green
                              : RetroColors.gold,
                          fontSize: 7,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.vt323(
                        fontSize: isCompactHeight ? 14 : 15,
                        color: RetroColors.textBright,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Bono actual: +${_percent(stat.effectiveBasisPoints)}',
                          style: GoogleFonts.vt323(
                            fontSize: 14,
                            color: RetroColors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!stat.isCapped && stat.nextCost != null) ...[
                          Text(
                            ' · Siguiente: +${_percent(stat.nextBonusBasisPoints ?? 0)}',
                            style: GoogleFonts.vt323(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Botón de Compra
              _BuyActionButton(
                isCapped: stat.isCapped,
                canBuy: canBuy,
                cost: stat.nextCost,
                unlockLevel: stat.nextUnlockLevel,
                masteryReady: masteryReady,
                balanceReady: balanceReady,
                storeUnlocked: snapshot.storeUnlocked,
                isBusy: busy,
                isCompact: isCompactHeight,
                onPressed: () => controller.purchaseUpgrade(stat),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _statIcon(String id) {
    if (id.contains('life') || id.contains('health')) return Icons.favorite;
    if (id.contains('jump')) return Icons.arrow_upward;
    if (id.contains('speed')) return Icons.flash_on;
    if (id.contains('shield') || id.contains('armor')) return Icons.security;
    return Icons.upgrade;
  }
}

// ---------------------------------------------------------------------------
// CATÁLOGO DE HABILIDADES (SKILLS)
// ---------------------------------------------------------------------------

class _SkillsCatalog extends ConsumerWidget {
  const _SkillsCatalog({
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

    return ListView(
      padding: EdgeInsets.all(isCompactHeight ? 10 : 16),
      children: [
        // Identidad innata del héroe
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(isCompactHeight ? 8 : 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1826),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: RetroColors.cyan, width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.fingerprint, color: RetroColors.cyan, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Habilidad innata: ${definition.description}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.vt323(fontSize: 15, color: Colors.white),
                ),
              ),
              if (definition.defaultActive != null &&
                  snapshot.authorizedBuild.activeSkillId != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: state.isBusy
                      ? null
                      : () => controller.equipActive(null),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    side: const BorderSide(color: RetroColors.cyan),
                  ),
                  child: Text(
                    'RESTAURAR INNATA',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 7,
                      color: RetroColors.cyan,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Lista de habilidades
        for (final skill in snapshot.skills) ...[
          _SkillRow(
            skill: skill,
            state: state,
            isCompactHeight: isCompactHeight,
            onEquipActive: () => controller.equipActive(skill.id),
            onTogglePassive: () => controller.togglePassive(skill.id),
            onPurchase: () => controller.purchaseSkill(skill),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.skill,
    required this.state,
    required this.isCompactHeight,
    required this.onEquipActive,
    required this.onTogglePassive,
    required this.onPurchase,
  });

  final ProgressionSkill skill;
  final ProgressionViewState state;
  final bool isCompactHeight;
  final VoidCallback onEquipActive;
  final VoidCallback onTogglePassive;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.snapshot;
    final isEquipped = skill.slot == SkillSlot.active
        ? snapshot.authorizedBuild.activeSkillId == skill.id
        : snapshot.authorizedBuild.passiveSkillIds.contains(skill.id);
    final masteryReady = snapshot.masteryLevel >= skill.unlockLevel;
    final balanceReady = snapshot.bankedCurrency >= skill.cost;
    final canPurchase = !state.isBusy &&
        snapshot.storeUnlocked &&
        !skill.owned &&
        masteryReady &&
        balanceReady;
    final busy = state.busyAction?.contains(skill.id) == true;

    return Container(
      padding: EdgeInsets.all(isCompactHeight ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1724),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isEquipped
              ? RetroColors.green
              : (skill.owned ? RetroColors.cyan : const Color(0xFF1E354F)),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Insignia de ranura (Activa / Pasiva)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: skill.slot == SkillSlot.active
                  ? RetroColors.cyan.withValues(alpha: 0.15)
                  : RetroColors.magenta.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: skill.slot == SkillSlot.active
                    ? RetroColors.cyan
                    : RetroColors.magenta,
              ),
            ),
            child: Text(
              skill.slot == SkillSlot.active ? 'ACTIVA' : 'PASIVA',
              style: GoogleFonts.pressStart2p(
                fontSize: 7,
                color: skill.slot == SkillSlot.active
                    ? RetroColors.cyan
                    : RetroColors.magenta,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Título y descripción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        skill.displayName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.pressStart2p(
                          fontSize: isCompactHeight ? 8.5 : 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isEquipped) ...[
                      const SizedBox(width: 8),
                      const RetroBadge(
                        text: 'EQUIPADA',
                        color: RetroColors.green,
                        fontSize: 7,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  skill.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.vt323(
                    fontSize: isCompactHeight ? 14 : 15,
                    color: RetroColors.textBright,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Botón Acción
          if (skill.owned)
            FilledButton.icon(
              onPressed: state.isBusy
                  ? null
                  : (skill.slot == SkillSlot.active
                      ? (isEquipped ? null : onEquipActive)
                      : onTogglePassive),
              style: FilledButton.styleFrom(
                backgroundColor: isEquipped
                    ? const Color(0xFF132032)
                    : const Color(0xFF1E354F),
                foregroundColor:
                    isEquipped ? RetroColors.green : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(
                    color: isEquipped ? RetroColors.green : RetroColors.cyan,
                  ),
                ),
              ),
              icon: Icon(
                isEquipped ? Icons.check : Icons.touch_app,
                size: 14,
              ),
              label: Text(
                isEquipped
                    ? (skill.slot == SkillSlot.active ? 'EN USO' : 'QUITAR')
                    : 'EQUIPAR',
                style: GoogleFonts.pressStart2p(fontSize: 7.5),
              ),
            )
          else
            _BuyActionButton(
              isCapped: false,
              canBuy: canPurchase,
              cost: skill.cost,
              unlockLevel: skill.unlockLevel,
              masteryReady: masteryReady,
              balanceReady: balanceReady,
              storeUnlocked: snapshot.storeUnlocked,
              isBusy: busy,
              isCompact: isCompactHeight,
              onPressed: onPurchase,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CATÁLOGO DE PALETAS (SKINS / ASPECTOS)
// ---------------------------------------------------------------------------

class _PalettesCatalog extends ConsumerWidget {
  const _PalettesCatalog({
    required this.state,
    required this.isCompactHeight,
  });

  final ProgressionViewState state;
  final bool isCompactHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = state.snapshot;
    final controller = ref.read(progressionControllerProvider.notifier);

    return GridView.builder(
      padding: EdgeInsets.all(isCompactHeight ? 10 : 16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: isCompactHeight ? 180 : 205,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: snapshot.palettes.length,
      itemBuilder: (context, index) {
        final palette = snapshot.palettes[index];
        final masteryReady = snapshot.masteryLevel >= palette.unlockLevel;
        final balanceReady = snapshot.bankedCurrency >= palette.cost;
        final canPurchase = !state.isBusy &&
            snapshot.storeUnlocked &&
            !palette.owned &&
            masteryReady &&
            balanceReady;
        final busy = state.busyAction?.contains(palette.id) == true;

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1724),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: palette.equipped
                  ? RetroColors.green
                  : (palette.owned ? RetroColors.cyan : const Color(0xFF1E354F)),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Previsualización de personaje con el filtro de color
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF070D16),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: palette.transform.colorFilter ??
                          const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CharacterIcon(
                          assetName:
                              snapshot.characterId.definition.assetName,
                          size: 54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Nombre de la paleta
              Text(
                palette.displayName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.pressStart2p(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),

              // Botón Equipar / Comprar
              if (palette.owned)
                FilledButton(
                  onPressed: palette.equipped || state.isBusy
                      ? null
                      : () => controller.equipPalette(palette.id),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.equipped
                        ? const Color(0xFF132032)
                        : RetroColors.cyan,
                    foregroundColor:
                        palette.equipped ? RetroColors.green : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size.fromHeight(32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    palette.equipped ? 'EQUIPADA' : 'EQUIPAR',
                    style: GoogleFonts.pressStart2p(fontSize: 7.5),
                  ),
                )
              else
                _BuyActionButton(
                  isCapped: false,
                  canBuy: canPurchase,
                  cost: palette.cost,
                  unlockLevel: palette.unlockLevel,
                  masteryReady: masteryReady,
                  balanceReady: balanceReady,
                  storeUnlocked: snapshot.storeUnlocked,
                  isBusy: busy,
                  isCompact: isCompactHeight,
                  onPressed: () => controller.purchasePalette(palette),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// BOTÓN DE ACCIÓN / COMPRA REUTILIZABLE
// ---------------------------------------------------------------------------

class _BuyActionButton extends StatelessWidget {
  const _BuyActionButton({
    required this.isCapped,
    required this.canBuy,
    required this.cost,
    required this.unlockLevel,
    required this.masteryReady,
    required this.balanceReady,
    required this.storeUnlocked,
    required this.isBusy,
    required this.isCompact,
    required this.onPressed,
  });

  final bool isCapped;
  final bool canBuy;
  final int? cost;
  final int? unlockLevel;
  final bool masteryReady;
  final bool balanceReady;
  final bool storeUnlocked;
  final bool isBusy;
  final bool isCompact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isCapped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0C241B),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: RetroColors.green),
        ),
        child: Text(
          'MÁXIMO',
          style: GoogleFonts.pressStart2p(
            fontSize: 7.5,
            color: RetroColors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (canBuy) {
      return FilledButton.icon(
        onPressed: isBusy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: RetroColors.gold,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 14,
            vertical: isCompact ? 8 : 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        icon: isBusy
            ? const SizedBox.square(
                dimension: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const PixelIconAsset(
                assetName: PixelIconAsset.coin,
                size: 14,
              ),
        label: Text(
          _coins(cost ?? 0),
          style: GoogleFonts.pressStart2p(
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Si no se puede comprar, mostrar motivo breve
    String reason = 'BLOQUEADO';
    if (!storeUnlocked) {
      reason = 'REQ. CLEAR';
    } else if (!masteryReady && unlockLevel != null) {
      reason = 'REQ. NVL $unlockLevel';
    } else if (!balanceReady && cost != null) {
      reason = '🪙 ${_coins(cost!)}';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF141A24),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF1E354F)),
      ),
      child: Text(
        reason,
        style: GoogleFonts.pressStart2p(
          fontSize: 7,
          color: Colors.white38,
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
              size: 48,
              color: RetroColors.magenta,
            ),
            const SizedBox(height: 12),
            Text(
              'NO SE PUDO CARGAR LA TIENDA',
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            RetroArcadeButton(
              text: 'REINTENTAR',
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
