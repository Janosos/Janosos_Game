# Configuración de desarrollo y despliegue

## Toolchains

Instala Flutter estable y las herramientas de la plataforma a compilar:

- Web: Chrome o Edge.
- Windows: Visual Studio Build Tools con Desktop C++, CMake, Windows SDK y ATL.
- Android: Android SDK command-line tools, platform/build-tools aceptados y
  JDK 17. La firma release se lee de `android/key.properties`, que está ignorado.
- iOS/macOS: Xcode en macOS y una identidad de firma propia.
- Linux: clang, cmake, ninja, GTK 3 y `libsecret-1-dev`.
- Backend: Docker Desktop, Supabase CLI y Deno 2.

Verifica con `flutter doctor -v` y resuelve todos los errores de la plataforma
que quieras publicar.

## Desarrollo sin nube

```powershell
flutter pub get
dart run build_runner build
flutter run -d windows
```

`APP_BACKEND=local` es el valor predeterminado. Permite completar los diez
niveles, acumular y gastar moneda, comprar/equipar progresión por personaje y
desbloquear Boss Rush con persistencia por cuenta en el dispositivo. Sus datos
no salen del equipo, no generan resultados globales verificados y el login
local no representa seguridad de producción.

## Supabase local

```powershell
npx supabase start
npx supabase db reset --local
npx supabase test db
npx supabase db lint --local --schema private,public --level warning --fail-on warning
```

Crea `supabase/.env.local` (ignorado por Git) con secretos sólo de servidor:

```text
STAGE_SIGNING_KEY_V1=<32 bytes aleatorios o más>
BOSS_DROP_KEY_V1=<32 bytes aleatorios o más>
```

Después ejecuta:

```powershell
npx supabase functions serve --env-file supabase/.env.local
```

Los E2E locales de `supabase/tests/e2e` crean y eliminan usuarios fixture. No
los ejecutes contra producción.

## Cliente Supabase

```powershell
flutter run -d chrome `
  --dart-define=APP_BACKEND=supabase `
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_REPLACE_ME `
  --dart-define=AUTH_REDIRECT_URI=https://HOST/Janosos_Game/ `
  --dart-define=CONTENT_VERSION=v6-preview-1
```

`SUPABASE_PUBLISHABLE_KEY` es configuración pública. Nunca pases una secret key,
`service_role`, clave de firma, secreto OAuth o llave de tienda con
`--dart-define`: los defines forman parte del binario distribuido.

Sigue [configuration/authentication.md](configuration/authentication.md) para
Google/Apple, callbacks y deep links nativos.

## GitHub Pages

El workflow requiere estas variables del repositorio o environment:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `AUTH_REDIRECT_URI`
- `GOOGLE_WEB_CLIENT_ID` (opcional hasta habilitar Google)
- `GOOGLE_APPLE_CLIENT_ID` (opcional; cliente Google para Apple platforms)

Configura Pages con GitHub Actions como source. El job falla si falta la
configuración principal y compila siempre con `APP_BACKEND=supabase`.

## Firma Android

Genera la llave fuera del repositorio y crea `android/key.properties`:

```text
storePassword=REPLACE_ME
keyPassword=REPLACE_ME
keyAlias=upload
storeFile=C:/ruta/fuera/del/repositorio/upload-keystore.jks
```

Respalda la upload key mediante el procedimiento de tu organización. Un build
sin este archivo sirve para comprobar compilación, pero no es publicable.
