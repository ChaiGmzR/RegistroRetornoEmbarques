import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'api_service.dart';
import 'cache_service.dart';

/// Modelo de usuario para autenticación.
class User {
  final String id;
  final String username;
  final String fullName;
  final String? email;
  final String department;
  final String cargo;
  final bool isActive;
  final List<String> permissions;

  const User({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    required this.department,
    required this.cargo,
    required this.isActive,
    this.permissions = const [],
  });

  /// Compatibilidad con vistas que todavía muestran un "turno".
  String get shift => cargo;

  /// Crea un [User] desde JSON de la API o sesión local.
  factory User.fromJson(
    Map<String, dynamic> json, {
    List<String>? permissions,
  }) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: (json['full_name'] ?? json['nombre_completo'] ?? '').toString(),
      email: json['email']?.toString(),
      department: (json['department'] ?? json['departamento'] ?? '').toString(),
      cargo: (json['cargo'] ?? json['shift'] ?? '').toString(),
      isActive:
          _parseBool(json['active'] ?? json['activo'], defaultValue: true),
      permissions: List.unmodifiable(
        permissions ?? _parsePermissions(json['permissions']),
      ),
    );
  }

  /// Convierte a JSON para persistencia local.
  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'email': email,
        'department': department,
        'cargo': cargo,
        'active': isActive,
        'permissions': permissions,
      };

  User copyWith({
    List<String>? permissions,
  }) {
    return User(
      id: id,
      username: username,
      fullName: fullName,
      email: email,
      department: department,
      cargo: cargo,
      isActive: isActive,
      permissions: permissions ?? this.permissions,
    );
  }

  static bool _parseBool(dynamic value, {required bool defaultValue}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == '1' || normalized == 'true') {
        return true;
      }
      if (normalized == '0' || normalized == 'false') {
        return false;
      }
    }
    return defaultValue;
  }

  static List<String> _parsePermissions(dynamic rawPermissions) {
    if (rawPermissions is! List) {
      return const [];
    }

    final permissions = <String>[];
    for (final permission in rawPermissions) {
      if (permission is String && permission.isNotEmpty) {
        permissions.add(permission);
        continue;
      }

      if (permission is Map<String, dynamic>) {
        final key = permission['permission_key']?.toString();
        final enabled = _parseBool(permission['enabled'], defaultValue: true);
        if (key != null && key.isNotEmpty && enabled) {
          permissions.add(key);
        }
      }
    }

    return permissions;
  }
}

/// Resultado de autenticación.
class AuthResult {
  final bool success;
  final String? error;
  final User? user;
  final int? attemptsRemaining;
  final DateTime? blockedUntil;

  const AuthResult({
    required this.success,
    this.error,
    this.user,
    this.attemptsRemaining,
    this.blockedUntil,
  });
}

/// Servicio de autenticación con persistencia de sesión local.
abstract class AuthService {
  /// Cambia a `true` para pruebas sin backend.
  static const bool useMockData = false;
  static const Set<String> _fullAccessDepartments = {
    'Sistemas',
    'Gerencia',
    'Administración',
  };

