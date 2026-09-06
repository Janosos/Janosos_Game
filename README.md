# Janosos Game V6.1

Runner 2D retro construido con Flutter y Flame. V6.1 mejora la experiencia de
combate contra jefes, la responsividad en móviles y los controles táctiles.

![Janosos Game](assets/images/title_retro.png)

## Novedades en V6.1

### Gameplay
- **Jano daña jefes**: El disparo destructor de Jano ahora impacta directamente
  a los jefes (300 puntos de daño) e intercepta sus proyectiles.
- **Contadores de cooldown restaurados**: Todas las habilidades muestran su
  temporizador en tiempo real (DISPARO, FANTASMA, ESCUDO, ENERGÍA) tanto en el
  HUD como en los botones de habilidad y golpe al jefe.
- **Hitboxes precisos**: Los jefes, proyectiles y obstáculos usan hitboxes
  ajustados al cuerpo visible, eliminando daño fantasma.
- **Movimiento lateral**: Mecánica de movimiento izquierda/derecha con teclas
  A/D o flechas, y D-Pad táctil retro en dispositivos móviles.
- **Ataques dirigidos**: Las cartas y proyectiles de los jefes apuntan a la
  posición del jugador, forzándolo a esquivar activamente.
- **Desbloqueo permanente de jefes**: Al derrotar un jefe, queda desbloqueado
  para siempre con opción de volver a jugarlo.

### Responsividad y Controles
- **Landscape optimizado para móviles**: Barras superior/inferior reducidas en
  pantallas delgadas, calle dinámica (~25% de la altura en vez de 50%), y
  amplio espacio vertical para el combate.
- **D-Pad táctil retro**: Flechas direccionales que aparecen automáticamente
  solo en navegadores móviles y tablets (detección por User-Agent y touch).
- **Compatibilidad GitHub Pages**: Funciona tanto en navegadores de PC (sin
  flechas, usa teclado) como en navegadores móviles (con flechas táctiles).
- **Barra de vida del jefe sin recorte**: El título del jefe (★ JINETE SIN
  CABEZA ★) siempre visible con margen seguro desde el borde superior.

### Estabilidad
- **Precarga resiliente de assets**: Cada imagen y audio se carga
  individualmente con manejo de errores, evitando caídas por assets faltantes.
- **Sprites de jefes mejorados**: Limpieza de transparencia, 4 poses dinámicas
  de movimiento por jefe, y orientación constante hacia el jugador.

## Juego

- Siete personajes: Jano, Parker, Chema, Conra, Shyno, Nakama y Nanic.
- Habilidades innatas conservadas y 28 skills comprables exclusivas, cuatro por
  personaje.
- Modo Estándar normalizado, sin ventajas compradas ni recompensas económicas.
- Campaña de diez niveles. Perder o abandonar reinicia la campaña y elimina la
  moneda temporal; maestría, compras, paletas y drops únicos se conservan.
- Diez jefes con patrones y siluetas originales. Cada jefe tiene un drop único
  con probabilidad fija del 1%. Supabase resuelve el drop verificable en el
  servidor; el backend local usa una tirada no clasificatoria guardada sólo en
  el dispositivo.
- Boss Rush desbloqueable al completar la campaña: diez jefes seguidos, una
  vida recuperada entre combates, maestría reducida y cero moneda.
- Leaderboards verificados por personaje y modo, más historial personal.
- Registro/inicio de sesión por email y adaptadores Google/Apple.
- Cinco mejoras porcentuales por personaje, 21 variantes de paleta y un límite
  explícito que evita que la tienda sea necesaria para superar el juego.
- Controles persistentes de audio y reducción de movimiento.

Los nombres literarios y cinematográficos usados como referencia corresponden
a personajes de dominio público seleccionados para el diseño. Todo el arte de
jefes incluido es programático y original; la revisión legal de nombres,
territorios y materiales de marketing sigue siendo un gate de publicación.

## Inicio rápido local

Requiere Flutter estable. El backend local permite jugar la campaña completa,
ganar y gastar moneda, comprar/equipar mejoras y paletas, desbloquear Boss Rush
y conservar todo por cuenta en el dispositivo. Sus cuentas, recompensas y
rankings no son cloud ni se consideran verificados.

```powershell
flutter pub get
dart run build_runner build
flutter run -d windows
```

Para Web:

```powershell
flutter run -d chrome
```

La configuración Supabase, OAuth y deep links está en
[docs/setup.md](docs/setup.md) y
[docs/configuration/authentication.md](docs/configuration/authentication.md).

## Backend Supabase local completo

Requiere Docker Desktop, Supabase CLI y Deno.

```powershell
npx supabase start
npx supabase db reset --local
npx supabase test db
npx supabase functions serve --env-file supabase/.env.local
```

Nunca uses una `service_role`/secret key en Flutter ni la guardes en Git. El
cliente recibe únicamente la URL y publishable key de Supabase; firmas de
stages, drops, mutaciones económicas y borrado de Auth permanecen en servidor.

## Calidad

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
flutter test integration_test/local_app_journey_test.dart -d windows
flutter build web --release --base-href "/Janosos_Game/"
npx supabase test db
npx supabase db lint --local --schema private,public --level warning --fail-on warning
```

La herramienta `tool/load_test.ts` ejecuta carga autenticada y elimina su
usuario fixture al terminar. Los gates de lanzamiento son 25 rps durante diez
minutos y una ráfaga de 100 rps durante un minuto en staging/producción.

## Arquitectura

- `lib/game`: runtime Flame determinista, componentes, controles y contratos.
- `lib/features`: auth, campaña, Boss Rush, progresión, rankings y ajustes.
- `lib/core`: Drift, almacenamiento protegido, sesión y outbox AES-GCM.
- `supabase/migrations`: esquema autoritativo, RLS, economía y retención.
- `supabase/functions`: límites HTTP autenticados para comandos firmados.
- `supabase/tests`: pgTAP y recorridos HTTP locales.
- `docs/janosos-v6`: investigación, plan y evidencia acumulada.

## Operación y release

- [Entrega local 6.0.0-dev.1](docs/releases/6.0.0-dev.1.md)
- [Migración V5 → V6](docs/migration-v5-v6.md)
- [Privacidad y retención](docs/privacy-data-retention.md)
- [Borrado de cuenta](docs/account-deletion.md)
- [Backups y restauración](docs/operations/backup-restore.md)
- [SLO y carga](docs/operations/observability-slo.md)
- [Rotación de Apple](docs/operations/apple-secret-rotation.md)
- [Checklist de release](docs/operations/release-checklist.md)

El esquema incluye sólo una separación futura para moneda premium. V6 no tiene
wallet público, pagos, compras premium ni skins de pago; esas capacidades deben
pasar revisión económica, legal, de tiendas y parental antes de activarse.
