import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../models/composer/quill_embed_models.dart';
import '../../models/composer/quill_draft_utils.dart';
import 'details_embed_card.dart';

typedef DetailsEmbedUpdate =
    void Function(int offset, BluefishDetailsEmbedData data);
typedef ImagePlaceholderEmbedUpdate =
    void Function(int offset, BluefishImagePlaceholderEmbedData data);

class QuillComposerEditor extends StatefulWidget {
  final quill.QuillController controller;
  final String placeholder;
  final DetailsEmbedUpdate onDetailsEmbedChanged;
  final ImagePlaceholderEmbedUpdate onImagePlaceholderChanged;
  final ValueChanged<int> onEmbedRemoved;

  const QuillComposerEditor({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.onDetailsEmbedChanged,
    required this.onImagePlaceholderChanged,
    required this.onEmbedRemoved,
  });

  @override
  State<QuillComposerEditor> createState() => _QuillComposerEditorState();
}

class _QuillComposerEditorState extends State<QuillComposerEditor> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: quill.QuillEditor(
        focusNode: _focusNode,
        scrollController: _scrollController,
        controller: widget.controller,
        config: quill.QuillEditorConfig(
          scrollable: false,
          padding: const EdgeInsets.all(16),
          placeholder: widget.placeholder,
          embedBuilders: [
            _DetailsEmbedBuilder(
              focusNode: _focusNode,
              onChanged: widget.onDetailsEmbedChanged,
              onRemoved: widget.onEmbedRemoved,
            ),
            _ImagePlaceholderEmbedBuilder(
              focusNode: _focusNode,
              onChanged: widget.onImagePlaceholderChanged,
              onRemoved: widget.onEmbedRemoved,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsEmbedBuilder extends quill.EmbedBuilder {
  final FocusNode focusNode;
  final DetailsEmbedUpdate onChanged;
  final ValueChanged<int> onRemoved;

  const _DetailsEmbedBuilder({
    required this.focusNode,
    required this.onChanged,
    required this.onRemoved,
  });

  @override
  String get key => bluefishDetailsEmbedType;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final data = BluefishDetailsEmbedData.fromJsonString(
      embedContext.node.value.data as String,
    );
    final documentOffset = embedContext.node.documentOffset;

    void updateBoundarySelection(TextSelection selection) {
      focusNode.requestFocus();
      embedContext.controller.updateSelection(
        selection,
        quill.ChangeSource.local,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (embedContext.readOnly)
          const SizedBox(height: 6)
        else
          _BlockBoundaryTapTarget(
            key: ValueKey('details_embed_before_zone_$documentOffset'),
            gestureKey: ValueKey(
              'details_embed_before_gesture_$documentOffset',
            ),
            onTap: () {
              updateBoundarySelection(
                collapsedSelectionBeforeBlockEmbed(
                  plainText: embedContext.controller.document.toPlainText(),
                  embedOffset: documentOffset,
                ),
              );
            },
          ),
        DetailsEmbedCard(
          data: data,
          readOnly: embedContext.readOnly,
          onChanged: (nextData) {
            onChanged(documentOffset, nextData);
          },
          onRemove: embedContext.readOnly
              ? null
              : () => onRemoved(documentOffset),
        ),
        if (embedContext.readOnly)
          const SizedBox(height: 6)
        else
          _BlockBoundaryTapTarget(
            key: ValueKey('details_embed_after_zone_$documentOffset'),
            gestureKey: ValueKey('details_embed_after_gesture_$documentOffset'),
            onTap: () {
              updateBoundarySelection(
                collapsedSelectionAfterBlockEmbed(
                  plainText: embedContext.controller.document.toPlainText(),
                  embedOffset: documentOffset,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _BlockBoundaryTapTarget extends StatelessWidget {
  final Key? gestureKey;
  final VoidCallback onTap;

  const _BlockBoundaryTapTarget({
    super.key,
    this.gestureKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      width: double.infinity,
      child: GestureDetector(
        key: gestureKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
      ),
    );
  }
}

class _ImagePlaceholderEmbedBuilder extends quill.EmbedBuilder {
  final FocusNode focusNode;
  final ImagePlaceholderEmbedUpdate onChanged;
  final ValueChanged<int> onRemoved;

  const _ImagePlaceholderEmbedBuilder({
    required this.focusNode,
    required this.onChanged,
    required this.onRemoved,
  });

  @override
  String get key => bluefishImagePlaceholderEmbedType;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final data = BluefishImagePlaceholderEmbedData.fromJsonString(
      embedContext.node.value.data as String,
    );
    final documentOffset = embedContext.node.documentOffset;

    void updateBoundarySelection(TextSelection selection) {
      focusNode.requestFocus();
      embedContext.controller.updateSelection(
        selection,
        quill.ChangeSource.local,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (embedContext.readOnly)
          const SizedBox(height: 6)
        else
          _BlockBoundaryTapTarget(
            key: ValueKey('image_embed_before_zone_$documentOffset'),
            gestureKey: ValueKey('image_embed_before_gesture_$documentOffset'),
            onTap: () {
              updateBoundarySelection(
                collapsedSelectionBeforeBlockEmbed(
                  plainText: embedContext.controller.document.toPlainText(),
                  embedOffset: documentOffset,
                ),
              );
            },
          ),
        ImagePlaceholderEmbedCard(
          data: data,
          readOnly: embedContext.readOnly,
          onChanged: (nextData) {
            onChanged(documentOffset, nextData);
          },
          onRemove: embedContext.readOnly
              ? null
              : () => onRemoved(documentOffset),
        ),
        if (embedContext.readOnly)
          const SizedBox(height: 6)
        else
          _BlockBoundaryTapTarget(
            key: ValueKey('image_embed_after_zone_$documentOffset'),
            gestureKey: ValueKey('image_embed_after_gesture_$documentOffset'),
            onTap: () {
              updateBoundarySelection(
                collapsedSelectionAfterBlockEmbed(
                  plainText: embedContext.controller.document.toPlainText(),
                  embedOffset: documentOffset,
                ),
              );
            },
          ),
      ],
    );
  }
}
