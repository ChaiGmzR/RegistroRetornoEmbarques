import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Excepción personalizada para errores de API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Resultado genérico de una llamada API.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });
}

/// Servicio base para comunicación HTTP con el backend MES.
class ApiService {
  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: ApiConfig.timeoutSeconds);

  static String? _authToken;

  /// Establece el token de autenticación para requests subsecuentes.
  static void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Obtiene el token actual.
  static String? get authToken => _authToken;

  /// Limpia el token (logout).
  static void clearAuthToken() {
    _authToken = null;
  }

  /// Realiza una petición GET.
  static Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final request = await _client.getUrl(uri);
      _addHeaders(request);

      final response = await request.close();
      return _processResponse(response, uri);
    } on SocketException {
      return const ApiResponse(
        success: false,
        error: 'Sin conexión a internet. Verifica tu red WiFi.',
        statusCode: 0,
      );
    } on HttpException catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error de conexión: ${e.message}',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error inesperado: $e',
        statusCode: 0,
      );
    }
  }

  /// Realiza una petición POST.
  static Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final request = await _client.postUrl(uri);
      _addHeaders(request);

      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      return _processResponse(response, uri);
    } on SocketException {
      return const ApiResponse(
        success: false,
        error: 'Sin conexión a internet. Verifica tu red WiFi.',
        statusCode: 0,
      );
    } on HttpException catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error de conexión: ${e.message}',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error inesperado: $e',
        statusCode: 0,
      );
    }
  }

  /// Agrega headers comunes a todas las peticiones.
  static void _addHeaders(HttpClientRequest request) {
    request.headers.add('Content-Type', 'application/json');
    request.headers.add('Accept', 'application/json');
    
    if (_authToken != null) {
      request.headers.add('Authorization', 'Bearer $_authToken');
    }
  }

  /// Procesa la respuesta HTTP.
  static Future<ApiResponse<Map<String, dynamic>>> _processResponse(
    HttpClientResponse response,
    Uri uri,
  ) async {
    final responseBody = await response.transform(utf8.decoder).join();
    final contentType = response.headers.contentType;
    final mimeType = contentType?.mimeType.toLowerCase();
    final isJsonResponse = mimeType == 'application/json' ||
        responseBody.trimLeft().startsWith('{') ||
        responseBody.trimLeft().startsWith('[');
    
    Map<String, dynamic>? data;
    try {
      if (responseBody.isNotEmpty && isJsonResponse) {
        data = jsonDecode(responseBody) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error parsing JSON response from $uri: $e');
      debugPrint('Response body preview: ${_previewBody(responseBody)}');
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    final errorMessage = isSuccess
        ? null
        : _buildErrorMessage(
            statusCode: response.statusCode,
            data: data,
            responseBody: responseBody,
            uri: uri,
            mimeType: mimeType,
          );

    return ApiResponse(
      success: isSuccess,
      data: data,
      error: errorMessage,
      statusCode: response.statusCode,
    );
  }

  static String _buildErrorMessage({
    required int statusCode,
    required Map<String, dynamic>? data,
    required String responseBody,
    required Uri uri,
    required String? mimeType,
  }) {
    final apiMessage = data?['message'] ?? data?['error'];
    if (apiMessage is String && apiMessage.trim().isNotEmpty) {
      return apiMessage;
    }

    final trimmedBody = responseBody.trimLeft();
    final isHtml = (mimeType?.contains('html') ?? false) ||
        trimmedBody.startsWith('<!doctype html') ||
        trimmedBody.startsWith('<html');

    if (statusCode == 404) {
      return 'Endpoint no encontrado (${uri.path}). Verifica la URL base y que el backend desplegado incluya Shipping API.';
    }

    if (isHtml) {
      return 'El servidor devolvió HTML en lugar de JSON. Revisa la URL configurada o el despliegue del backend.';
    }

    if (responseBody.trim().isNotEmpty) {
      return 'Error HTTP $statusCode: ${_previewBody(responseBody)}';
    }

    return 'Error del servidor (HTTP $statusCode)';
  }

  static String _previewBody(String body) {
    final singleLine = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (singleLine.length <= 160) {
      return singleLine;
    }
    return '${singleLine.substring(0, 157)}...';
  }
}
