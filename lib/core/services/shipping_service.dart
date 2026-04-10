import '../config/api_config.dart';
import '../../models/box_id_entry.dart';
import 'api_service.dart';

/// Resultado de consulta de calidad.
class QualityCheckResult {
  final bool success;
  final BoxIdEntry? entry;
  final String? error;

  const QualityCheckResult({
    required this.success,
    this.entry,
    this.error,
  });
}

/// Resultado genérico de registro de movimiento.
class RegisterMovementResult {
  final bool success;
  final int? movementId;
  final String? folio;
  final String? error;
  final String? message;
  final int statusCode;

  const RegisterMovementResult({
    required this.success,
    this.movementId,
    this.folio,
    this.error,
    this.message,
    required this.statusCode,
  });

  bool get isConnectionError => statusCode == 0;
}

/// Estadísticas operativas del día.
class DailyStats {
  final int total;
  final int entries;
  final int exits;
  final int returns;
  final int inventoryItems;
  final int inventoryQuantity;

  const DailyStats({
    required this.total,
    required this.entries,
    required this.exits,
    required this.returns,
    required this.inventoryItems,
    required this.inventoryQuantity,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      total: _parseInt(json['total']),
      entries: _parseInt(json['entries']),
      exits: _parseInt(json['exits']),
      returns: _parseInt(json['returns']),
      inventoryItems: _parseInt(json['inventory_items']),
      inventoryQuantity: _parseInt(json['inventory_quantity']),
    );
  }

  factory DailyStats.empty() => const DailyStats(
        total: 0,
        entries: 0,
        exits: 0,
        returns: 0,
        inventoryItems: 0,
        inventoryQuantity: 0,
      );

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// Servicio para operaciones de embarques e inventario compartido.
class ShippingService {
  static const String defaultEntryLocation = 'SIN-UBICACION';

  /// Consulta el estatus de calidad legado de un Box ID.
  static Future<QualityCheckResult> checkQualityStatus(String boxId) async {
    final response = await ApiService.get(
      '${ApiConfig.qualityEndpoint}/$boxId',
    );

    if (!response.success) {
      if (response.statusCode == 404) {
        return const QualityCheckResult(
          success: false,
          error: 'Box ID no encontrado en el sistema',
        );
      }
      return QualityCheckResult(
        success: false,
        error: response.error ?? 'Error al consultar estatus de calidad',
      );
    }

    final data = response.data;
    if (data == null) {
      return const QualityCheckResult(
        success: false,
        error: 'Respuesta vacía del servidor',
      );
    }

    try {
      final entry = BoxIdEntry(
        boxId: data['box_id']?.toString() ?? boxId,
        status: MovementType.entry,
        scannedAt: DateTime.now(),
        partNumber:
            data['part_number']?.toString() ?? data['box_id']?.toString() ?? boxId,
        quantity: _parseInt(data['quantity']),
        rawCode: data['raw_code']?.toString(),
        productName: data['product_name']?.toString(),
        lotNumber: data['lot_number']?.toString(),
      );

      return QualityCheckResult(success: true, entry: entry);
    } catch (e) {
      return QualityCheckResult(
        success: false,
        error: 'Error al procesar respuesta: $e',
      );
    }
  }

  static Future<RegisterMovementResult> registerEntry({
    required String partNumber,
    required int quantity,
    required String scannedBy,
    String? rawCode,
    String? location,
    String? notes,
    String? deviceId,
  }) async {
    final response = await ApiService.post(
      ApiConfig.materialEntriesEndpoint,
      body: {
        'partNumber': partNumber,
        'quantity': quantity,
        'location': _normalizeEntryLocation(location),
        'referenceCode': rawCode,
        'notes': notes,
        'registeredBy': scannedBy,
        'deviceId': deviceId,
        'receivedAt': DateTime.now().toIso8601String(),
      },
    );

    if (!response.success) {
      return RegisterMovementResult(
        success: false,
        error: response.error ?? 'Error al registrar entrada',
        statusCode: response.statusCode,
      );
    }

    return RegisterMovementResult(
      success: true,
      movementId: response.data?['id'] as int?,
      folio: response.data?['folio']?.toString(),
      message: response.data?['message']?.toString(),
      statusCode: response.statusCode,
    );
  }

  static Future<RegisterMovementResult> registerExit({
    required String partNumber,
    required int quantity,
    required String scannedBy,
    String? rawCode,
    String? destinationArea,
    String? reason,
    String? remarks,
  }) async {
    final response = await ApiService.post(
      ApiConfig.materialExitsEndpoint,
      body: {
        'partNumber': partNumber,
        'quantity': quantity,
        'destinationArea': destinationArea,
        'reason': reason,
        'remarks': remarks,
        'requestedBy': scannedBy,
        'registeredBy': scannedBy,
        'referenceCode': rawCode,
        'exitedAt': DateTime.now().toIso8601String(),
      },
    );

    if (!response.success) {
      return RegisterMovementResult(
        success: false,
        error: response.error ?? 'Error al registrar salida',
        statusCode: response.statusCode,
      );
    }

    return RegisterMovementResult(
      success: true,
      movementId: response.data?['id'] as int?,
      folio: response.data?['folio']?.toString(),
      message: response.data?['message']?.toString(),
      statusCode: response.statusCode,
    );
  }

