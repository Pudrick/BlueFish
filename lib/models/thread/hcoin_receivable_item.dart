import 'package:bluefish/models/model_parsing.dart';
import 'package:flutter/foundation.dart';

@immutable
class HcoinReceivableItem {
  final String id;
  final int amount;
  final String description;
  final int? expireTimeMs;

  const HcoinReceivableItem({
    required this.id,
    required this.amount,
    required this.description,
    required this.expireTimeMs,
  });

  static HcoinReceivableItem? tryFromJson(Map<String, dynamic> json) {
    final id = parseString(json['id']).trim();
    if (id.isEmpty) {
      return null;
    }

    final rawExpireTime = parseNullableInt(json['expireTime']);
    return HcoinReceivableItem(
      id: id,
      amount: parseInt(json['num']),
      description: parseString(json['desc']).trim(),
      expireTimeMs: rawExpireTime != null && rawExpireTime > 0
          ? rawExpireTime
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HcoinReceivableItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amount == other.amount &&
          description == other.description &&
          expireTimeMs == other.expireTimeMs;

  @override
  int get hashCode => Object.hash(id, amount, description, expireTimeMs);
}
