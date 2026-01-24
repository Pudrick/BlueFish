import "package:bluefish/widgets/author_info_widget.dart";
import "package:bluefish/widgets/htmlWidget_with_vote.dart";
import "package:flutter/material.dart";

import 'package:bluefish/models/single_reply_floor.dart';

class ReplyFloor extends StatelessWidget {
  final SingleReplyFloor replyFloor;
  final bool isQuote;

  const ReplyFloor({super.key, required this.replyFloor, required this.isQuote});

  @override
  Widget build(BuildContext context) {
    if (replyFloor.isDelete || replyFloor.isSelfDelete || replyFloor.isHidden) {
      return const SizedBox.shrink();
    } else {
      const double buttonHeight = 36.0;
      const double capsuleRadius = buttonHeight / 2;
      const double adjacentCornerRadius = 4.0;

      // TODO: implement quotes in reply.
      return Card(
        color: isQuote ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthorInfoWidget(content: replyFloor),
                const Divider(),
                if(!isQuote && replyFloor.hasQuote) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _QuoteWidget(
                      quoteWidget: ReplyFloor(replyFloor: replyFloor.quote!, isQuote: true)),
                    ),
                ],
                Padding(

                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: HtmlWidgetWithVote(replyFloor.contentHTML),

                ),
                if(!isQuote) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(capsuleRadius),
                                    right:
                                        Radius.circular(adjacentCornerRadius)))),

                        // the effect is same.

                        //  ButtonStyle(
                        // shape:
                        //     WidgetStateProperty.all<RoundedRectangleBorder>(
                        //         const RoundedRectangleBorder(
                        //             borderRadius: BorderRadius.horizontal(
                        //                 left: Radius.circular(capsuleRadius),
                        //                 right: Radius.circular(
                        //                     adjacentCornerRadius))))),
                        child: Row(
                          children: [
                            const Icon(Icons.wb_incandescent_outlined),
                            Text(" ${replyFloor.lightCount}"),
                          ],
                        ),
                      ),
                      const SizedBox(width: 3),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(capsuleRadius),
                                    left:
                                        Radius.circular(adjacentCornerRadius)))),
                        child: const Icon(Icons.thumb_down_alt_outlined),
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
        ),
      );
    }
  }
}

class _QuoteWidget extends StatefulWidget {
  final Widget quoteWidget;
  final double maxHeight;

  const _QuoteWidget({required this.quoteWidget, this.maxHeight = 180, });

  @override
  State<_QuoteWidget> createState() => _QuoteWidgetState();
}

class _QuoteWidgetState extends State<_QuoteWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      alignment: Alignment.topCenter,
      child: _isExpanded ? _buildExpandedView(colorScheme) : _buildCollapsedView(colorScheme),
      );
  }

  Widget _buildExpandedView(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.quoteWidget,

        InkWell(
          onTap: () => setState(() => _isExpanded = false,),
          child: SizedBox(
            height: 30,
            child: Icon(
              Icons.keyboard_arrow_up, size: 20, color: colorScheme.primary,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildCollapsedView(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true,),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: ClipRect(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: AbsorbPointer(child: widget.quoteWidget),
              ),
            ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0),
                      colorScheme.surfaceContainerHighest.withValues(alpha: 1)
                    ])
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 2,),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    )
                  ],
                ),
              ))
        ],
      ),
    );
  }
}