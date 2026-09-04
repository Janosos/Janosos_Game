# Borrado de cuenta

## Jugador

1. Abre `Configuración` → `Eliminar mi cuenta`.
2. Si el inicio de sesión fuerte tiene más de diez minutos, vuelve a autenticar.
3. Escribe `ELIMINAR` y confirma.

La acción elimina la identidad Auth y las filas de aplicación mediante cascada,
cierra la sesión local y conserva únicamente un hash SHA-256 no reversible con
el receipt idempotente. La meta operativa es completar el borrado del sistema
en vivo dentro de 24 horas. Backups cifrados vencen en 30 días y no se usan para
restaurar selectivamente una cuenta borrada.

## Operación

La Edge Function `delete-account` exige JWT, autenticación fuerte reciente y un
UUID idempotente. Usa la secret key sólo en servidor. Nunca registres el JWT,
email, UUID del usuario ni body.

Comprueba diariamente:

```sql
select private.audit_account_deletion_sla(now());
select * from private.retention_runs order by completed_at desc limit 10;
```

Un resultado mayor a cero crea `account_deletion_sla_breach` con un contador
agregado. Investiga la función, Auth Admin API y receipts `processing`; no
expongas hashes en tickets externos.

## Después de restaurar un backup

Con el servicio todavía cerrado:

```sql
select private.reapply_deletion_tombstones();
select private.run_retention_maintenance(now());
```

Verifica que el resultado sea coherente, que no queden solicitudes atrasadas y
recién entonces abre tráfico. Los tombstones no se borran al reaplicarse.
