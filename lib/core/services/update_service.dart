import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../config/update_config.dart';
import '../models/update_info.dart';

/// Servicio para gestionar actualizaciones automaticas via GitHub Releases
class UpdateService {
  static const String _lastCheckKey = 'last_update_check';

  /// Verifica si hay una nueva version disponible
  static Future<UpdateInfo?> checkForUpdate({bool forceCheck = false}) async {
    try {
      // Verificar si debemos comprobar (intervalo minimo)
      if (!forceCheck && !await _shouldCheck()) {
        return null;
      }

      final response = await http.get(
        Uri.parse(UpdateConfig.latestReleaseUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'RegistroEmbarques-App',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await _saveLastCheckTime();

        final data = jsonDecode(response.body);
        final updateInfo = UpdateInfo.fromGitHubRelease(data);

        // Comparar versiones
        if (_isNewerVersion(updateInfo.version, UpdateConfig.currentVersion)) {
          return updateInfo;
        }
      } else if (response.statusCode == 404) {
        // No hay releases todavia
        debugPrint('UpdateService: No hay releases disponibles (404)');
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('Error al verificar actualizaciones: $e');
      return null;
    }
  }

  /// Compara dos versiones semanticas (ej: "1.2.3" vs "1.2.0")
  static bool _isNewerVersion(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      // Asegurar que ambas tengan 3 partes
      while (newParts.length < 3) {
        newParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (newParts[i] > currentParts[i]) return true;
        if (newParts[i] < currentParts[i]) return false;
      }

      return false; // Son iguales
    } catch (e) {
      return false;
    }
  }

  /// Verifica si ha pasado suficiente tiempo desde la ultima comprobacion
  static Future<bool> _shouldCheck() async {
    if (UpdateConfig.checkIntervalHours == 0) return true;

    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursSinceLastCheck = (now - lastCheck) / (1000 * 60 * 60);

    return hoursSinceLastCheck >= UpdateConfig.checkIntervalHours;
  }

  /// Guarda el timestamp de la ultima comprobacion
  static Future<void> _saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Solicita permisos necesarios para instalar APK en Android
  static Future<bool> requestInstallPermission() async {
    // Verificar permiso para instalar desde fuentes desconocidas
    final status = await Permission.requestInstallPackages.status;
    if (status.isGranted) {
      return true;
    }

    // Solicitar permiso
    final result = await Permission.requestInstallPackages.request();
    return result.isGranted;
  }

  /// Descarga la actualizacion y retorna la ruta del archivo APK
  static Future<String?> downloadUpdate(
    UpdateInfo updateInfo,
    void Function(double progress)? onProgress,
  ) async {
    try {
      // Obtener directorio de descargas
      final Directory downloadDir;
      if (Platform.isAndroid) {
        // En Android, usar el directorio externo de la app
        final extDir = await getExternalStorageDirectory();
        downloadDir = Directory('${extDir?.path}/updates');
      } else {
        final tempDir = await getTemporaryDirectory();
        downloadDir = Directory('${tempDir.path}/updates');
      }

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final filePath = '${downloadDir.path}/${updateInfo.assetName}';
      final file = File(filePath);

      // Si existe un archivo anterior, eliminarlo
      if (await file.exists()) {
        await file.delete();
      }

      // Descargar con progreso
      final request = http.Request('GET', Uri.parse(updateInfo.downloadUrl));
      request.headers['User-Agent'] = 'RegistroEmbarques-App';

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Error al descargar: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? updateInfo.assetSize;
      int received = 0;

      final sink = file.openWrite();

      await for (var chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress?.call(received / contentLength);
        }
      }

      await sink.close();

      debugPrint('APK descargado en: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error al descargar actualizacion: $e');
      return null;
    }
  }

  /// Abre el APK descargado para instalacion (Android)
  static Future<bool> installUpdate(String apkPath) async {
    try {
      // Verificar que existe el APK
      if (!await File(apkPath).exists()) {
        throw Exception('No se encontro el APK descargado');
      }

      // Solicitar permiso para instalar
      final hasPermission = await requestInstallPermission();
      if (!hasPermission) {
        debugPrint('No se otorgo permiso para instalar paquetes');
        return false;
      }

      // Abrir el APK con el instalador del sistema
      final result = await OpenFilex.open(apkPath);

      if (result.type == ResultType.done) {
        debugPrint('Instalador de APK abierto exitosamente');
        return true;
      } else {
        debugPrint('Error al abrir APK: ${result.message}');
        return false;
      }
    } catch (e) {
      debugPrint('Error al instalar actualizacion: $e');
      return false;
    }
  }

  /// Abre la pagina de releases en el navegador
  static Future<void> openReleasesPage() async {
    final url = UpdateConfig.releasesUrl;
    try {
      // Usar open_filex para abrir URL en Android
      await OpenFilex.open(url);
    } catch (e) {
      debugPrint('Error al abrir pagina de releases: $e');
    }
  }
}
