import 'package:flutter_test/flutter_test.dart';
import 'package:registro_retorno_embarques/core/config/api_config.dart';

void main() {
  test('production API uses backend port 81', () {
    expect(ApiConfig.environment, ApiEnvironment.production);
    expect(ApiConfig.baseUri.host, '192.168.1.10');
    expect(ApiConfig.baseUri.port, 81);
    expect(ApiConfig.baseUri.path, '/api/shipping');
    expect(ApiConfig.healthCheckUrl, 'http://192.168.1.10:81/api/health');
  });
}
