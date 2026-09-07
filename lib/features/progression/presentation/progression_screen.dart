import 'dart:math' as math;

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

enum _StoreCategory { stats, palettes }

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
                      title: 'ASPECTOS',
                      subtitle: 'Auras y apariencias',
                      icon: Icons.auto_awesome,
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
                          cat == _StoreCategory.stats ? 'MEJORAS' : 'ASPECTOS',
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
    if (id.contains('vitality') || id.contains('life') || id.contains('health')) {
      return Icons.favorite;
    }
    if (id.contains('speed')) return Icons.flash_on;
    if (id.contains('fortune') || id.contains('coin')) return Icons.monetization_on;
    return Icons.upgrade;
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
        final balanceReady = snapshot.bankedCurrency >= palette.cost;
        final canPurchase = !state.isBusy &&
            snapshot.storeUnlocked &&
            !palette.owned &&
            balanceReady;
        final busy = state.busyAction?.contains(palette.id) == true;

        final Color borderColor;
        if (palette.equipped) {
          borderColor = RetroColors.green;
        } else if (palette.isRainbow) {
          borderColor = RetroColors.gold;
        } else if (palette.owned) {
          borderColor = RetroColors.cyan;
        } else {
          borderColor = const Color(0xFF1E354F);
        }

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1724),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: borderColor,
              width: palette.isRainbow || palette.equipped ? 1.8 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Previsualización destacada de personaje con Aura
              Expanded(
                child: _SkinPreviewBox(
                  palette: palette,
                  assetName: snapshot.characterId.definition.assetName,
                ),
              ),
              const SizedBox(height: 6),

              // Nombre de la paleta con estilo según aura
              Text(
                palette.isRainbow
                    ? '★ ${palette.displayName.toUpperCase()} ★'
                    : palette.displayName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.pressStart2p(
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                  color: palette.isRainbow
                      ? RetroColors.gold
                      : (palette.auraType == SkinAuraType.aurora
                          ? RetroColors.cyan
                          : (palette.auraType == SkinAuraType.eclipse
                              ? const Color(0xFFC084FC)
                              : Colors.white)),
                ),
              ),
              if (palette.isRainbow) ...[
                const SizedBox(height: 2),
                Text(
                  'MÍTICA · EFECTO ARCOÍRIS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(
                    fontSize: 13,
                    color: RetroColors.gold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
              const SizedBox(height: 4),

              // Botón Equipar / Comprar (Siempre desbloqueado para compra)
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
                  unlockLevel: 0,
                  masteryReady: true,
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
// PREVISUALIZACIÓN DE SKIN CON AURA DESTACADA
// ---------------------------------------------------------------------------

class _SkinPreviewBox extends StatefulWidget {
  const _SkinPreviewBox({
    required this.palette,
    required this.assetName,
  });

  final PaletteVariant palette;
  final String assetName;

  @override
  State<_SkinPreviewBox> createState() => _SkinPreviewBoxState();
}

class _SkinPreviewBoxState extends State<_SkinPreviewBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat();
    } else {
      _controller.value = 0.25;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aura = widget.palette.auraType;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final rainbowHue = (progress * 360).toInt();

        BoxDecoration auraDecoration;
        Widget? auraBadge;

        switch (aura) {
          case SkinAuraType.aurora:
            final pulse = 0.82 + 0.18 * math.sin(progress * 2 * math.pi);
            auraDecoration = BoxDecoration(
              color: const Color(0xFF06151E),
              borderRadius: BorderRadius.circular(4),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.85 * pulse,
                colors: const [
                  Color(0x9900FFD5),
                  Color(0x3300B4D8),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FFD5).withValues(alpha: 0.25 * pulse),
                  blurRadius: 12,
                  spreadRadius: 1.5,
                ),
              ],
            );
            auraBadge = _buildAuraBadge('AURA AURORA', RetroColors.cyan);
            break;

          case SkinAuraType.eclipse:
            final pulse = 0.82 + 0.18 * math.cos(progress * 2 * math.pi);
            auraDecoration = BoxDecoration(
              color: const Color(0xFF13091F),
              borderRadius: BorderRadius.circular(4),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.85 * pulse,
                colors: const [
                  Color(0x99A855F7),
                  Color(0x356B21A8),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.25 * pulse),
                  blurRadius: 12,
                  spreadRadius: 1.5,
                ),
              ],
            );
            auraBadge = _buildAuraBadge('AURA ECLIPSE', const Color(0xFFC084FC));
            break;

          case SkinAuraType.rainbow:
            final pulse = 0.85 + 0.15 * math.sin(progress * 4 * math.pi);
            final animatedColor = HSVColor.fromAHSV(1.0, rainbowHue.toDouble(), 1.0, 1.0).toColor();
            auraDecoration = BoxDecoration(
              color: const Color(0xFF100720),
              borderRadius: BorderRadius.circular(4),
              gradient: SweepGradient(
                center: Alignment.center,
                transform: GradientRotation(progress * 2 * math.pi),
                colors: const [
                  Color(0xDDFF0055),
                  Color(0xDDFF8800),
                  Color(0xDDFFEE00),
                  Color(0xDD00FF66),
                  Color(0xDD00F5FF),
                  Color(0xDD7928CA),
                  Color(0xDDFF0055),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: animatedColor.withValues(alpha: 0.35 * pulse),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            );
            auraBadge = _buildAuraBadge('AURA ARCOÍRIS', RetroColors.gold);
            break;

          case SkinAuraType.none:
            auraDecoration = BoxDecoration(
              color: const Color(0xFF070D16),
              borderRadius: BorderRadius.circular(4),
            );
            auraBadge = null;
            break;
        }

        final ColorFilter characterFilter;
        if (widget.palette.isRainbow) {
          characterFilter = PaletteTransform(
            hueShift: rainbowHue,
            saturationBasisPoints: 12500,
            valueBasisPoints: 11000,
            isRainbow: true,
          ).colorFilter!;
        } else {
          characterFilter = widget.palette.transform.colorFilter ??
              const ColorFilter.mode(Colors.transparent, BlendMode.dst);
        }

        return Container(
          decoration: auraDecoration,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Personaje base con filtro cromático
              Center(
                child: ColorFiltered(
                  colorFilter: characterFilter,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CharacterIcon(
                      assetName: widget.assetName,
                      size: 54,
                    ),
                  ),
                ),
              ),

              // Reflejo prismático holográfico sobre el personaje
              if (widget.palette.isRainbow) ...[
                Center(
                  child: ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (bounds) {
                      final beamOffset = -2.0 + (progress * 4.0);
                      return LinearGradient(
                        begin: Alignment(beamOffset - 0.7, -1.2),
                        end: Alignment(beamOffset + 0.7, 1.2),
                        colors: const [
                          Colors.transparent,
                          Color(0x88FF0055),
                          Color(0xAAFF8800),
                          Color(0xCCFFEE00),
                          Color(0xAA00FF66),
                          Color(0xAA00F5FF),
                          Color(0x887928CA),
                          Color(0xEEFFFFFF),
                          Colors.transparent,
                        ],
                        stops: const [
                          0.0,
                          0.15,
                          0.30,
                          0.45,
                          0.60,
                          0.75,
                          0.88,
                          0.94,
                          1.0,
                        ],
                      ).createShader(bounds);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CharacterIcon(
                        assetName: widget.assetName,
                        size: 54,
                      ),
                    ),
                  ),
                ),

                // Destellos estelares que titilan en arcoíris
                Positioned(
                  top: 12,
                  left: 18,
                  child: _RainbowSparkle(
                    progress: progress,
                    phaseOffset: 0.0,
                    size: 11,
                    baseHue: rainbowHue,
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 16,
                  child: _RainbowSparkle(
                    progress: progress,
                    phaseOffset: 0.38,
                    size: 9,
                    baseHue: (rainbowHue + 120) % 360,
                  ),
                ),
                Positioned(
                  top: 22,
                  right: 14,
                  child: _RainbowSparkle(
                    progress: progress,
                    phaseOffset: 0.72,
                    size: 10,
                    baseHue: (rainbowHue + 240) % 360,
                  ),
                ),
              ],

              if (auraBadge != null)
                Positioned(
                  top: 5,
                  child: auraBadge,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuraBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xEE000000),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.pressStart2p(
          fontSize: 5.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _RainbowSparkle extends StatelessWidget {
  const _RainbowSparkle({
    required this.progress,
    required this.phaseOffset,
    required this.size,
    required this.baseHue,
  });

  final double progress;
  final double phaseOffset;
  final double size;
  final int baseHue;

  @override
  Widget build(BuildContext context) {
    final t = ((progress + phaseOffset) % 1.0) * 2 * math.pi;
    final scale = (math.sin(t) * 0.45 + 0.55).clamp(0.1, 1.0);
    final color = HSVColor.fromAHSV(
      1.0,
      baseHue.toDouble(),
      0.9,
      1.0,
    ).toColor();

    return Transform.scale(
      scale: scale,
      child: Transform.rotate(
        angle: progress * 2 * math.pi,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _SparklePainter(color: color),
          ),
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..moveTo(center.dx, 0)
      ..quadraticBezierTo(center.dx, center.dy, size.width, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, size.height)
      ..quadraticBezierTo(center.dx, center.dy, 0, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, 0)
      ..close();
    canvas.drawPath(path, paint);

    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.18, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.color != color;
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
