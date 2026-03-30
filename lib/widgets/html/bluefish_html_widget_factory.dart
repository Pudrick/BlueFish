import 'package:bluefish/widgets/html/details/bluefish_details_build_op.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' as fwfh;
import 'package:flutter/widgets.dart';

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

  @override
  Widget? onLoadingBuilder(
    BuildContext context,
    fwfh.BuildTree tree, [
    double? loadingProgress,
    dynamic data,
  ]) {
    final isImage = data is fwfh.ImageSource || tree.element.localName == 'img';
    if (isImage) {
      // Avoid centered loading placeholder to keep image position stable.
      return const SizedBox.shrink();
    }

    return super.onLoadingBuilder(context, tree, loadingProgress, data);
  }
}