  // Catálogo compartido con la app de escritorio.
  static const String viewWarehousingPermission = 'view_warehousing';
  static const String writeWarehousingPermission = 'write_warehousing';
  static const String multiEditWarehousingPermission = 'multi_edit_warehousing';
  static const String viewOutgoingPermission = 'view_outgoing';
  static const String writeOutgoingPermission = 'write_outgoing';
  static const String viewInventoryPermission = 'view_inventory';
  static const String viewIqcPermission = 'view_iqc';
  static const String writeIqcPermission = 'write_iqc';
  static const String viewQuarantinePermission = 'view_quarantine';
  static const String sendQuarantinePermission = 'send_quarantine';
  static const String releaseQuarantinePermission = 'release_quarantine';
  static const String viewBlacklistPermission = 'view_blacklist';
  static const String writeBlacklistPermission = 'write_blacklist';
  static const String manageUsersPermission = 'manage_users';
  static const String viewReportsPermission = 'view_reports';
  static const String exportDataPermission = 'export_data';
  static const String approveCancellationPermission = 'approve_cancellation';
  static const String viewMaterialReturnPermission = 'view_material_return';
  static const String writeMaterialReturnPermission = 'write_material_return';
  static const String viewRequirementsPermission = 'view_requirements';
  static const String writeRequirementsPermission = 'write_requirements';
  static const String approveRequirementsPermission = 'approve_requirements';
  static const String viewReentryPermission = 'view_reentry';
  static const String writeReentryPermission = 'write_reentry';
  static const String viewPendingExitsPermission = 'view_pending_exits';
  static const String writePendingExitsPermission = 'write_pending_exits';
  static const String viewAuditPermission = 'view_audit';
  static const String startAuditPermission = 'start_audit';
  static const String scanAuditPermission = 'scan_audit';
  static const String viewMasterLabelsPermission = 'view_master_labels';
  static const String writeMasterLabelsPermission = 'write_master_labels';
  static const String viewWarehouseMapPermission = 'view_warehouse_map';
  static const String createWarehouseZonesPermission = 'create_warehouse_zones';
  static const String editWarehouseLocationsPermission =
      'edit_warehouse_locations';
  static const String manageWarehouseLayoutPermission =
      'manage_warehouse_layout';

  static const List<String> allPermissionKeys = [
    viewWarehousingPermission,
    writeWarehousingPermission,
    multiEditWarehousingPermission,
    viewOutgoingPermission,
    writeOutgoingPermission,
    viewInventoryPermission,
    viewIqcPermission,
    writeIqcPermission,
    viewQuarantinePermission,
    sendQuarantinePermission,
    releaseQuarantinePermission,
    viewBlacklistPermission,
    writeBlacklistPermission,
    manageUsersPermission,
    viewReportsPermission,
    exportDataPermission,
    approveCancellationPermission,
    viewMaterialReturnPermission,
    writeMaterialReturnPermission,
    viewRequirementsPermission,
    writeRequirementsPermission,
    approveRequirementsPermission,
    viewReentryPermission,
    writeReentryPermission,
    viewPendingExitsPermission,
    writePendingExitsPermission,
    viewAuditPermission,
    startAuditPermission,
    scanAuditPermission,
    viewMasterLabelsPermission,
    writeMasterLabelsPermission,
    viewWarehouseMapPermission,
    createWarehouseZonesPermission,
    editWarehouseLocationsPermission,
    manageWarehouseLayoutPermission,
  ];

  static const Duration _sessionDuration = Duration(hours: 24);
  static const String _userSessionKey = 'user_session';
  static const String _sessionStartTimeKey = 'session_start_time';

  static User? _currentUser;

  /// Usuario actualmente autenticado.
  static User? get currentUser => _currentUser;

  /// Estado de autenticación actual.
  static bool get isAuthenticated => _currentUser != null;

  /// Permisos cargados del usuario actual.
  static List<String> get currentPermissions =>
      _currentUser?.permissions ?? const [];

  static bool hasPermission(String permissionKey) {
    if (!isAuthenticated) {
      return false;
    }
    if (hasFullAccess) {
      return true;
    }
    return currentPermissions.contains(permissionKey);
  }

  static bool hasAnyPermission(Iterable<String> permissionKeys) {
    for (final permissionKey in permissionKeys) {
      if (hasPermission(permissionKey)) {
        return true;
      }
    }
    return false;
  }

  static bool get hasFullAccess {
    final department = _currentUser?.department;
    if (department == null) {
      return false;
    }
    return _fullAccessDepartments.contains(department.trim());
  }

  static bool get canViewWarehousing =>
      hasPermission(viewWarehousingPermission);

  static bool get canWriteWarehousing =>
      hasPermission(writeWarehousingPermission);

  static bool get canMultiEditWarehousing =>
      hasPermission(multiEditWarehousingPermission);

