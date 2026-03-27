import 'package:flutter/material.dart';

class ThreadReplySheetAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool enabled;
  final bool selected;

  const ThreadReplySheetAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.tooltip,
    this.enabled = true,
    this.selected = false,
  });
}

class ThreadReplySheetEmojiItem {
  final String key;
  final String label;
  final String display;
  final String insertText;
  final String? tooltip;

  const ThreadReplySheetEmojiItem({
    required this.key,
    required this.label,
    required this.display,
    String? insertText,
    this.tooltip,
  }) : insertText = insertText ?? display;
}

class ThreadReplySheetEmojiCategory {
  final String key;
  final String label;
  final List<ThreadReplySheetEmojiItem> items;

  const ThreadReplySheetEmojiCategory({
    required this.key,
    required this.label,
    required this.items,
  });

  static const List<ThreadReplySheetEmojiCategory> defaultCategories = [
    ThreadReplySheetEmojiCategory(
      key: 'faces',
      label: '表情',
      items: [
        ThreadReplySheetEmojiItem(key: 'grin', label: '咧嘴笑', display: '😀'),
        ThreadReplySheetEmojiItem(key: 'laugh', label: '大笑', display: '😄'),
        ThreadReplySheetEmojiItem(key: 'squint', label: '眯眼笑', display: '😆'),
        ThreadReplySheetEmojiItem(
          key: 'sweat_smile',
          label: '苦笑',
          display: '😅',
        ),
        ThreadReplySheetEmojiItem(key: 'joy', label: '笑哭', display: '😂'),
        ThreadReplySheetEmojiItem(key: 'wink', label: '眨眼', display: '😉'),
        ThreadReplySheetEmojiItem(key: 'smile', label: '微笑', display: '😊'),
        ThreadReplySheetEmojiItem(key: 'halo', label: '天使', display: '😇'),
        ThreadReplySheetEmojiItem(key: 'cool', label: '墨镜', display: '😎'),
        ThreadReplySheetEmojiItem(key: 'thinking', label: '思考', display: '🤔'),
        ThreadReplySheetEmojiItem(key: 'smirk', label: '坏笑', display: '😏'),
        ThreadReplySheetEmojiItem(key: 'relieved', label: '松气', display: '😌'),
        ThreadReplySheetEmojiItem(key: 'sob', label: '大哭', display: '😭'),
        ThreadReplySheetEmojiItem(key: 'rage', label: '生气', display: '😡'),
      ],
    ),
    ThreadReplySheetEmojiCategory(
      key: 'gestures',
      label: '手势',
      items: [
        ThreadReplySheetEmojiItem(key: 'thumbs_up', label: '点赞', display: '👍'),
        ThreadReplySheetEmojiItem(
          key: 'thumbs_down',
          label: '点踩',
          display: '👎',
        ),
        ThreadReplySheetEmojiItem(key: 'clap', label: '鼓掌', display: '👏'),
        ThreadReplySheetEmojiItem(
          key: 'raised_hands',
          label: '举手庆祝',
          display: '🙌',
        ),
        ThreadReplySheetEmojiItem(key: 'pray', label: '双手合十', display: '🙏'),
        ThreadReplySheetEmojiItem(key: 'muscle', label: '加油', display: '💪'),
        ThreadReplySheetEmojiItem(key: 'ok_hand', label: 'OK', display: '👌'),
        ThreadReplySheetEmojiItem(key: 'victory', label: '剪刀手', display: '✌️'),
        ThreadReplySheetEmojiItem(key: 'wave', label: '挥手', display: '👋'),
        ThreadReplySheetEmojiItem(key: 'fist_bump', label: '碰拳', display: '🤜'),
        ThreadReplySheetEmojiItem(
          key: 'heart_hands',
          label: '比心',
          display: '🫶',
        ),
        ThreadReplySheetEmojiItem(key: 'writing', label: '记笔记', display: '✍️'),
      ],
    ),
    ThreadReplySheetEmojiCategory(
      key: 'hearts',
      label: '氛围',
      items: [
        ThreadReplySheetEmojiItem(key: 'heart', label: '红心', display: '❤️'),
        ThreadReplySheetEmojiItem(key: 'fire', label: '火焰', display: '🔥'),
        ThreadReplySheetEmojiItem(key: 'sparkles', label: '闪光', display: '✨'),
        ThreadReplySheetEmojiItem(key: 'party', label: '庆祝', display: '🥳'),
        ThreadReplySheetEmojiItem(key: 'tada', label: '礼花', display: '🎉'),
        ThreadReplySheetEmojiItem(key: 'eyes', label: '关注', display: '👀'),
        ThreadReplySheetEmojiItem(key: 'boom', label: '爆炸', display: '💥'),
        ThreadReplySheetEmojiItem(key: 'hundred', label: '满分', display: '💯'),
        ThreadReplySheetEmojiItem(key: 'star', label: '星星', display: '⭐'),
        ThreadReplySheetEmojiItem(key: 'moon', label: '月亮', display: '🌙'),
        ThreadReplySheetEmojiItem(key: 'sun', label: '太阳', display: '☀️'),
        ThreadReplySheetEmojiItem(key: 'coffee', label: '咖啡', display: '☕'),
      ],
    ),
    ThreadReplySheetEmojiCategory(
      key: 'animals',
      label: '杂项',
      items: [
        ThreadReplySheetEmojiItem(key: 'dog', label: '小狗', display: '🐶'),
        ThreadReplySheetEmojiItem(key: 'cat', label: '小猫', display: '🐱'),
        ThreadReplySheetEmojiItem(key: 'bear', label: '小熊', display: '🐻'),
        ThreadReplySheetEmojiItem(key: 'frog', label: '青蛙', display: '🐸'),
        ThreadReplySheetEmojiItem(key: 'penguin', label: '企鹅', display: '🐧'),
        ThreadReplySheetEmojiItem(key: 'rocket', label: '火箭', display: '🚀'),
        ThreadReplySheetEmojiItem(
          key: 'light_bulb',
          label: '灵感',
          display: '💡',
        ),
        ThreadReplySheetEmojiItem(
          key: 'video_game',
          label: '游戏',
          display: '🎮',
        ),
        ThreadReplySheetEmojiItem(key: 'music', label: '音乐', display: '🎵'),
        ThreadReplySheetEmojiItem(key: 'soccer', label: '足球', display: '⚽'),
        ThreadReplySheetEmojiItem(key: 'book', label: '书本', display: '📚'),
        ThreadReplySheetEmojiItem(key: 'memo', label: '备忘', display: '📝'),
      ],
    ),
  ];
}
