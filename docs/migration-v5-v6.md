# Migración de V5 a V6

## Datos locales

Al primer arranque V6 conserva `SharedPreferences.high_score` en Drift con la
etiqueta `Récord local heredado`. Ese récord permanece local, no se atribuye a
una cuenta y nunca se sube al leaderboard porque V5 no tenía evidencia de
verificación compatible.

No borres preferencias ni la base Drift durante la actualización. La migración
de Drift es incremental y conserva el outbox y las proyecciones locales.

## Cuentas y progreso

V5 no tenía una identidad cloud autoritativa. Cada jugador debe registrar o
iniciar sesión en V6; maestría, moneda, compras, skills, paletas, campaña y Boss
Rush empiezan en el estado inicial del servidor. No asocies récords V5 a una
cuenta mediante scripts manuales.

## Compatibilidad de protocolo

- `v6-preview-1`/protocolo 1: compatible y elegible para ranking.
- `v5-legacy`/protocolo 1: ventana máxima de 90 días desde la migración,
  compatible sólo para terminar operaciones válidas y sin ranking.
- Versiones anteriores o vencidas: `unsupported_client_version`.

Mantén cliente actual y anterior desplegados durante la ventana. Antes de
retirar el anterior, comprueba que no existan receipts `processing` ni campañas
activas de esa versión.

## Rollout recomendado

1. Haz backup y prueba su restauración en un proyecto aislado.
2. Aplica las 14 migraciones en staging y despliega las 12 Edge Functions.
3. Ejecuta pgTAP, E2E firmados, carga y los recorridos de release.
4. Publica V6 sin activar monetización premium.
5. Observa SLO, rechazos y outbox por al menos 24 horas.
6. Mantén rollback del cliente; las migraciones son aditivas y no deben
   revertirse destruyendo datos.

## Rollback

Pausa nuevos despliegues y vuelve al binario V6 anterior compatible. No uses
`db reset`, no borres migraciones aplicadas y no restaures selectivamente una
cuenta eliminada. Si una restauración completa es inevitable, sigue el runbook
de backups y reaplica tombstones antes de abrir el servicio.