  static bool get canViewOutgoing => hasPermission(viewOutgoingPermission);

  static bool get canWriteOutgoing => hasPermission(writeOutgoingPermission);

  static bool get canViewInventory => hasPermission(viewInventoryPermission);

  static bool get canViewIqc => hasPermission(viewIqcPermission);

  static bool get canWriteIqc => hasPermission(writeIqcPermission);

  static bool get canViewQuarantine => hasPermission(viewQuarantinePermission);

  static bool get canSendToQuarantine =>
      hasPermission(sendQuarantinePermission);

  static bool get canWriteQuarantine =>
      hasPermission(releaseQuarantinePermission);

  static bool get canViewBlacklist => hasPermission(viewBlacklistPermission);

  static bool get canWriteBlacklist => hasPermission(writeBlacklistPermission);

  static bool get canManageUsers => hasPermission(manageUsersPermission);

  static bool get canViewReports => hasPermission(viewReportsPermission);

  static bool get canExportData => hasPermission(exportDataPermission);

  static bool get canApproveCancellation =>
      hasPermission(approveCancellationPermission);

  static bool get canViewMaterialReturn =>
      hasPermission(viewMaterialReturnPermission);

  static bool get canWriteMaterialReturn =>
      hasPermission(writeMaterialReturnPermission);

  static bool get canViewRequirements =>
      hasPermission(viewRequirementsPermission);

  static bool get canWriteRequirements =>
      hasPermission(writeRequirementsPermission);

  static bool get canApproveRequirements =>
      hasPermission(approveRequirementsPermission);

  static bool get canViewReentry => hasPermission(viewReentryPermission);

  static bool get canWriteReentry => hasPermission(writeReentryPermission);

  static bool get canViewPendingExits =>
      hasPermission(viewPendingExitsPermission);

  static bool get canWritePendingExits =>
      hasPermission(writePendingExitsPermission);

  static bool get canViewAudit => hasPermission(viewAuditPermission);

  static bool get canManageAudit => hasPermission(startAuditPermission);

  static bool get canScanAudit => hasPermission(scanAuditPermission);

  static bool get canViewMasterLabels =>
      hasPermission(viewMasterLabelsPermission);

  static bool get canWriteMasterLabels =>
      hasPermission(writeMasterLabelsPermission);

  static bool get canViewWarehouseMap =>
      hasPermission(viewWarehouseMapPermission);

  static bool get canCreateWarehouseZones => hasAnyPermission(
        [
          createWarehouseZonesPermission,
          manageWarehouseLayoutPermission,
        ],
      );

  static bool get canEditWarehouseLocations => hasAnyPermission(
        [
          editWarehouseLocationsPermission,
          manageWarehouseLayoutPermission,
        ],
      );

  static bool get canManageWarehouseLayout =>
      canCreateWarehouseZones || canEditWarehouseLocations;

  // Aliases para la app móvil de retornos.
  static bool get canViewDashboard => hasAnyPermission(
        [
          viewInventoryPermission,
          viewMaterialReturnPermission,
          writeMaterialReturnPermission,
        ],
      );

  static bool get canWriteEntries => canWriteMaterialReturn;

  static bool get canWriteExits => false;

  static bool get canViewHistory => hasAnyPermission(
        [
          viewMaterialReturnPermission,
          writeMaterialReturnPermission,
        ],
      );

  static bool get canViewSettings => isAuthenticated;

  static bool get hasMobileOperationalAccess =>
      canViewDashboard || canWriteEntries || canViewHistory;

