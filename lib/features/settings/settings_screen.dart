import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/update_service.dart';
import '../../core/config/update_config.dart';
import '../../main.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/update_dialog.dart';

/// Pantalla de ajustes.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _vibrationOnScan = true;
  bool _soundOnScan = true;
  bool _autoValidate = true;
  bool _checkingUpdates = false;

  Future<void> _checkForUpdates() async {
    setState(() => _checkingUpdates = true);

    try {
      final updateInfo = await UpdateService.checkForUpdate(forceCheck: true);

      if (!mounted) return;

      if (updateInfo != null) {
        UpdateDialog.show(context, updateInfo);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                    'Estas en la ultima version (v${UpdateConfig.currentVersion})'),
              ],
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSuccess
                : AppColors.lightSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al verificar actualizaciones'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkError
              : AppColors.lightError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingUpdates = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = RegistroEmbarquesApp.of(context);
    final user = AuthService.currentUser;
    final displayName = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName
        : 'Sin sesión activa';
    final displayRole = [
      user?.department,
      user?.cargo,
    ].where((value) => value != null && value.isNotEmpty).join(' • ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Perfil ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isDark
                        ? AppColors.darkPrimary.withValues(alpha: 0.15)
                        : AppColors.lightPrimarySoft,
                    child: Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayRole.isNotEmpty
                              ? displayRole
                              : 'Sin información de perfil',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSuccessSoft
                          : AppColors.lightSuccessSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Activo',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkSuccess
                            : AppColors.lightSuccess,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Sección: Apariencia ──
          SectionHeader(title: 'Apariencia'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Modo Oscuro',
            subtitle: 'Reduce el brillo y la fatiga visual',
            trailing: Switch.adaptive(
              value: isDark,
              activeTrackColor:
                  isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              onChanged: (value) {
                appState?.toggleTheme();
              },
            ),
          ),
          const SizedBox(height: 20),

          // ── Sección: Escáner ──
          SectionHeader(title: 'Escáner'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.vibration_rounded,
            title: 'Vibración al escanear',
            subtitle: 'Retroalimentación háptica al leer un código',
            trailing: Switch.adaptive(
              value: _vibrationOnScan,
              activeTrackColor:
                  isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              onChanged: (value) => setState(() => _vibrationOnScan = value),
            ),
          ),
          _SettingsTile(
            icon: Icons.volume_up_rounded,
            title: 'Sonido al escanear',
            subtitle: 'Reproducir tono al leer un código',
            trailing: Switch.adaptive(
              value: _soundOnScan,
              activeTrackColor:
                  isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              onChanged: (value) => setState(() => _soundOnScan = value),
            ),
          ),
          _SettingsTile(
            icon: Icons.auto_awesome_rounded,
            title: 'Validación automática',
            subtitle: 'Validar estatus de calidad al escanear',
            trailing: Switch.adaptive(
              value: _autoValidate,
              activeTrackColor:
                  isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              onChanged: (value) => setState(() => _autoValidate = value),
            ),
          ),
          const SizedBox(height: 20),

          // ── Sección: Dispositivo ──
          SectionHeader(title: 'Dispositivo'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.smartphone_rounded,
            title: 'Modelo',
            subtitle: 'Zebra TC15',
            trailing: Icon(
              Icons.check_circle_rounded,
              color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
              size: 20,
            ),
          ),
          _SettingsTile(
            icon: Icons.wifi_rounded,
            title: 'Conexión',
            subtitle: 'WiFi Corporativo',
            trailing: Icon(
              Icons.signal_wifi_4_bar_rounded,
              color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
              size: 20,
            ),
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle: 'v${AppConstants.appVersion}',
          ),
          const SizedBox(height: 20),

          // ── Seccion: Actualizaciones ──
          SectionHeader(title: 'Actualizaciones'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.system_update_rounded,
            title: 'Buscar actualizaciones',
            subtitle: 'Verificar si hay una nueva version',
            trailing: _checkingUpdates
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  )
                : Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
            onTap: _checkingUpdates ? null : _checkForUpdates,
          ),
          const SizedBox(height: 28),

          // ── Cerrar sesión ──
          OutlinedButton.icon(
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppConstants.loginRoute,
                (route) => false,
              );
            },
            icon: Icon(
              Icons.logout_rounded,
              color: isDark ? AppColors.darkError : AppColors.lightError,
            ),
            label: Text(
              'Cerrar Sesión',
              style: TextStyle(
                color: isDark ? AppColors.darkError : AppColors.lightError,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? AppColors.darkError : AppColors.lightError,
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightIconPlaceholder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
