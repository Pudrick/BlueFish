import 'package:bluefish/widgets/html/bluefish_html_widget_factory.dart';
import 'package:bluefish/widgets/html/vote/vote_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;

class BluefishHtmlWidget extends StatelessWidget {
  final String html;
  final TextStyle? textStyle;

  const BluefishHtmlWidget(this.html, {super.key, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: HtmlWidget(
        html,
        textStyle: textStyle,
        factoryBuilder: () => BluefishHtmlWidgetFactory(),
        customWidgetBuilder: _buildCustomWidget,
      ),
    );
  }

  Widget? _buildCustomWidget(dom.Element element) {
    if (element.localName == 'span' &&
        element.attributes['data-type'] == 'vote') {
      final voteId = int.tryParse(element.attributes['data-vote-id'] ?? '');
      if (voteId != null) {
        return VoteWidget(voteID: voteId);
      }
    }

    return null;
  }
}
