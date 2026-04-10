import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/shipping_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/optimistic_update_service.dart';
import '../../models/box_id_entry.dart';
import '../../models/mock_data.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/connection_indicator.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../scan/scan_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

/// Pantalla principal con navegación inferior (Mockup).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeTabDefinition {
  final String id;
  final Widget screen;
  final NavigationDestination destination;

  const _HomeTabDefinition({
    required this.id,
    required this.screen,
    required this.destination,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<_HomeTabDefinition> _availableTabs() {
    final tabs = <_HomeTabDefinition>[];
    final hasOperationalAccess = AuthService.hasMobileOperationalAccess;

    if (!hasOperationalAccess) {
      tabs.add(
        const _HomeTabDefinition(
          id: 'no_access',
          screen: _NoPermissionsTab(),
          destination: NavigationDestination(
            icon: Icon(Icons.lock_outline_rounded),
            selectedIcon: Icon(Icons.lock_rounded),
            label: 'Acceso',
          ),
        ),
      );
    }

    if (AuthService.canViewDashboard) {
      tabs.add(
        const _HomeTabDefinition(
          id: 'dashboard',
          screen: _DashboardTab(),
          destination: NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Inicio',
          ),
        ),
      );
    }

    if (AuthService.canViewHistory) {
      tabs.add(
        const _HomeTabDefinition(
          id: 'history',
          screen: HistoryScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Historial',
          ),
        ),
      );
    }

    if (AuthService.canViewSettings) {
      tabs.add(
        const _HomeTabDefinition(
          id: 'settings',
          screen: SettingsScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ),
      );
    }

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabs = _availableTabs();
    final selectedIndex = _currentIndex >= tabs.length ? 0 : _currentIndex;
    final showNavigation = tabs.length > 1 || tabs.first.id != 'no_access';

    return Scaffold(
      body: tabs[selectedIndex].screen,
      bottomNavigationBar: showNavigation
          ? Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _currentIndex = index),
                destinations: tabs.map((tab) => tab.destination).toList(),
              ),
            )
          : null,
    );
  }
}

