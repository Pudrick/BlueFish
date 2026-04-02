List<Map<String, dynamic>> emptyQuillDeltaJson() {
  return const <Map<String, dynamic>>[
    <String, dynamic>{'insert': '\n'},
  ];
}

bool isQuillDeltaMeaningfullyEmpty(List<Map<String, dynamic>> deltaJson) {
  for (final operation in deltaJson) {
    final insert = operation['insert'];
    if (insert is String) {
      final normalized = insert.replaceAll('\n', '').trim();
      if (normalized.isNotEmpty) {
        return false;
      }
      continue;
    }

    if (insert is Map && insert.isNotEmpty) {
      return false;
    }
  }

  return true;
}
