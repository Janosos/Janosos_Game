# Runbook de backup y restauración

Objetivos de lanzamiento: RPO ≤ 24 horas, RTO ≤ 8 horas y backups cifrados con
caducidad máxima de 30 días.

## Backup

1. Activa backups diarios/PITR según el plan Supabase de producción.
2. Restringe descarga y restore a operadores designados con MFA.
3. Registra hora, proyecto, cifrado, tamaño y fecha de expiración; no copies
   dumps a carpetas personales ni al repositorio.
4. Exporta por separado los tombstones más recientes a almacenamiento cifrado
   e inmutable para poder reaplicarlos tras un restore.

## Restore drill

Ejecuta trimestralmente en un proyecto aislado:

1. Anota el instante del incidente y selecciona un backup dentro del RPO.
2. Restaura sin habilitar tráfico, OAuth ni jobs externos.
3. Aplica migraciones pendientes.
4. Reaplica tombstones con `private.reapply_deletion_tombstones()`.
5. Ejecuta `private.run_retention_maintenance(now())`.
6. Corre pgTAP, lint, un E2E firmado y valida conteos/invariantes económicos.
7. Comprueba manualmente que ninguna cuenta borrada reapareció.
8. Mide el RTO y documenta desviaciones sin incluir PII.
9. Destruye el proyecto de drill y cualquier dump temporal según política.

## Incidente real

Congela mutaciones antes del restore. Si no puedes asegurar que el conjunto de
tombstones está completo, no abras el servicio. Nunca restaures una sola cuenta
eliminada ni uses un backup para eludir una solicitud de borrado.

La ejecución local de `supabase db reset` valida reproducibilidad del esquema,
pero no cuenta como drill de backup administrado.