  /// Restaura la sesión local si sigue vigente.
  static Future<bool> restoreSession() async {
    if (useMockData) {
      return _restoreMockSession();
    }

    final prefs = await SharedPreferences.getInstance();
    final userSession = prefs.getString(_userSessionKey);
    final sessionStartTime = prefs.getString(_sessionStartTimeKey);

    if (userSession == null || sessionStartTime == null) {
      await _clearLocalSession(prefs: prefs);
      return false;
    }

    final storedAt = DateTime.tryParse(sessionStartTime);
    if (storedAt == null ||
        DateTime.now().difference(storedAt) > _sessionDuration) {
      await _clearLocalSession(prefs: prefs);
      return false;
    }

    try {
      final storedUser = User.fromJson(
        jsonDecode(userSession) as Map<String, dynamic>,
      );

      if (storedUser.id.isEmpty) {
        await _clearLocalSession(prefs: prefs);
        return false;
      }

      final verifyResponse = await ApiService.get(
        '${ApiConfig.verifySessionEndpoint}/${storedUser.id}',
      );

      final verifiedUserData = verifyResponse.data?['user'];
      final isValid = verifyResponse.success &&
          verifiedUserData is Map<String, dynamic> &&
          (verifyResponse.data?['valid'] != false);

      if (!isValid) {
        await _clearLocalSession(prefs: prefs);
        return false;
      }

      final permissions = await _loadPermissions(storedUser.id);
      final verifiedUser = User.fromJson(
        verifiedUserData,
        permissions: permissions,
      );

      _currentUser = verifiedUser;
      await _persistSession(verifiedUser,
          prefs: prefs, sessionStartedAt: storedAt);
      return true;
    } catch (_) {
      await _clearLocalSession(prefs: prefs);
      return false;
    }
  }

  /// Realiza autenticación interactiva.
  static Future<AuthResult> login(String username, String password) async {
    if (useMockData) {
      return _mockLogin(username, password);
    }
    return _apiLogin(username, password);
  }

  /// Login contra la API real del backend.
  static Future<AuthResult> _apiLogin(String username, String password) async {
    final response = await ApiService.post(
      ApiConfig.loginEndpoint,
      body: {
        'username': username,
        'password': password,
      },
    );

    if (!response.success) {
      return AuthResult(
        success: false,
        error: response.error ?? 'Error de autenticación',
        attemptsRemaining: _parseAttemptsRemaining(response.data),
        blockedUntil: _parseBlockedUntil(response.data),
      );
    }

    final data = response.data;
    final userData = data?['user'];
    if (userData is! Map<String, dynamic>) {
      return const AuthResult(
        success: false,
        error: 'Respuesta inválida del servidor',
      );
    }

    final userId = userData['id']?.toString() ?? '';
    final permissions = await _loadPermissions(userId);
    final user = User.fromJson(userData, permissions: permissions);

    _currentUser = user;
    ApiService.clearAuthToken();
    await _persistSession(user);

    return AuthResult(
      success: true,
      user: user,
    );
  }

  /// Login con datos mock para desarrollo.
  static Future<AuthResult> _mockLogin(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final user = _mockUsers.firstWhere(
      (item) => item.username == username,
      orElse: () => _nullUser,
    );

    if (user == _nullUser || (password != username && password != 'admin123')) {
      return const AuthResult(
        success: false,
        error: 'Usuario o contraseña incorrectos',
      );
    }

    _currentUser = user;
    await _persistSession(user);

    return AuthResult(
      success: true,
      user: user,
    );
  }

  /// Cierra la sesión local y notifica al backend.
  static Future<void> logout() async {
    final userId = _currentUser?.id;

    try {
      if (!useMockData && userId != null && userId.isNotEmpty) {
        await ApiService.post(
          ApiConfig.logoutEndpoint,
          body: {'userId': userId},
        );
      }
    } finally {
      await _clearLocalSession();
    }
  }

  static Future<List<String>> _loadPermissions(String userId) async {
    if (userId.isEmpty) {
      return const [];
    }

    final response = await ApiService.get(
      '${ApiConfig.usersEndpoint}/$userId/permissions',
    );

    if (!response.success || response.data == null) {
      return const [];
    }

    final data = response.data!;
    final enabledPermissions = data['enabledPermissions'];
    if (enabledPermissions is List) {
      return enabledPermissions
          .map((permission) => permission.toString())
          .where((permission) => permission.isNotEmpty)
          .toList();
    }

    final permissions = data['permissions'];
    if (permissions is List) {
      return permissions
          .whereType<Map<String, dynamic>>()
          .where((permission) =>
              User._parseBool(permission['enabled'], defaultValue: true))
          .map((permission) => permission['permission_key']?.toString() ?? '')
          .where((permission) => permission.isNotEmpty)
          .toList();
    }

    return const [];
  }

