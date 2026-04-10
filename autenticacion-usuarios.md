# Autenticacion de Usuarios

> Ultima revision: Marzo 2026

Este documento describe como funciona hoy la autenticacion de usuarios en la aplicacion, que tablas intervienen y como se relacionan.

## Alcance

La autenticacion actual se reparte entre estos componentes:

- Frontend Flutter:
  - `lib/screens/login/login_screen.dart`
  - `lib/core/services/auth_service.dart`
  - `lib/screens/main_tabbed_screen.dart`
- Backend Node.js / Express:
  - `backend/routes/auth.routes.js`
  - `backend/controllers/auth.controller.js`

## Resumen rapido

- No se usan JWT, cookies de sesion ni tabla de sesiones en base de datos.
- El login valida usuario y password contra `usuarios_sistema`.
- Los permisos se cargan aparte desde `user_permissions_materiales`.
- La sesion se conserva del lado cliente en `SharedPreferences`.
- La restauracion de sesion solo verifica que el usuario siga activo.
- La expiracion de sesion es local al cliente: 24 horas desde el ultimo login guardado.

## Flujo de autenticacion

### 1. Login interactivo

1. El usuario captura `username` y `password` en `LoginScreen`.
2. Flutter envia `POST /api/auth/login`.
3. El backend busca el registro en `usuarios_sistema` por `username`.
4. Antes de validar la contrasena revisa:
   - que el usuario exista
   - que `activo = 1`
   - que `bloqueado_hasta` no siga vigente
5. El backend calcula `SHA-256(password)` y lo compara con `password_hash`.
6. Si falla:
   - incrementa `intentos_fallidos`
   - al quinto intento bloquea al usuario por 15 minutos
   - responde `401` con `intentosRestantes`
7. Si es correcto:
   - reinicia `intentos_fallidos`
   - limpia `bloqueado_hasta`
   - actualiza `ultimo_acceso = NOW()`
   - responde el objeto `user` sin exponer `password_hash`
8. Ya autenticado, el cliente llama `GET /api/users/:id/permissions`.
9. Flutter guarda:
   - `user_session`
   - `session_start_time`
10. La app construye tabs y acciones visibles con base en los permisos cargados.

### 2. Restauracion de sesion

Cuando la app arranca:

1. `app.dart` ejecuta `AuthService.restoreSession()`.
2. El cliente revisa si la sesion local ya excedio 24 horas.
3. Si sigue vigente, lee `user_session` desde `SharedPreferences`.
4. Llama `GET /api/auth/verify/:userId`.
5. El backend solo valida que el usuario exista y siga activo.
6. Si la verificacion es valida:
   - se restaura `_currentUser`
   - se vuelven a cargar permisos desde `user_permissions_materiales`
7. Si no es valida:
   - se elimina la sesion local
   - el usuario regresa a login

### 3. Logout

1. Flutter llama `POST /api/auth/logout` con `userId`.
2. El backend actualiza `ultimo_acceso`.
3. El cliente limpia memoria y `SharedPreferences`.

## Autenticacion vs autorizacion

En este proyecto estan separadas:

- Autenticacion:
  - valida identidad del usuario en `usuarios_sistema`
- Autorizacion:
  - decide que puede ver o hacer el usuario
  - usa `user_permissions_materiales`
  - aplica excepcion de acceso total por departamento

### Regla de acceso total

Los usuarios con `departamento` en esta lista tienen todos los permisos sin depender de filas en `user_permissions_materiales`:

- `Sistemas`
- `Gerencia`
- `Administración`

### Catalogo de permisos

El catalogo de permisos disponibles no vive en una tabla. Hoy esta hardcodeado en `backend/controllers/auth.controller.js` y se expone por `GET /api/permissions/available`.

Eso significa que:

- `permission_key` debe coincidir con una clave conocida por backend y frontend
- agregar un permiso nuevo requiere cambio de codigo, no solo insercion en BD

## Tablas involucradas

### 1. `usuarios_sistema`

Tabla principal de usuarios del sistema.

### Columnas usadas por el codigo

| Columna | Uso |
| --- | --- |
| `id` | Identificador del usuario |
| `username` | Login unico |
| `password_hash` | Hash SHA-256 de la contrasena |
| `email` | Correo de contacto |
| `nombre_completo` | Nombre mostrado en la UI y trazabilidad |
| `departamento` | Departamento del usuario |
| `cargo` | Puesto del usuario |
| `activo` | Habilita o bloquea el acceso al sistema |
| `intentos_fallidos` | Conteo de intentos fallidos |
| `bloqueado_hasta` | Fecha/hora hasta la cual el usuario queda bloqueado |
| `ultimo_acceso` | Ultimo acceso registrado |
| `fecha_creacion` | Fecha de alta del usuario |

### Operaciones observadas

- `SELECT` por `username` para login
- `SELECT` por `id` para verify y gestion de usuarios
- `INSERT` para crear usuarios
- `UPDATE` para:
  - reiniciar intentos
  - bloquear temporalmente
  - cambiar password
  - activar/desactivar
  - actualizar perfil
  - registrar ultimo acceso

