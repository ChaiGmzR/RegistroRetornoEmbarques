import 'dart:async';
import 'dart:io';
import '../config/api_config.dart';

/// Servicio para monitorear conectividad y latencia.
/// 
/// Permite a la app adaptar su comportamiento según la calidad
/// de la conexión (mostrar indicadores, usar caché, etc).
class ConnectivityService {
  static bool _isOnline = true;
  static int _latencyMs = 0;
  static ConnectionQuality _quality = ConnectionQuality.good;
  
  static final _connectivityController = StreamController<bool>.broadcast();
  static final _qualityController = StreamController<ConnectionQuality>.broadcast();

  /// Stream de cambios de conectividad.
  static Stream<bool> get onConnectivityChanged => _connectivityController.stream;
  
  /// Stream de cambios de calidad de conexión.
  static Stream<ConnectionQuality> get onQualityChanged => _qualityController.stream;

  /// Estado actual de conexión.
  static bool get isOnline => _isOnline;
  
  /// Latencia actual en ms.
  static int get latencyMs => _latencyMs;
  
  /// Calidad de conexión actual.
  static ConnectionQuality get quality => _quality;

  /// Verifica la conectividad contra el backend real de la app.
  static Future<bool> checkConnectivity({
    String? customUrl,
  }) async {
    final healthUrl = customUrl ?? ApiConfig.healthCheckUrl;
    HttpClient? client;

    try {
      final stopwatch = Stopwatch()..start();
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(Uri.parse(healthUrl));
      final response = await request.close().timeout(const Duration(seconds: 5));
      await response.drain();

      stopwatch.stop();
      _latencyMs = stopwatch.elapsedMilliseconds;
      final wasOnline = _isOnline;
      _isOnline = response.statusCode >= 200 && response.statusCode < 300;
      _updateQuality();

      if (wasOnline != _isOnline) {
        _connectivityController.add(_isOnline);
      }

      return _isOnline;
    } on SocketException {
      _setOffline();
      return false;
    } on TimeoutException {
      _setOffline();
      return false;
    } catch (e) {
      _setOffline();
      return false;
    } finally {
      client?.close(force: true);
    }
  }

  /// Mide la latencia real haciendo una request HTTP.
  static Future<int> measureLatency(String url) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      final stopwatch = Stopwatch()..start();
      
      final request = await client.headUrl(Uri.parse(url));
      final response = await request.close();
      await response.drain();
      
      stopwatch.stop();
      _latencyMs = stopwatch.elapsedMilliseconds;
      
      client.close();
      
      _updateQuality();
      return _latencyMs;
    } catch (e) {
      return -1; // Error
    }
  }

  static void _setOffline() {
    final wasOnline = _isOnline;
    _isOnline = false;
    _quality = ConnectionQuality.offline;
    
    if (wasOnline) {
      _connectivityController.add(false);
      _qualityController.add(ConnectionQuality.offline);
    }
  }

  static void _updateQuality() {
    final previousQuality = _quality;
    
    if (!_isOnline) {
      _quality = ConnectionQuality.offline;
    } else if (_latencyMs < 200) {
      _quality = ConnectionQuality.excellent;
    } else if (_latencyMs < 500) {
      _quality = ConnectionQuality.good;
    } else if (_latencyMs < 1000) {
      _quality = ConnectionQuality.fair;
    } else {
      _quality = ConnectionQuality.poor;
    }
    
    if (previousQuality != _quality) {
      _qualityController.add(_quality);
    }
  }

  /// Inicia monitoreo periódico de conectividad.
  static Timer? _monitorTimer;
  
  static void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    _monitorTimer?.cancel();
    Timer.run(checkConnectivity);
    _monitorTimer = Timer.periodic(interval, (_) => checkConnectivity());
  }

  static void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  static void dispose() {
    stopMonitoring();
    _connectivityController.close();
    _qualityController.close();
  }
}

/// Calidad de conexión.
enum ConnectionQuality {
  excellent,  // <200ms - Sin indicador
  good,       // 200-500ms - Sin indicador
  fair,       // 500-1000ms - Indicador amarillo
  poor,       // >1000ms - Indicador rojo
  offline,    // Sin conexión - Modo offline
}

extension ConnectionQualityExtension on ConnectionQuality {
  String get label {
    switch (this) {
      case ConnectionQuality.excellent:
        return 'Excelente';
      case ConnectionQuality.good:
        return 'Buena';
      case ConnectionQuality.fair:
        return 'Regular';
      case ConnectionQuality.poor:
        return 'Lenta';
      case ConnectionQuality.offline:
        return 'Sin conexión';
    }
  }

  bool get showIndicator {
    return this == ConnectionQuality.offline;
  }
}