  static int? _parseAttemptsRemaining(Map<String, dynamic>? data) {
    final attempts = data?['intentosRestantes'];
    if (attempts is int) {
      return attempts;
    }
    if (attempts is String) {
      return int.tryParse(attempts);
    }
    return null;
  }

  static DateTime? _parseBlockedUntil(Map<String, dynamic>? data) {
    final blockedUntil = data?['blockedUntil']?.toString();
    if (blockedUntil == null || blockedUntil.isEmpty) {
      return null;
    }
    return DateTime.tryParse(blockedUntil);
  }

  static Future<void> _persistSession(
    User user, {
    SharedPreferences? prefs,
    DateTime? sessionStartedAt,
  }) async {
    final sharedPrefs = prefs ?? await SharedPreferences.getInstance();
    await sharedPrefs.setString(_userSessionKey, jsonEncode(user.toJson()));
    await sharedPrefs.setString(
      _sessionStartTimeKey,
      (sessionStartedAt ?? DateTime.now()).toIso8601String(),
    );
  }

  static Future<void> _clearLocalSession({
    SharedPreferences? prefs,
  }) async {
    final sharedPrefs = prefs ?? await SharedPreferences.getInstance();
    await sharedPrefs.remove(_userSessionKey);
    await sharedPrefs.remove(_sessionStartTimeKey);
    ApiService.clearAuthToken();
    CacheService.clear();
    _currentUser = null;
  }

  static Future<bool> _restoreMockSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userSession = prefs.getString(_userSessionKey);
    final sessionStartTime = prefs.getString(_sessionStartTimeKey);

    if (userSession == null || sessionStartTime == null) {
      await _clearLocalSession(prefs: prefs);
      return false;
    }

    final storedAt = DateTime.tryParse(sessionStartTime);
    if (storedAt == null ||
        DateTime.now().difference(storedAt) > _sessionDuration) {
      await _clearLocalSession(prefs: prefs);
      return false;
    }

    try {
      _currentUser = User.fromJson(
        jsonDecode(userSession) as Map<String, dynamic>,
      );
      return _currentUser != null;
    } catch (_) {
      await _clearLocalSession(prefs: prefs);
      return false;
    }
  }

  static const List<String> _defaultMockPermissions = [
    viewWarehousingPermission,
    writeWarehousingPermission,
  ];

  static final List<User> _mockUsers = [
    const User(
      id: '1247',
      username: '1247',
      fullName: 'Operador 1247',
      department: 'Almacén de Embarques',
      cargo: 'Operador de Embarques',
      isActive: true,
      permissions: _defaultMockPermissions,
    ),
    const User(
      id: '1248',
      username: '1248',
      fullName: 'Operador 1248',
      department: 'Almacén de Embarques',
      cargo: 'Supervisor de Embarques',
      isActive: true,
      permissions: _defaultMockPermissions,
    ),
    const User(
      id: '1249',
      username: '1249',
      fullName: 'Inspector 1249',
      department: 'Calidad',
      cargo: 'Inspector de Calidad',
      isActive: true,
      permissions: [
        viewIqcPermission,
        writeIqcPermission,
      ],
    ),
    const User(
      id: '1',
      username: 'admin',
      fullName: 'Administrador Sistema',
      department: 'Sistemas',
      cargo: 'Administrador',
      isActive: true,
      permissions: [
        ..._defaultMockPermissions,
        manageUsersPermission,
      ],
    ),
  ];

  static const User _nullUser = User(
    id: '',
    username: '',
    fullName: '',
    department: '',
    cargo: '',
    isActive: false,
  );
}
