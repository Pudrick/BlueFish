// lib/pages/thread/widgets/thread_pagination_bar.dart

import 'package:flutter/material.dart';

class ThreadPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrev; 
  final VoidCallback? onNext; 

  const ThreadPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: onPrev,
              style: _commonButtonStyle(),
              child: const Text("上一页"),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.tonal(
              onPressed: onNext,
              style: _commonButtonStyle(),
              child: const Text("下一页"),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _commonButtonStyle() {
    return FilledButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    );
  }
}