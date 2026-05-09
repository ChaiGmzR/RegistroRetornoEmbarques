enum ApiEnvironment {
  localEmulator,
  localLan,
  production,
}

/// Configuración de la API del backend MES.
///
/// IMPORTANTE: En producción, estas URLs deben venir de variables de entorno
/// o configuración remota, NO hardcodeadas.
abstract class ApiConfig {
  /// Cambia este valor según dónde quieras apuntar la app.
  ///
  /// - `localEmulator`: Android Emulator usando 10.0.2.2
  /// - `localLan`: dispositivo físico en la misma red WiFi
  /// - `production`: backend local en Windows Server
  static const ApiEnvironment environment = ApiEnvironment.production;

  /// URL local para Android Emulator.
  static const String _localEmulatorBaseUrl =
      'http://10.0.2.2:5000/api/shipping';

  /// URL local para dispositivo físico en la LAN.
  /// Servidor local MES en Windows Server.
  static const String _localLanBaseUrl =
      'http://192.168.1.10/api/shipping';

  /// URL del backend MES en servidor local.
  static const String _productionBaseUrl =
      'http://192.168.1.10/api/shipping';

  static String get baseUrl {
    switch (environment) {
      case ApiEnvironment.localEmulator:
        return _localEmulatorBaseUrl;
      case ApiEnvironment.localLan:
        return _localLanBaseUrl;
      case ApiEnvironment.production:
        return _productionBaseUrl;
    }
  }

  static Uri get baseUri => Uri.parse(baseUrl);

  static String get connectivityHost => baseUri.host;

  static String get healthCheckUrl => baseUri
      .replace(
        path: '/api/health',
        queryParameters: null,
        fragment: null,
      )
      .toString();

  /// Timeout para requests HTTP (en segundos)
  static const int timeoutSeconds = 30;

  /// Endpoints de autenticación
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String verifySessionEndpoint = '/auth/verify';
  static const String usersEndpoint = '/users';
  static const String permissionsAvailableEndpoint = '/permissions/available';
  static const String departmentsEndpoint = '/departments';
  static const String cargosEndpoint = '/cargos';

  /// Endpoints de calidad
  static const String qualityEndpoint = '/quality';

  /// Endpoints de embarques
  static const String shippingEntriesEndpoint = '/entries';
  static const String shippingStatsEndpoint = '/stats';

  /// Endpoints compartidos de inventario/embarques.
  static const String materialBaseEndpoint = '/material';
  static const String materialEntriesEndpoint = '$materialBaseEndpoint/entries';
  static const String materialExitsEndpoint = '$materialBaseEndpoint/exits';
  static const String materialReturnsEndpoint = '$materialBaseEndpoint/returns';
  static const String materialInventoryEndpoint =
      '$materialBaseEndpoint/inventory';
  static const String materialStatsEndpoint = '$materialBaseEndpoint/stats';
  static const String materialCatalogImportEndpoint =
      '$materialBaseEndpoint/catalog/import';
}
