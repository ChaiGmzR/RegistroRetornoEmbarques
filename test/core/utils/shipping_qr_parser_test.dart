import 'package:flutter_test/flutter_test.dart';
import 'package:registro_retorno_embarques/core/utils/shipping_qr_parser.dart';

void main() {
  group('ShippingQrParser', () {
    test('parsea formato P/No ... Qty ...', () {
      const rawValue =
          "P/No EBR80757421 Line R1 Qty 20 Description: PCB Assy' Main Ref ANDREA Day Model QUANTUM-T Apariencia OK Funcionamiento OK 0 0 Contenedor OK RoHS OK";

      final parsed = ShippingQrParser.parse(rawValue);

      expect(parsed, isNotNull);
      expect(parsed!.partNumber, 'EBR80757421');
      expect(parsed.quantity, 20);
      expect(parsed.rawValue, rawValue);
    });

    test('parsea formato prefijo-partNumber-Oven-cantidad', () {
      const rawValue = '3608-EBR43713608-Oven-20-TR0330_021';

      final parsed = ShippingQrParser.parse(rawValue);

      expect(parsed, isNotNull);
      expect(parsed!.partNumber, 'EBR43713608');
      expect(parsed.quantity, 20);
      expect(parsed.rawValue, rawValue);
    });

    test('parsea formato multilinea Resultado: P/No ... Qty ...', () {
      const rawValue =
          'Resultado: P/No\nACQ30500849\nLine\nR2\nQty\n80\nDescriptionÑ\nInner Display\nDilan\nDay\nModel\nVF1 B\nApariencia\nOK\nFuncionamiento\nOK\n80.7\n80.87\nContenedor\nOK\nRoHS\nOK';

      final parsed = ShippingQrParser.parse(rawValue);

      expect(parsed, isNotNull);
      expect(parsed!.partNumber, 'ACQ30500849');
      expect(parsed.quantity, 80);
    });

    test('acepta numero de parte directo cuando el campo ya fue normalizado', () {
      const rawValue = 'ACQ30500849';

      final parsed = ShippingQrParser.parse(rawValue);

      expect(parsed, isNotNull);
      expect(parsed!.partNumber, 'ACQ30500849');
      expect(parsed.quantity, isNull);
      expect(parsed.rawValue, rawValue);
    });

    test('extrae numero de parte desde codigo largo que inicia con EBR', () {
      const rawValue = 'EBR80757421922407030048';

      final parsed = ShippingQrParser.parse(rawValue);

      expect(parsed, isNotNull);
      expect(parsed!.partNumber, 'EBR80757421');
      expect(parsed.quantity, isNull);
    });

    test('extrae numero de parte embebido en codigo delimitado con ñ', () {
      const rawValue = "I20240110'0052'00608ñMAINñEBR80757421ñ1ñ";

      final parsed = ShippingQrParser.parse(rawValue);

      expect(parsed, isNotNull);
      expect(parsed!.partNumber, 'EBR80757421');
      expect(parsed.quantity, isNull);
    });

    test('retorna null cuando el QR no coincide con un formato soportado', () {
      final parsed = ShippingQrParser.parse('codigo-invalido');

      expect(parsed, isNull);
    });
  });
}
