import '../config/update_config.dart';

/// Modelo para almacenar informacion de una actualizacion disponible
class UpdateInfo {
  final String version;
  final String tagName;
  final String downloadUrl;
  final String releaseNotes;
  final DateTime publishedAt;
  final int assetSize;
  final String assetName;
  final bool isPrerelease;

  UpdateInfo({
    required this.version,
    required this.tagName,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.publishedAt,
    required this.assetSize,
    required this.assetName,
    this.isPrerelease = false,
  });

  factory UpdateInfo.fromGitHubRelease(Map<String, dynamic> json) {
    // Obtener el primer asset que coincida con el patron configurado (.apk)
    final assets = json['assets'] as List<dynamic>? ?? [];
    Map<String, dynamic>? matchingAsset;
    final pattern = UpdateConfig.assetFilePattern.toLowerCase();

    for (var asset in assets) {
      if (asset['name'].toString().toLowerCase().endsWith(pattern)) {
        matchingAsset = asset;
        break;
      }
    }

    return UpdateInfo(
      version: _parseVersion(json['tag_name'] ?? '0.0.0'),
      tagName: json['tag_name'] ?? '',
      downloadUrl: matchingAsset?['browser_download_url'] ?? '',
      releaseNotes: json['body'] ?? 'Sin notas de version',
      publishedAt:
          DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
      assetSize: matchingAsset?['size'] ?? 0,
      assetName: matchingAsset?['name'] ?? '',
      isPrerelease: json['prerelease'] ?? false,
    );
  }

  /// Extrae numero de version del tag (ej: "v1.2.3" -> "1.2.3")
  static String _parseVersion(String tagName) {
    return tagName.replaceFirst(RegExp(r'^v', caseSensitive: false), '');
  }

  /// Formatea el tamano del asset en MB
  String get formattedSize {
    final mb = assetSize / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Verifica si la URL de descarga es valida
  bool get hasValidDownload => downloadUrl.isNotEmpty;
}
