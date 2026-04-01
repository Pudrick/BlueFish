String parseString(Object? value, {String fallback = ''}) {
  return value?.toString() ?? fallback;
}

String? parseNullableString(Object? value) {
  return value?.toString();
}

int parseInt(Object? value, {int fallback = 0}) {
  return switch (value) {
    int intValue => intValue,
    num numValue => numValue.toInt(),
    String stringValue => int.tryParse(stringValue) ?? fallback,
    _ => fallback,
  };
}

int? parseNullableInt(Object? value) {
  if (value == null) {
    return null;
  }

  return parseInt(value);
}

bool parseBool(Object? value, {bool fallback = false}) {
  return switch (value) {
    bool boolValue => boolValue,
    num numValue => numValue != 0,
    String stringValue =>
      stringValue.toLowerCase() == 'true' || stringValue == '1',
    _ => fallback,
  };
}

Map<String, dynamic> parseMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  throw ArgumentError.value(value, 'value', 'Expected a JSON object map.');
}

DateTime parseDateTimeFromMilliseconds(Object? value) {
  return DateTime.fromMillisecondsSinceEpoch(parseInt(value));
}
