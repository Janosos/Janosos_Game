import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../game/domain/character_id.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/progression_models.dart';

class ProgressionViewState {
  const ProgressionViewState({
    required this.snapshot,
    this.busyAction,
    this.noticeMessage,
    this.errorMessage,
  });

  final ProgressionSnapshot snapshot;
  final String? busyAction;
  final String? noticeMessage;
  final String? errorMessage;

  bool get isBusy => busyAction != null;

  ProgressionViewState copyWith({
    ProgressionSnapshot? snapshot,
    String? busyAction,
    String? noticeMessage,
    String? errorMessage,
    bool clearBusy = false,
    bool clearNotice = false,
    bool clearError = false,
  }) {
    return ProgressionViewState(
      snapshot: snapshot ?? this.snapshot,
      busyAction: clearBusy ? null : busyAction ?? this.busyAction,
      noticeMessage: clearNotice ? null : noticeMessage ?? this.noticeMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final progressionControllerProvider =
    AsyncNotifierProvider<ProgressionController, ProgressionViewState>(
      ProgressionController.new,
    );

class ProgressionController extends AsyncNotifier<ProgressionViewState> {
  @override
  Future<ProgressionViewState> build() async {
    ref.watch(authControllerProvider.select((auth) => auth.session.user?.id));
    return _load(CharacterId.jano);
  }

  Future<void> selectCharacter(CharacterId characterId) async {
    final current = state.value;
    if (current?.snapshot.characterId == characterId) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(characterId));
  }

  Future<void> refresh() async {
    final characterId = state.value?.snapshot.characterId ?? CharacterId.jano;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(characterId));
  }

  Future<void> purchaseUpgrade(ProgressionStat stat) async {
    await _mutate(
      'stat:${stat.id}',
      (snapshot) => ref
          .read(progressionRepositoryProvider)
          .purchaseUpgrade(snapshot: snapshot, stat: stat),
      '${stat.displayName} avanzó al rango ${stat.rank + 1}.',
    );
  }

  Future<void> purchaseSkill(ProgressionSkill skill) async {
    await _mutate(
      'skill:${skill.id}',
      (snapshot) => ref
          .read(progressionRepositoryProvider)
          .purchaseSkill(snapshot: snapshot, skill: skill),
      '${skill.displayName} se añadió al inventario del personaje.',
    );
  }

  Future<void> purchasePalette(PaletteVariant palette) async {
    await _mutate(
      'palette:${palette.id}',
      (snapshot) => ref
          .read(progressionRepositoryProvider)
          .purchasePalette(snapshot: snapshot, palette: palette),
      'La paleta ${palette.displayName} ya pertenece al personaje.',
    );
  }

  Future<void> equipActive(String? skillId) async {
    final snapshot = state.value?.snapshot;
    if (snapshot == null) return;
    await _equip(
      actionId: 'equip-active:${skillId ?? 'default'}',
      activeSkillId: skillId,
      passiveSkillIds: snapshot.authorizedBuild.passiveSkillIds,
      skinId: snapshot.authorizedBuild.skinId,
      successMessage: skillId == null
          ? 'Se restauró la habilidad activa predeterminada.'
          : 'Habilidad activa equipada.',
    );
  }

  Future<void> togglePassive(String skillId) async {
    final snapshot = state.value?.snapshot;
    if (snapshot == null) return;
    final passives = [...snapshot.authorizedBuild.passiveSkillIds];
    if (passives.remove(skillId)) {
      await _equip(
        actionId: 'equip-passive:$skillId',
        activeSkillId: snapshot.authorizedBuild.activeSkillId,
        passiveSkillIds: passives,
        skinId: snapshot.authorizedBuild.skinId,
        successMessage: 'Habilidad pasiva retirada.',
      );
      return;
    }
    if (passives.length >= 2) {
      state = AsyncData(
        state.requireValue.copyWith(
          errorMessage: 'Sólo puedes equipar dos habilidades pasivas.',
          clearNotice: true,
        ),
      );
      return;
    }
    passives.add(skillId);
    await _equip(
      actionId: 'equip-passive:$skillId',
      activeSkillId: snapshot.authorizedBuild.activeSkillId,
      passiveSkillIds: passives,
      skinId: snapshot.authorizedBuild.skinId,
      successMessage: 'Habilidad pasiva equipada.',
    );
  }

  Future<void> equipPalette(String skinId) async {
    final snapshot = state.value?.snapshot;
    if (snapshot == null) return;
    await _equip(
      actionId: 'equip-palette:$skinId',
      activeSkillId: snapshot.authorizedBuild.activeSkillId,
      passiveSkillIds: snapshot.authorizedBuild.passiveSkillIds,
      skinId: skinId,
      successMessage: 'Paleta equipada.',
    );
  }

  Future<void> _equip({
    required String actionId,
    required String? activeSkillId,
    required List<String> passiveSkillIds,
    required String? skinId,
    required String successMessage,
  }) {
    return _mutate(
      actionId,
      (snapshot) => ref
          .read(progressionRepositoryProvider)
          .equipLoadout(
            snapshot: snapshot,
            selection: LoadoutSelection(
              activeSkillId: activeSkillId,
              passiveSkillIds: passiveSkillIds,
              skinId: skinId,
            ),
          ),
      successMessage,
    );
  }

  Future<void> _mutate(
    String actionId,
    Future<void> Function(ProgressionSnapshot) action,
    String successMessage,
  ) async {
    final current = state.value;
    if (current == null || current.isBusy) return;
    state = AsyncData(
      current.copyWith(
        busyAction: actionId,
        clearNotice: true,
        clearError: true,
      ),
    );
    try {
      await action(current.snapshot);
      final refreshed = await _load(current.snapshot.characterId);
      state = AsyncData(refreshed.copyWith(noticeMessage: successMessage));
    } on Object catch (error) {
      state = AsyncData(
        current.copyWith(
          errorMessage: _friendlyError(error),
          clearBusy: true,
          clearNotice: true,
        ),
      );
    }
  }

  Future<ProgressionViewState> _load(CharacterId characterId) async {
    final environment = ref.read(appEnvironmentProvider);
    final snapshot = await ref
        .read(progressionRepositoryProvider)
        .loadSnapshot(
          characterId: characterId,
          contentVersion: environment.contentVersion,
        );
    return ProgressionViewState(snapshot: snapshot);
  }

  static String _friendlyError(Object error) {
    if (error is AppFailure) return error.message;
    return 'No se pudo actualizar la progresión. Inténtalo de nuevo.';
  }
}
