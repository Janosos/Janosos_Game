# Privacidad y retención de datos

Janosos V6 no incorpora analytics de comportamiento ni publicidad. Conserva
sólo datos funcionales necesarios para cuentas, progreso, sincronización,
prevención de fraude y rankings.

| Categoría | Finalidad | Retención máxima en vivo |
|---|---|---|
| Perfil e identidades vinculadas | Cuenta y acceso | Hasta borrar la cuenta |
| Progreso, inventario y loadout | Continuidad del juego | Hasta borrar la cuenta |
| Resultados verificados/limitados y ranking | Historial, ranking y soporte | 180 días |
| Resultados/reintentos rechazados y campañas sin resultado válido | Seguridad y diagnóstico | 30 días |
| Receipts terminales de comandos | Idempotencia y soporte | 30 días |
| Señales técnicas sanitizadas | SLO y operación | 14 días |
| Backups cifrados | Recuperación ante desastre | 30 días |
| Tombstone SHA-256 de cuenta eliminada | Evitar resurrección tras restore | Mientras existan backups/restores aplicables |

El cliente sólo recibe como máximo las últimas 100 partidas por filtro mediante
`get_personal_history`; la tabla base no tiene lectura directa para jugadores.
Las señales técnicas admiten categoría, código, medición, duración, correlación
aleatoria y timestamp. Su esquema no admite ID de jugador, email, nombre,
token, request/response, payload ni puntuación.

La tarea `janosos-retention-daily` ejecuta a las 04:17 UTC, expira leases,
elimina datos vencidos, audita solicitudes de borrado de más de 24 horas,
reaplica tombstones y registra sólo contadores agregados.

Datos locales como sesión protegida, outbox cifrado y proyecciones se aíslan por
usuario. Cerrar sesión no equivale a borrar la cuenta. El récord V5 heredado es
local, no atribuido y no se sube.

Antes de publicar, adapta este documento a la jurisdicción, responsable de
tratamiento, contacto de privacidad, base jurídica y derechos aplicables. Este
archivo describe el comportamiento técnico; no reemplaza una política legal.
