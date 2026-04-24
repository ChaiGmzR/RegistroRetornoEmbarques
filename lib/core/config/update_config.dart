/// Configuracion para el sistema de auto-actualizacion via GitHub Releases
class UpdateConfig {
  /// Usuario/Organizacion de GitHub
  static const String githubUser = 'ChaiGmzR';

  /// Nombre del repositorio
  static const String repoName = 'RegistroRetornoEmbarques';

  /// Version actual de la aplicacion (debe coincidir con pubspec.yaml)
  static const String currentVersion = '1.0.1';

  /// URL de la API de GitHub para obtener el ultimo release
  static String get latestReleaseUrl =>
      'https://api.github.com/repos/$githubUser/$repoName/releases/latest';

  /// URL base para descargas de releases
  static String get releasesUrl =>
      'https://github.com/$githubUser/$repoName/releases';

  /// Patron del archivo esperado en el release (APK para Android)
  static const String assetFilePattern = '.apk';

  /// Verificar actualizaciones al iniciar la app
  static const bool checkOnStartup = true;

  /// Intervalo minimo entre verificaciones en horas (0 = siempre verificar al iniciar)
  static const int checkIntervalHours = 0;
}
