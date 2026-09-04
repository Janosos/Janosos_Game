# Checklist de release V6

## Automatizado

- [ ] Formato, analyze y todos los tests Flutter.
- [ ] Web release con CSP y `APP_BACKEND=supabase`.
- [ ] Build nativo release por plataforma objetivo.
- [ ] Las 14 migraciones aplican desde cero; pgTAP y lint pasan.
- [ ] Deno fmt/lint/check y E2E firmados pasan en staging.
- [ ] Carga 25 rps/10 min y 100 rps/1 min con p95 < 2 s y cero invariantes rotos.
- [ ] Restore drill cumple RPO 24 h/RTO 8 h y reaplica tombstones.
- [ ] Escaneo confirma cero secret/service-role/OAuth secret/keystore en Git.

## Recorridos manuales en cada plataforma

- [ ] Registrar, verificar email, iniciar/cerrar sesión y recuperar contraseña.
- [ ] Vincular Google/Apple donde corresponda y volver por deep link.
- [ ] Jugar Estándar con los siete personajes y controles disponibles.
- [ ] Completar campaña 1–10; validar derrota/reset y compras permanentes.
- [ ] Comprar/equipar stats, skills exclusivas y paletas sin cambiar hitboxes.
- [ ] Completar/derrotarse/abandonar Boss Rush y revisar su leaderboard aislado.
- [ ] Probar offline/outbox, retry canónico, expiración y recuperación de red.
- [ ] Probar borrado de cuenta con reautenticación reciente.
- [ ] Probar teclado, touch/gamepad aplicable, lector de pantalla, contraste,
  escalado de texto 200%, audio desactivado y reducción de movimiento.
- [ ] Medir frame pacing y memoria en dispositivo de gama objetivo.

## Configuración externa

- [ ] Supabase producción, secrets de stages/drops y job de retención.
- [ ] Redirect HTTPS/deep links y credenciales Google/Apple finales.
- [ ] Certificados/perfiles Apple, Android upload key, Windows/Linux packaging.
- [ ] GitHub Pages variables y dominio/base path final.
- [ ] Política de privacidad/contacto legal y revisión de nombres por territorio.
- [ ] Ficha, rating, capturas, soporte y proceso de incidencias de cada tienda.

No marques release listo si una casilla de la plataforma o infraestructura
objetivo permanece sin evidencia. Un build local no sustituye firma, hardware,
OAuth ni pruebas en producción/staging.
