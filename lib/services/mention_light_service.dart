import 'package:bluefish/models/mention_light.dart';
import 'package:bluefish/services/mention_service.dart';

class MentionLightService extends MentionService<MentionLight> {
  MentionLightService()
    : super(
        apiPath: "getLightRemindList",
        fromJson: MentionLight.fromJson,
        defaultQueryParameters: const {'plat': '2'},
      );
}
