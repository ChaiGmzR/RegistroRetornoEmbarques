class ShippingQrData {
  final String rawValue;
  final String partNumber;
  final int? quantity;

  const ShippingQrData({
    required this.rawValue,
    required this.partNumber,
    this.quantity,
  });
}

/// Extrae número de parte y cantidad desde los formatos de QR soportados.
abstract final class ShippingQrParser {
  static final RegExp _partQtyFormat = RegExp(
    r'P\s*[\/-]?\s*No\s*([A-Z0-9]+?)(?=\s*(?:Line|Qty|Description|Day|Model|Apariencia|Funcionamiento|Contenedor|RoHS|$)).*?\bQty\s*[:\-]?\s*(\d+)\b',
    caseSensitive: false,
    dotAll: true,
  );

  static final RegExp _ovenFormat = RegExp(
    r'^[^-]+-([A-Z0-9]+)-Oven-(\d+)(?:-|$)',
    caseSensitive: false,
  );

  static final RegExp _partOnlyFormat = RegExp(
    r'P\s*[\/-]?\s*No\s*([A-Z0-9]+?)(?=\s*(?:Line|Qty|Description|Day|Model|Apariencia|Funcionamiento|Contenedor|RoHS|$))',
    caseSensitive: false,
    dotAll: true,
  );

  static final RegExp _ovenPartOnlyFormat = RegExp(
    r'^[^-]+-([A-Z0-9]+)-Oven(?:-|$)',
    caseSensitive: false,
  );

  static final RegExp _tracedBoxPartNumberFormat = RegExp(
    r"(?:\b\d{4}[-'])?([A-Z]{2,5}\d{6,12})(?=(?:[-']+)?TR\d{4}(?:[_?]\d+)?\b)",
    caseSensitive: false,
  );

  static final RegExp _embeddedEbrPartNumberFormat = RegExp(
    r'(EBR\d{8})',
    caseSensitive: false,
  );

  static final RegExp _directPartNumberFormat = RegExp(
    r'\b(EBR[A-Z0-9]+)\b',
    caseSensitive: false,
  );

  static final RegExp _fullDirectPartNumberFormat = RegExp(
    r'^(?=.*\d)[A-Z]{2,}[A-Z0-9-]{4,}$',
    caseSensitive: false,
  );

  static ShippingQrData? parse(String rawValue) {
    final normalizedValue = _normalize(rawValue);
    if (normalizedValue.isEmpty) {
      return null;
    }

    final partQtyMatch = _partQtyFormat.firstMatch(normalizedValue);
    if (partQtyMatch != null) {
      return ShippingQrData(
        rawValue: normalizedValue,
        partNumber: partQtyMatch.group(1)!.toUpperCase(),
        quantity: int.parse(partQtyMatch.group(2)!),
      );
    }

    final ovenMatch = _ovenFormat.firstMatch(normalizedValue);
    if (ovenMatch != null) {
      return ShippingQrData(
        rawValue: normalizedValue,
        partNumber: ovenMatch.group(1)!.toUpperCase(),
        quantity: int.parse(ovenMatch.group(2)!),
      );
    }

    final partOnlyMatch = _partOnlyFormat.firstMatch(normalizedValue);
    if (partOnlyMatch != null) {
      return ShippingQrData(
        rawValue: normalizedValue,
        partNumber: partOnlyMatch.group(1)!.toUpperCase(),
      );
    }

    final ovenPartOnlyMatch = _ovenPartOnlyFormat.firstMatch(normalizedValue);
    if (ovenPartOnlyMatch != null) {
      return ShippingQrData(
        rawValue: normalizedValue,
        partNumber: ovenPartOnlyMatch.group(1)!.toUpperCase(),
      );
    }

    final tracedBoxPartNumberMatch =
        _tracedBoxPartNumberFormat.firstMatch(normalizedValue);
    if (tracedBoxPartNumberMatch != null) {
      return ShippingQrData(
        rawValue: normalizedValue,
        partNumber: tracedBoxPartNumberMatch.group(1)!.toUpperCase(),
      );
    }

    final embeddedEbrPartNumberMatch =
        _embeddedEbrPartNumberFormat.firstMatch(normalizedValue);
    if (embeddedEbrPartNumberMatch != null) {
      return ShippingQrData(
        rawValue: normalizedValue,
        partNumber: embeddedEbrPartNumberMatch.group(1)!.toUpperCase(),
      );
    }

    final directPartNumberMatch =
        _directPartNumberFormat.firstMatch(normalizedValue);
    if (directPartNumberMatch != null) {
      return ShippingQrData(
        rawValue: normalizedValue,
        partNumber: directPartNumberMatch.group(1)!.toUpperCase(),
      );
    }

    final fullDirectPartNumberMatch =
        _fullDirectPartNumberFormat.firstMatch(normalizedValue);
    if (fullDirectPartNumberMatch != null) {
      return ShippingQrData(
        rawValue: normalizedValue,
        partNumber: fullDirectPartNumberMatch.group(0)!.toUpperCase(),
      );
    }

    return null;
  }

  static String _normalize(String rawValue) {
    return rawValue
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
