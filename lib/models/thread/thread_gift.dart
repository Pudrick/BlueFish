import 'package:bluefish/models/model_parsing.dart';

class ThreadGift {
  final String giftId;
  final String iconUrl;

  const ThreadGift({required this.giftId, required this.iconUrl});

  static ThreadGift? tryFromJson(Map<String, dynamic> json) {
    final giftId = parseString(json['giftId']).trim();
    final iconUrl = parseString(json['icon']).trim();
    if (giftId.isEmpty || iconUrl.isEmpty) {
      return null;
    }

    return ThreadGift(giftId: giftId, iconUrl: iconUrl);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThreadGift &&
          runtimeType == other.runtimeType &&
          giftId == other.giftId &&
          iconUrl == other.iconUrl;

  @override
  int get hashCode => Object.hash(giftId, iconUrl);
}
