import 'package:bluefish/models/thread_detail.dart';
import 'package:bluefish/widgets/thread_main_widget.dart';
import 'package:bluefish/widgets/reply_floor_widget.dart';
import 'package:flutter/material.dart';

class ThreadWidget extends StatefulWidget {
  final String tid;

  const ThreadWidget._({super.key, required this.tid});

  factory ThreadWidget({Key? key, required dynamic tid}) {
    if (tid is String) {
      return ThreadWidget._(tid: tid);
    } else if (tid is int) {
      return ThreadWidget._(tid: tid.toString());
    } else {
      throw ArgumentError(
          "tid only can be String or int, but get ${tid.runtimeType}");
    }
  }

  @override
  State<StatefulWidget> createState() => _ThreadWidgetState();
}

class _ThreadWidgetState extends State<ThreadWidget> {
  late ThreadDetail threadDetail;
  bool isLoading = true;

  Future<void> _loadData() async {
    await threadDetail.refresh();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    threadDetail = ThreadDetail(widget.tid);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // TODO: make title widget independent so that can be sticked on the top.
          SliverPersistentHeader(
              delegate: StickyHeaderDelegate(
                  child:
                      ThreadTitleWidget(title: threadDetail.mainFloor.title)),
              pinned: true),

          SliverToBoxAdapter(
            child: ThreadMainFloorWidget(mainFloor: threadDetail.mainFloor),
          ),

          SliverList(
              delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
            return ReplyFloor(replyFloor: threadDetail.replies[index]);
          },
                  childCount: (threadDetail.totalRepliesNum <= 20)
                      ? threadDetail.totalRepliesNum
                      : 20))
        ],
      ),
    );
  }
}