  static Future<RegisterMovementResult> registerReturn({
    required String partNumber,
    required int quantity,
    required String scannedBy,
    required String returnType,
    String? rawCode,
    String? remarks,
  }) async {
    final response = await ApiService.post(
      ApiConfig.materialReturnsEndpoint,
      body: {
        'partNumber': partNumber,
        'returnQty': quantity,
        'lossQty': 0,
        'reason': returnType,
        'remarks': remarks,
        'registeredBy': scannedBy,
        'userName': scannedBy,
        'referenceCode': rawCode,
        'returnedAt': DateTime.now().toIso8601String(),
      },
    );

    if (!response.success) {
      return RegisterMovementResult(
        success: false,
        error: response.error ?? 'Error al registrar retorno',
        statusCode: response.statusCode,
      );
    }

    return RegisterMovementResult(
      success: true,
      movementId: response.data?['id'] as int?,
      folio: response.data?['folio']?.toString(),
      message: response.data?['message']?.toString(),
      statusCode: response.statusCode,
    );
  }

  /// Obtiene el historial visible para la app móvil: retornos.
  static Future<List<BoxIdEntry>> getHistory({
    MovementType? statusFilter,
    String? searchQuery,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      if (searchQuery != null && searchQuery.isNotEmpty) 'q': searchQuery,
    };

    final response = await ApiService.get(
      ApiConfig.materialReturnsEndpoint,
      queryParams: queryParams,
    );

    final history = _mapMovementList(
      response.data?['returns'] as List<dynamic>?,
      MovementType.materialReturn,
    );

    history.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

    final filtered = statusFilter == null
        ? history
        : history.where((entry) => entry.status == statusFilter).toList();

    if (filtered.length <= limit) {
      return filtered;
    }
    return filtered.take(limit).toList();
  }

  /// Obtiene las estadísticas operativas del día actual.
  static Future<DailyStats> getTodayStats() async {
    final today = DateTime.now();
    final response = await ApiService.get(
      '${ApiConfig.materialStatsEndpoint}/today',
      queryParams: {
        'date':
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
      },
    );

    if (!response.success || response.data == null) {
      return DailyStats.empty();
    }

    return DailyStats.fromJson(response.data!);
  }

  static List<BoxIdEntry> _mapMovementList(
    List<dynamic>? rows,
    MovementType type,
  ) {
    if (rows == null) {
      return const [];
    }

    return rows.whereType<Map<String, dynamic>>().map((json) {
      final partNumber = json['part_number']?.toString() ?? '';
      final quantity = _parseInt(
        json['quantity'] ?? json['return_quantity'],
      );
      final scannedAt =
          DateTime.tryParse(json['movement_at']?.toString() ?? '') ??
              DateTime.now();

      return BoxIdEntry(
        boxId: _pickString(
          json,
          ['entry_folio', 'exit_folio', 'return_folio', 'part_number'],
        ),
        status: type,
        scannedAt: scannedAt,
        partNumber: partNumber,
        quantity: quantity == 0 ? null : quantity,
        rawCode: json['reference_code']?.toString(),
        productName: json['description']?.toString(),
        lotNumber: json['batch_no']?.toString(),
        folio: _pickString(
          json,
          ['entry_folio', 'exit_folio', 'return_folio'],
        ),
        location: _pickString(
          json,
          ['location_code', 'zone_code'],
        ),
        detail: _buildDetail(type, json),
        notes: _pickString(json, ['notes', 'remarks', 'reason']),
      );
    }).toList();
  }

  static String? _buildDetail(MovementType type, Map<String, dynamic> json) {
    final quantity = _parseInt(json['quantity'] ?? json['return_quantity']);
    switch (type) {
      case MovementType.entry:
        final location = _pickString(json, ['location_code', 'zone_code']);
        if (location.isNotEmpty &&
            location.toUpperCase() != defaultEntryLocation) {
          return 'Cant: $quantity • Ubicación: $location';
        }
        return 'Cant: $quantity';
      case MovementType.exit:
        final destination = _pickString(json, ['destination_area', 'reason']);
        if (destination.isNotEmpty) {
          return 'Cant: $quantity • Destino: $destination';
        }
        return 'Cant: $quantity';
      case MovementType.materialReturn:
        final reason = _pickString(json, ['reason', 'remarks']);
        if (reason.isNotEmpty) {
          return 'Cant: $quantity • Tipo: $reason';
        }
        return 'Cant: $quantity';
      case MovementType.adjustment:
        return 'Cant: $quantity';
    }
  }

  static String _pickString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _normalizeEntryLocation(String? location) {
    final normalized = location?.trim();
    if (normalized == null || normalized.isEmpty) {
      return defaultEntryLocation;
    }
    return normalized;
  }
}