/// Tab del Dashboard principal.
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  bool _isLoading = true;
  List<BoxIdEntry> _recentScans = [];
  int _pendingSync = 0;
  StreamSubscription<int>? _pendingSyncSubscription;

  @override
  void initState() {
    super.initState();
    _pendingSyncSubscription = OptimisticUpdateService.pendingCountStream.listen((
      count,
    ) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingSync = count;
      });
    });
    _loadData();
    // Iniciar monitoreo de conectividad
    ConnectivityService.startMonitoring();
  }

  @override
  void dispose() {
    _pendingSyncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    // 1. Cargar desde caché primero (instantáneo)
    final cachedHistory = _filterVisibleHistory(CacheService.getHistory());

    if (cachedHistory.isNotEmpty) {
      setState(() {
        _recentScans = cachedHistory;
        _isLoading = false;
      });
    }

    // 2. Actualizar pendientes de sync
    setState(() {
      _pendingSync = OptimisticUpdateService.pendingOperations.length;
    });

    // 3. Refrescar desde servidor en background
    await _refreshFromServer();
  }

  Future<void> _refreshFromServer() async {
    // Si estamos usando mock, usar datos mock
    if (AuthService.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _recentScans = _filterVisibleHistory(MockData.recentScans);
        _isLoading = false;
      });
      CacheService.setHistory(_recentScans);
      return;
    }

    // Llamar API real
    try {
      final historyResult = await ShippingService.getHistory(limit: 10);

      if (mounted) {
        setState(() {
          _recentScans = _filterVisibleHistory(historyResult);
          _isLoading = false;
        });

        CacheService.setHistory(_recentScans);
      }
    } catch (e) {
      // Si falla, mantener datos de caché/mock
      if (mounted && _isLoading) {
        setState(() {
          _recentScans = _filterVisibleHistory(MockData.recentScans);
          _isLoading = false;
        });
      }
    }
  }

  List<BoxIdEntry> _filterVisibleHistory(List<BoxIdEntry>? entries) {
    if (entries == null) {
      return const [];
    }

    return entries
        .where(
          (entry) => entry.status == MovementType.materialReturn,
        )
        .toList();
  }

  Future<void> _onRefresh() async {
    // Sincronizar pendientes
    await OptimisticUpdateService.syncAllPending();
    // Refrescar datos
    await _refreshFromServer();
    // Actualizar contador de pendientes
    setState(() {
      _pendingSync = OptimisticUpdateService.pendingOperations.length;
    });
  }

  void _refreshLocalHistoryFromCache() {
    setState(() {
      _recentScans = _filterVisibleHistory(CacheService.getHistory());
      _pendingSync = OptimisticUpdateService.pendingOperations.length;
    });
  }

  String _getGreeting() {
    final user = AuthService.currentUser;
    final name = user?.fullName ?? 'Operador';
    return 'Hola, $name';
  }

  String _getDateShift() {
    final now = DateTime.now();
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    final user = AuthService.currentUser;
    final department = user?.department.isNotEmpty == true
        ? user!.department
        : 'Registro móvil';
    return '${now.day} ${months[now.month - 1]}, ${now.year} • $department';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canWriteEntries = AuthService.canWriteEntries;
    final canViewHistory = AuthService.canViewHistory;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: const _EntriesHeaderBar(),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Banner de sincronización pendiente ──
            if (_pendingSync > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SyncPendingBanner(
                  count: _pendingSync,
                  onRetry: _onRefresh,
                ),
              ),

            // ── Bienvenida ──
            Text(_getGreeting(), style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              _getDateShift(),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            if (canWriteEntries) ...[
              const SectionHeader(title: 'Registrar retorno'),
              const SizedBox(height: 10),
              ReturnScanForm(
                embedded: true,
                onRegistered: _refreshLocalHistoryFromCache,
              ),
              const SizedBox(height: 24),
            ],

            if (canViewHistory) ...[
              SectionHeader(
                title: 'Últimos retornos',
                actionLabel: 'Ver todo',
                onAction: () =>
                    Navigator.pushNamed(context, AppConstants.historyRoute),
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const ScanListShimmer(itemCount: 3)
              else if (_recentScans.isEmpty)
                _EmptyStateCard(isDark: isDark)
              else
                ..._recentScans.take(4).map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ScanEntryCard(
                          entry: entry,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppConstants.scanResultRoute,
                            arguments: ScanResultArguments(
                              boxId: entry.boxId,
                              status: entry.status,
                              scannedAt: entry.scannedAt,
                              partNumber: entry.partNumber,
                              quantity: entry.quantity,
                              rawCode: entry.rawCode,
                              detail: entry.detail,
                              notes: entry.notes,
                              compactDetailView: true,
                            ),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoPermissionsTab extends StatelessWidget {
  const _NoPermissionsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: const _EntriesHeaderBar(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_person_rounded,
                size: 56,
                color: isDark ? AppColors.darkWarning : AppColors.lightWarning,
              ),
              const SizedBox(height: 16),
              Text(
                'Sin permisos asignados',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tu usuario no tiene permisos para registrar o consultar retornos en la app móvil.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntriesHeaderBar extends StatelessWidget {
  const _EntriesHeaderBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Stack(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: _EntriesHeaderLogo(),
            ),
            const Positioned.fill(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 72),
                  child: _EntriesHeaderBrand(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ConnectionIndicator(compact: true),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntriesHeaderLogo extends StatelessWidget {
  const _EntriesHeaderLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'LOGO.png',
      height: 28,
      fit: BoxFit.contain,
    );
  }
}

class _EntriesHeaderBrand extends StatelessWidget {
  const _EntriesHeaderBrand();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Retornos',
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 0.9,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          'Almacén de Embarques',
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.darkTextSecondary.withValues(alpha: 0.92),
            height: 0.95,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Banner de sincronización pendiente.
class _SyncPendingBanner extends StatelessWidget {
  final int count;
  final VoidCallback? onRetry;

  const _SyncPendingBanner({required this.count, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkInfo : AppColors.lightInfo;
    final bgColor = isDark ? AppColors.darkInfoSoft : AppColors.lightInfoSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count registro${count > 1 ? 's' : ''} pendiente${count > 1 ? 's' : ''} de sincronizar',
              style: TextStyle(fontSize: 13, color: color),
            ),
          ),
          if (onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Estado vacío cuando no hay escaneos.
class _EmptyStateCard extends StatelessWidget {
  final bool isDark;

  const _EmptyStateCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin retornos hoy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Los retornos aparecerán aquí',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
