import 'package:flutter/material.dart';

@immutable
class BluefishSemanticColors extends ThemeExtension<BluefishSemanticColors> {
  final Color linkAccent;
  final Color linkAccentAlt;
  final Color mentionAccent;
  final Color mentionQuoteAccent;
  final Color voteLeadingAccent;
  final Color voteTrailingAccent;
  final Color mediaOverlay;
  final Color onMediaOverlay;
  final Color modalBarrier;

  const BluefishSemanticColors({
    required this.linkAccent,
    required this.linkAccentAlt,
    required this.mentionAccent,
    required this.mentionQuoteAccent,
    required this.voteLeadingAccent,
    required this.voteTrailingAccent,
    required this.mediaOverlay,
    required this.onMediaOverlay,
    required this.modalBarrier,
  });

  factory BluefishSemanticColors.fromScheme(ColorScheme colorScheme) {
    return BluefishSemanticColors(
      linkAccent: colorScheme.primary,
      linkAccentAlt: colorScheme.tertiary,
      mentionAccent: colorScheme.primary,
      mentionQuoteAccent: colorScheme.tertiary,
      voteLeadingAccent: colorScheme.tertiary,
      voteTrailingAccent: colorScheme.secondary,
      mediaOverlay: const Color(0xFF000000),
      onMediaOverlay: const Color(0xFFFFFFFF),
      modalBarrier: const Color(0x8A000000),
    );
  }

  @override
  BluefishSemanticColors copyWith({
    Color? linkAccent,
    Color? linkAccentAlt,
    Color? mentionAccent,
    Color? mentionQuoteAccent,
    Color? voteLeadingAccent,
    Color? voteTrailingAccent,
    Color? mediaOverlay,
    Color? onMediaOverlay,
    Color? modalBarrier,
  }) {
    return BluefishSemanticColors(
      linkAccent: linkAccent ?? this.linkAccent,
      linkAccentAlt: linkAccentAlt ?? this.linkAccentAlt,
      mentionAccent: mentionAccent ?? this.mentionAccent,
      mentionQuoteAccent: mentionQuoteAccent ?? this.mentionQuoteAccent,
      voteLeadingAccent: voteLeadingAccent ?? this.voteLeadingAccent,
      voteTrailingAccent: voteTrailingAccent ?? this.voteTrailingAccent,
      mediaOverlay: mediaOverlay ?? this.mediaOverlay,
      onMediaOverlay: onMediaOverlay ?? this.onMediaOverlay,
      modalBarrier: modalBarrier ?? this.modalBarrier,
    );
  }

  @override
  BluefishSemanticColors lerp(
    covariant ThemeExtension<BluefishSemanticColors>? other,
    double t,
  ) {
    if (other is! BluefishSemanticColors) {
      return this;
    }

    return BluefishSemanticColors(
      linkAccent: Color.lerp(linkAccent, other.linkAccent, t) ?? linkAccent,
      linkAccentAlt:
          Color.lerp(linkAccentAlt, other.linkAccentAlt, t) ?? linkAccentAlt,
      mentionAccent:
          Color.lerp(mentionAccent, other.mentionAccent, t) ?? mentionAccent,
      mentionQuoteAccent:
          Color.lerp(mentionQuoteAccent, other.mentionQuoteAccent, t) ??
          mentionQuoteAccent,
      voteLeadingAccent:
          Color.lerp(voteLeadingAccent, other.voteLeadingAccent, t) ??
          voteLeadingAccent,
      voteTrailingAccent:
          Color.lerp(voteTrailingAccent, other.voteTrailingAccent, t) ??
          voteTrailingAccent,
      mediaOverlay:
          Color.lerp(mediaOverlay, other.mediaOverlay, t) ?? mediaOverlay,
      onMediaOverlay:
          Color.lerp(onMediaOverlay, other.onMediaOverlay, t) ?? onMediaOverlay,
      modalBarrier:
          Color.lerp(modalBarrier, other.modalBarrier, t) ?? modalBarrier,
    );
  }
}

extension BluefishThemeContext on BuildContext {
  BluefishSemanticColors get semanticColors =>
      Theme.of(this).extension<BluefishSemanticColors>() ??
      BluefishSemanticColors.fromScheme(Theme.of(this).colorScheme);
}
