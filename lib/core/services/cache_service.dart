import '../../models/box_id_entry.dart';

/// Servicio de caché en memoria para respuestas rápidas.
///
/// Estrategia: Cache-First para datos que cambian poco,
/// Network-First para datos críticos.

class CacheService {
  static final Map<String, _CacheEntry> _cache = {};
  
  /// TTL por tipo de dato
  static const Map<String, Duration> _ttlConfig = {
    'stats': Duration(minutes: 2),      // Estadísticas: refrescar cada 2 min
    'quality': Duration(minutes: 5),    // Estatus calidad: refrescar cada 5 min
    'history': Duration(minutes: 1),    // Historial: refrescar cada 1 min
    'user': Duration(hours: 1),         // Datos usuario: refrescar cada hora
  };

  /// Obtiene un valor del caché si existe y no expiró.
  static T? get<T>(String key, String type) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    final ttl = _ttlConfig[type] ?? const Duration(minutes: 5);
    if (DateTime.now().difference(entry.timestamp) > ttl) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value as T?;
  }

  /// Almacena un valor en caché.
  static void set(String key, dynamic value) {
    _cache[key] = _CacheEntry(value: value, timestamp: DateTime.now());
  }

  /// Invalida una entrada específica.
  static void invalidate(String key) {
    _cache.remove(key);
  }

  /// Invalida todo el caché de un tipo.
  static void invalidateType(String type) {
    _cache.removeWhere((key, _) => key.startsWith('$type:'));
  }

  /// Limpia todo el caché.
  static void clear() {
    _cache.clear();
  }

  // ─────────────────────────────────────────────────────────
  // Métodos de conveniencia para tipos específicos
  // ─────────────────────────────────────────────────────────

  /// Obtiene el historial de escaneos del caché.
  static List<BoxIdEntry>? getHistory() {
    return get<List<BoxIdEntry>>('history:scans', 'history');
  }

  /// Almacena el historial de escaneos en caché.
  static void setHistory(List<BoxIdEntry> entries) {
    set('history:scans', entries);
  }

  /// Obtiene las estadísticas del día del caché.
  static Map<String, dynamic>? getStats() {
    return get<Map<String, dynamic>>('stats:today', 'stats');
  }

  /// Almacena las estadísticas del día en caché.
  static void setStats(Map<String, dynamic> stats) {
    set('stats:today', stats);
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime timestamp;

  _CacheEntry({required this.value, required this.timestamp});
}
