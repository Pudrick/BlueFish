import 'package:bluefish/widgets/html/details/bluefish_details_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' as fwfh;

class BluefishDetailsBuildOp {
  static const String tagName = 'details';
  static const String _tagSummary = 'summary';
  static const String _attributeOpen = 'open';

  final fwfh.WidgetFactory wf;

  BluefishDetailsBuildOp(this.wf);

  fwfh.BuildOp get buildOp => fwfh.BuildOp(
    alwaysRenderBlock: true,
    debugLabel: tagName,
    onRenderedChildren: (tree, children) {
      Widget? summary;
      final contentChildren = <fwfh.WidgetPlaceholder>[];

      for (final child in children) {
        if (summary == null && child.isBluefishSummary) {
          summary = child;
        } else {
          contentChildren.add(child);
        }
      }

      final content = wf.buildColumnPlaceholder(tree, contentChildren);
      final hasContent = content != null;

      if (summary == null && !hasContent) {
        return null;
      }

      return fwfh.WidgetPlaceholder(
        debugLabel: '${tree.element.localName}--bluefish-details',
        builder: (context, _) => BluefishDetailsWidget(
          summary: summary ?? const Text('Details'),
          content: content ?? fwfh.widget0,
          hasContent: hasContent,
          initiallyOpen: tree.element.attributes.containsKey(_attributeOpen),
        ),
      );
    },
    onVisitChild: (detailsTree, subTree) {
      final element = subTree.element;
      if (element.parent != detailsTree.element) {
        return;
      }
      if (element.localName != _tagSummary) {
        return;
      }

      subTree.register(
        const fwfh.BuildOp.v2(
          alwaysRenderBlock: true,
          debugLabel: _tagSummary,
          onRenderedBlock: _markSummary,
          priority: fwfh.kPriorityDefault + 1,
        ),
      );
    },
  );

  static void _markSummary(fwfh.BuildTree _, Widget block) {
    block.isBluefishSummary = true;
  }
}

extension on Widget {
  static final _isBluefishSummary = Expando<bool>();

  bool get isBluefishSummary => _isBluefishSummary[this] ?? false;

  set isBluefishSummary(bool value) => _isBluefishSummary[this] = value;
}
