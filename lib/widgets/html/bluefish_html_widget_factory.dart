import 'package:bluefish/widgets/html/details/bluefish_details_build_op.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' as fwfh;

class BluefishHtmlWidgetFactory extends fwfh.WidgetFactory {
  fwfh.BuildOp? _detailsBuildOp;

  @override
  void parse(fwfh.BuildTree meta) {
    if (meta.element.localName == BluefishDetailsBuildOp.tagName) {
      meta.register(_detailsBuildOp ??= BluefishDetailsBuildOp(this).buildOp);
      return;
    }

    super.parse(meta);
  }
}
