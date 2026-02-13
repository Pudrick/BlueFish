extension RemoveStringTagSuffix on String {
  String removeSuffixTag() {
    const tags = ["[图片]", "[多图]", "[视频]"];

    for (final tag in tags) {
      if (endsWith(tag)) {
        return substring(0, length - tag.length);
      }
    }
    return this;
  }
}