### 2. `user_permissions_materiales`

Tabla de asignacion de permisos por usuario.

### Columnas usadas por el codigo

| Columna | Uso |
| --- | --- |
| `user_id` | Usuario al que pertenece el permiso |
| `permission_key` | Clave del permiso |
| `enabled` | Bandera de permiso habilitado |

### Operaciones observadas

- `SELECT permission_key, enabled WHERE user_id = ?`
- `DELETE WHERE user_id = ?` antes de guardar una nueva configuracion
- `INSERT IGNORE` de los permisos habilitados

### 3. Catalogos expuestos por API, pero no como tablas

Estos datos participan en la gestion de usuarios, pero no salen de BD:

| Recurso | Fuente actual |
| --- | --- |
| `GET /api/departments` | Array hardcodeado en backend |
| `GET /api/cargos` | Array hardcodeado en backend |
| `GET /api/permissions/available` | Array hardcodeado en backend |

`departamento` y `cargo` se guardan como texto dentro de `usuarios_sistema`; no hay tabla relacional para esos catalogos en el repo actual.

## Relaciones

### Relacion principal

```text
usuarios_sistema
  id (PK)
    |
    | 1 a N
    v
user_permissions_materiales
  user_id
  permission_key
  enabled
```

### Interpretacion

- Un usuario puede tener muchos permisos.
- Cada fila de `user_permissions_materiales` representa un permiso asignado a un usuario.
- El proyecto usa esta relacion de forma logica por `user_id`.
- No hay en el repo un DDL versionado que confirme una `FOREIGN KEY` fisica para esta tabla.

### Relacion con el catalogo de permisos

```text
user_permissions_materiales.permission_key
    |
    | coincide por nombre
    v
catalogo hardcodeado en GET /api/permissions/available
```

Esto no es una relacion SQL. Es una relacion por convencion de nombre entre BD y codigo.

### Relacion con la UI

```text
usuarios_sistema + user_permissions_materiales
    |
    v
AuthService.hasPermission(...)
    |
    v
AuthService.canView... / canWrite...
    |
    v
Tabs, botones y acciones visibles en MainTabbedScreen y pantallas de modulo
```

Ejemplos:

- `manage_users` habilita el tab de administracion de usuarios
- `view_warehousing` habilita el modulo de entradas
- `write_outgoing` habilita captura y edicion de salidas

### Relaciones indirectas con otras tablas

El sistema reutiliza la identidad del usuario en tablas operativas, pero casi siempre como trazabilidad, no como autentificacion directa.

Patrones actuales:

- Por nombre de usuario o nombre completo:
  - `usuario_registro`
  - `created_by`
  - `returned_by`
  - `usuario_reingreso`
  - `scanned_by`
- Por id de usuario en algunos modulos:
  - `iqc_inspection_lot.inspector_id`
  - `material_return.returned_by_id`
  - `cancellation_requests.requested_by_id`
  - `cancellation_requests.reviewed_by_id`

Importante:

- en el repo no se observa que esas referencias tengan `FOREIGN KEY` hacia `usuarios_sistema`
- por lo tanto son relaciones de trazabilidad, no garantias relacionales fuertes

## Endpoints relacionados

| Endpoint | Proposito |
| --- | --- |
| `POST /api/auth/login` | Autenticar usuario |
| `POST /api/auth/logout` | Cerrar sesion |
| `GET /api/auth/verify/:userId` | Verificar usuario activo para restaurar sesion |
| `GET /api/users` | Listar usuarios |
| `GET /api/users/:id` | Obtener usuario |
| `POST /api/users` | Crear usuario |
| `PUT /api/users/:id` | Actualizar usuario |
| `PUT /api/users/:id/password` | Cambiar password por administracion |
| `POST /api/users/:id/change-password` | Cambiar password propia |
| `PUT /api/users/:id/toggle-active` | Activar o desactivar usuario |
| `GET /api/users/:id/permissions` | Leer permisos asignados |
| `PUT /api/users/:id/permissions` | Reemplazar permisos asignados |
| `GET /api/departments` | Catalogo de departamentos |
| `GET /api/cargos` | Catalogo de cargos |
| `GET /api/permissions/available` | Catalogo de permisos disponibles |

## Limitaciones actuales

1. El repo no incluye un schema versionado para `usuarios_sistema` ni `user_permissions_materiales`; su estructura se infiere del codigo y de ejemplos de uso.
2. `verify` valida usuario activo, pero no valida un token ni una sesion persistida en servidor.
3. La expiracion de sesion depende del reloj y almacenamiento local del cliente.
4. El catalogo de permisos, departamentos y cargos esta hardcodeado en backend.

## Recomendacion de lectura cruzada

- `lib/core/services/auth_service.dart`
- `backend/controllers/auth.controller.js`
- `lib/screens/main_tabbed_screen.dart`
- `lib/screens/user_management/user_management_screen.dart`
