## 🚀 Cómo ejecutar la aplicación

### Usuarios de prueba disponibles:

| Usuario | Contraseña | Rol |
|---------|-----------|-----|
| `1247` | `1247` | Operador Turno A |
| `1248` | `1248` | Operador Turno B |
| `1249` | `1249` | Revisor de Calidad |
| `admin` | `admin123` | Administrador |

### Comando para ejecutar:

```bash
flutter run
```

### Pantallas disponibles:

1. **Login** - Autenticación con las credenciales de arriba
2. **Dashboard** - Resumen del día con última actividad
3. **Escanear** - Simulador de escaneo (botón "Simular Escaneo")
4. **Historial** - Registro con búsqueda y filtros
5. **Ajustes** - Configuración y toggle de tema dark/light

### Navegación:

- Usa la **barra inferior** para cambiar entre pantallas
- El login valida **automáticamente** las credenciales
- Si falla el login, se muestra un **mensaje de error**
- Puedes **cambiar tema** desde la pantalla de Ajustes

### Archivos clave para autenticación:

- [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart) - Servicio de login
- [lib/features/login/login_screen.dart](lib/features/login/login_screen.dart) - Pantalla de login
