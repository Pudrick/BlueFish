class ThreadTitleMaskRule {
  final List<String> prefixes;
  final String label;

  const ThreadTitleMaskRule({required this.prefixes, required this.label});

  bool matches(String title) {
    final normalizedTitle = title.trimLeft();
    return prefixes.any(normalizedTitle.startsWith);
  }
}

// Add more prefix rules here when other title-based masks are needed.
const List<ThreadTitleMaskRule> kThreadTitleMaskRules = [
  ThreadTitleMaskRule(prefixes: ['[剧透]'], label: '剧透'),
];

ThreadTitleMaskRule? matchThreadTitleMaskRule(
  String title, {
  List<ThreadTitleMaskRule> rules = kThreadTitleMaskRules,
}) {
  for (final rule in rules) {
    if (rule.matches(title)) {
      return rule;
    }
  }

  return null;
}
