# SLO, alertas y carga

Objetivos mensuales internos:

- autenticación y sincronización disponibles ≥ 99.5%;
- comandos económicos válidos procesados ≥ 99.5%;
- latencia p95 del servidor < 2 segundos;
- 95% del outbox resuelto en cinco minutos tras recuperar conectividad;
- cero commits económicos parciales.

Alertar por burn de SLO, tasa anómala de rechazo, edad del outbox, retención o
borrado atrasado, saturación de base y cuotas al 50/75/90%. Las alertas deben
usar únicamente métricas agregadas y correlaciones aleatorias.

`private.record_operational_event` valida identificadores sanitizados;
`private.operational_events` expira en 14 días. Conecta la tabla o métricas del
proveedor a un sistema de alertas antes de producción. No agregues PII o
payloads para facilitar debugging.

## Carga

Capacidad objetivo: 1,000 DAU, hasta tres campañas diarias por usuario y diez
stages por campaña. Criterio:

```powershell
npx deno run --allow-net --allow-run tool/load_test.ts --rps 25 --seconds 600
npx deno run --allow-net --allow-run tool/load_test.ts --rps 100 --seconds 60
```

La herramienta prueba el RPC autenticado de leaderboard, exige cero respuestas
fallidas y p95 ≤ 2 s, y borra su usuario fixture. Ejecútala sólo en staging o en
una ventana aprobada; para comandos económicos usa fixtures independientes y
verifica invariantes antes/después. Guarda el resumen agregado, no tokens.

Las corridas breves locales sirven como smoke, no como aceptación de capacidad
de producción.

Evidencia local del 2 de septiembre de 2026:

- 25 rps durante 600 s: 15,000 solicitudes, 0 fallos, p50 4 ms,
  p95 5 ms y p99 5 ms.
- 100 rps durante 60 s: 6,000 solicitudes, 0 fallos, p50 4 ms,
  p95 5 ms y p99 5 ms.

Estos resultados validan el harness y la instalación local; la misma prueba
todavía debe repetirse contra staging con observabilidad y cuotas reales.
