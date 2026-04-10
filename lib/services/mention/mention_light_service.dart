import 'package:bluefish/models/mention/mention_light.dart';
import 'package:bluefish/services/mention/mention_service.dart';

class MentionLightService extends MentionService<MentionLight> {
  MentionLightService({required super.client})
    : super(
        apiPath: 'getLightRemindList',
        fromJson: MentionLight.fromJson,
        defaultQueryParameters: const {'plat': '2'},
      );
}
