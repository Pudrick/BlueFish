import 'package:bluefish/models/abstract_floor_content.dart';
import 'package:bluefish/models/single_reply_floor.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AuthorInfoWidget extends StatelessWidget {
  final FloorContent content;
  const AuthorInfoWidget({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.network(
            content.author.avatarURL.toString(),
            scale: 4,
          ),
        ),
        const SizedBox(
          width: 5,
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Text(content.author.name,
                  textAlign: TextAlign.start,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(
                width: 5,
              ),
              if (content.author.adminsInfo != null) ...[
                const SizedBox(
                  width: 5,
                ),
                Text(
                  content.author.adminsInfo!,
                  style: const TextStyle(fontWeight: FontWeight.w100),
                  overflow: TextOverflow.visible,
                )
              ],
              if (content case SingleReplyFloor replyContent)
                if (replyContent.isOP) ...[
                  const SizedBox(
                    width: 5,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '楼主',
                      style: TextStyle(fontSize: 12),
                    ),
                  )
                ]
            ],
          ),
          Row(
            children: [
              Text(
                  "${DateFormat("yyyy-MM-dd HH:mm:ss").format(content.postTime)} (${content.postTimeReadable})"),
              if (content.postLocation != "")
                Text("    IP:${content.postLocation}"),
            ],
          ),
        ]),
        Expanded(
          child: Container(), // just for position holding
        ),
        Container(
            alignment: Alignment.center,
            child: switch (content.client) {
              "ANDROID" => const Icon(Icons.android),
              "IPHONE" => const Icon(Icons.apple),
              "PC" => const Icon(Icons.desktop_windows_outlined),
              String() => Container(),
            })
      ],
    );
  }
}
