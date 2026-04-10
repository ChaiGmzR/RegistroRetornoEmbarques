# Guia de Publicacion de Actualizaciones - GitHub Releases

## Configuracion Inicial del Repositorio

### 1. Inicializar Git (si no esta inicializado)
```bash
cd c:\Users\jesus\OneDrive\Documents\Desarrollo\RegistroRetornoEmbarques
git init
git add .
git commit -m "Initial commit"
```

### 2. Crear Repositorio en GitHub
1. Ve a [github.com/new](https://github.com/new)
2. Nombre del repositorio: `RegistroRetornoEmbarques`
3. Puede ser publico o privado
4. **NO** inicialices con README, .gitignore o licencia

### 3. Conectar con GitHub
```bash
git remote add origin https://github.com/ChaiGmzR/RegistroRetornoEmbarques.git
git branch -M main
git push -u origin main
```

---

## Proceso de Publicacion de Nueva Version

### Paso 1: Actualizar Numero de Version

Editar **TRES** archivos con la nueva version:

1. **pubspec.yaml** (linea 19):
```yaml
version: 1.1.0+N
```
> `+N` es el numero de build incremental (ej: si la anterior fue `+1`, usar `+2`).
> En Android, `+N` se usa como `versionCode` y debe ser **siempre mayor** que el anterior.

2. **lib/core/constants/app_constants.dart** (linea 4):
```dart
static const String appVersion = '1.1.0';
```

3. **lib/core/config/update_config.dart** (linea 10):
```dart
static const String currentVersion = '1.1.0';
```

> **IMPORTANTE:** Las versiones en estos 3 archivos deben coincidir para que el sistema de auto-actualizacion funcione correctamente.

### Paso 2: Apuntar al Entorno de Produccion

En **lib/core/config/api_config.dart**, verificar que el entorno apunte a produccion:

```dart
static const ApiEnvironment environment = ApiEnvironment.production;
```

> **IMPORTANTE:** Si estabas desarrollando con `localEmulator` o `localLan`, cambialo a `production` antes de compilar el release.

### Paso 3: Compilar el APK de Release

```bash
cd c:\Users\jesus\OneDrive\Documents\Desarrollo\RegistroRetornoEmbarques
flutter build apk --release
```

El APK se genera en: `build\app\outputs\flutter-apk\app-release.apk`

Renombrar el APK para incluir la version:
```bash
cp build/app/outputs/flutter-apk/app-release.apk "Registro_Embarques_1.1.0.apk"
```

### Paso 4: Commit y Tag de Git

```bash
git add .
git restore --staged *.apk
git restore --staged build/
git commit -m "Release v1.1.0 - Descripcion de cambios"
git tag v1.1.0
git push origin main --tags
```

### Paso 5: Crear Release en GitHub

**Opcion A: Con GitHub CLI (recomendado)**
```bash
gh release create v1.1.0 "Registro_Embarques_1.1.0.apk" \
  --title "Version 1.1.0 - Titulo descriptivo" \
  --notes "Descripcion de cambios"
```

**Opcion B: Desde la web**
1. Ve a: https://github.com/ChaiGmzR/RegistroRetornoEmbarques/releases/new
2. Selecciona el tag: `v1.1.0`
3. Titulo: `Version 1.1.0 - Titulo descriptivo`
4. Descripcion: Lista de cambios (Release Notes)
5. Arrastra el archivo **`Registro_Embarques_1.1.0.apk`** a la seccion de assets
6. Click en **Publish release**

---

## Como funciona la Auto-Actualizacion

La app incluye un sistema de auto-actualizacion que verifica automaticamente si hay nuevas versiones disponibles en GitHub Releases.

### Flujo de Auto-Actualizacion

```
┌─────────────────┐     ┌──────────────────┐     ┌────────────────────────┐
│  TI compila y   │────>│  TI sube APK a   │────>│  Operador abre la app  │
│  genera release │     │  GitHub Release  │     │  y ve aviso de update  │
└─────────────────┘     └──────────────────┘     └───────────┬────────────┘
                                                             │
                        ┌────────────────────────────────────┘
                        v
        ┌───────────────────────────────────┐
        │  Operador toca "Actualizar"       │
        │  → Descarga APK en dispositivo    │
        │  → Abre instalador de Android     │
        │  → Acepta instalacion             │
        │  → App actualizada!               │
        └───────────────────────────────────┘
```

### Comportamiento

1. **Al iniciar la app:** Verifica automaticamente si hay un nuevo release en GitHub
2. **Si hay actualizacion:** Muestra un dialogo con las notas de version y boton de descarga
3. **Al tocar "Actualizar":** Descarga el APK con barra de progreso
4. **Al completar descarga:** Abre el instalador de Android para que el usuario confirme
5. **Verificacion manual:** El usuario puede ir a Ajustes > Buscar actualizaciones

### Configuracion (update_config.dart)

```dart
class UpdateConfig {
  static const String githubUser = 'ChaiGmzR';
  static const String repoName = 'RegistroRetornoEmbarques';
  static const String currentVersion = '1.0.0';
  static const String assetFilePattern = '.apk';
  static const bool checkOnStartup = true;
  static const int checkIntervalHours = 0; // 0 = siempre verificar
}
```

### Requisitos para que funcione

1. El repositorio debe ser **publico** o el dispositivo debe tener acceso a la API de GitHub
2. El release debe tener un asset `.apk` adjunto
3. El tag del release debe seguir el formato `vX.Y.Z` (ej: `v1.2.0`)
4. La version del release debe ser **mayor** que `UpdateConfig.currentVersion`

---

## Distribucion Manual (Sideloading)

Si la auto-actualizacion no es posible (sin internet, repo privado, etc.), la app se puede actualizar manualmente.

### Instalacion en Dispositivo Zebra TC15

1. Descargar el `.apk` del release de GitHub desde el dispositivo o transferirlo por USB/red local
2. En el dispositivo, habilitar **Origenes desconocidos** (solo la primera vez):
   - Ajustes > Seguridad > Origenes desconocidos > Activar
3. Abrir el archivo `.apk` e instalar
4. Si ya existe una version anterior, Android la actualizara conservando los datos

### Instalacion por ADB (desde PC)

```bash
adb install -r Registro_Embarques_1.1.0.apk
```
> `-r` reemplaza la instalacion existente sin borrar datos.

### Instalacion masiva (multiples dispositivos)

Si tienes varios Zebra TC15 conectados por USB:
```bash
adb devices
adb -s <SERIAL_1> install -r Registro_Embarques_1.1.0.apk
adb -s <SERIAL_2> install -r Registro_Embarques_1.1.0.apk
```

---

## Firma del APK (Signing)

### Configuracion Inicial (solo una vez)

Actualmente el release usa debug keys. Para produccion, es recomendable crear un keystore propio:

```bash
keytool -genkey -v -keystore embarques-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias embarques
```

Luego crear `android/key.properties`:
```properties
storePassword=<tu_password>
keyPassword=<tu_password>
keyAlias=embarques
storeFile=../../embarques-release-key.jks
```

Y actualizar `android/app/build.gradle.kts` para usar el keystore en release builds.

> **IMPORTANTE:**
> - Nunca subir `embarques-release-key.jks` ni `key.properties` al repositorio.
> - Agregar ambos al `.gitignore`.
> - Guardar una copia de respaldo del keystore en un lugar seguro. Si se pierde, no podras publicar actualizaciones firmadas con la misma clave.

---

## Checklist Pre-Release

- [ ] Version actualizada en `pubspec.yaml` (version + versionCode)
- [ ] Version actualizada en `app_constants.dart`
- [ ] Version actualizada en `update_config.dart`
- [ ] `ApiConfig.environment` apunta a `production`
- [ ] Compilacion Flutter exitosa (`flutter build apk --release`)
- [ ] APK renombrado con numero de version (ej: `Registro_Embarques_1.1.0.apk`)
- [ ] APK probado en un dispositivo Zebra TC15 antes de distribuir
- [ ] Tag de Git creado con formato `vX.Y.Z`
- [ ] Release publicado en GitHub con el **`.apk`** adjunto

---

## Verificacion Post-Instalacion

Despues de instalar en el dispositivo Zebra TC15:

1. Abrir la app y verificar que aparece la version correcta en Ajustes
2. Confirmar conexion al backend de produccion (indicador de conexion verde)
3. Probar login con un operador real
4. Realizar un escaneo de prueba con el lector de codigo de barras
5. Verificar que el registro se guarda en el historial
6. **Probar auto-update:** En Ajustes > Buscar actualizaciones (deberia decir "Estas en la ultima version")

---

## Errores Comunes

| Error | Causa | Solucion |
|-------|-------|----------|
| "No se pudo conectar al servidor" | `ApiConfig.environment` no apunta a `production` | Cambiar a `ApiEnvironment.production` y recompilar |
| App no se instala en Zebra TC15 | Origenes desconocidos deshabilitado | Habilitar en Ajustes > Seguridad |
| "App no instalada" al actualizar | APK firmado con clave diferente | Desinstalar version anterior e instalar de nuevo |
| El escaner de barras no funciona | Permisos de teclado/input no configurados | Verificar configuracion de Zebra DataWedge |
| Version no cambia tras actualizar | versionCode no se incremento | Verificar que `+N` en `pubspec.yaml` sea mayor que la version anterior |
| Auto-update no detecta nueva version | `update_config.dart` no fue actualizado | Verificar que `currentVersion` coincida con la version publicada |
| "URL de descarga no disponible" | Release sin asset `.apk` | Subir el APK al release en GitHub |
| Error al instalar desde la app | Permiso de instalar apps no otorgado | El usuario debe aceptar el permiso cuando se solicite |

---

## Notas Importantes

1. **Versionado Semantico**: Usa formato `MAJOR.MINOR.PATCH` (ej: 1.2.3)
2. **Tags de Git**: Siempre con prefijo `v` (ej: v1.2.3)
3. **versionCode**: El `+N` en `pubspec.yaml` **debe incrementarse siempre** — Android rechaza instalar un APK con versionCode igual o menor
4. **Tres archivos de version**: `pubspec.yaml`, `app_constants.dart`, y `update_config.dart` deben tener la misma version
5. **Asset del Release**: Siempre debe ser un `.apk` con nombre descriptivo incluyendo la version
6. **Rollback**: Si hay problemas, crea un nuevo release con version superior que contenga una version estable anterior
7. **No subir binarios al repo**: Excluir `.apk` y `build/` del commit con `git restore --staged`
8. **Entorno de compilacion**: Siempre verificar que `ApiConfig.environment = production` antes de generar un release
9. **Repositorio publico**: Para que la auto-actualizacion funcione sin autenticacion, el repo debe ser publico
