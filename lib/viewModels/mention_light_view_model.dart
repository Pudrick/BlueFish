import 'package:bluefish/models/mention/mention_light.dart';
import 'package:bluefish/services/mention_light_service.dart';
import 'package:bluefish/viewModels/mention_view_model.dart';

class MentionLightViewModel extends MentionViewModel<MentionLight> {
  MentionLightViewModel() : super(MentionLightService());
}
