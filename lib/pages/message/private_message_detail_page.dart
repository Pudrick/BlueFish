import 'package:bluefish/services/private_message/private_message_detail_service.dart';
import 'package:bluefish/viewModels/private_message_detail_view_model.dart';
import 'package:bluefish/widgets/private_message/private_message_detail_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrivateMessageDetailPage extends StatelessWidget {
  final int puid;
  final String? initialTitle;
  final String? initialAvatarUrl;
  final double bottomInset;

  const PrivateMessageDetailPage({
    super.key,
    required this.puid,
    this.initialTitle,
    this.initialAvatarUrl,
    this.bottomInset = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ChangeNotifierProvider(
          create: (context) => PrivateMessageDetailViewModel(
            puid: puid,
            service: context.read<PrivateMessageDetailService>(),
          )..init(),
          child: PrivateMessageDetailWidget(
            initialTitle: initialTitle,
            initialAvatarUrl: initialAvatarUrl,
            bottomInset: bottomInset,
          ),
        ),
      ),
    );
  }
}
