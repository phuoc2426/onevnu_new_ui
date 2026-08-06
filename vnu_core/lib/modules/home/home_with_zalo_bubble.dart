import 'package:flutter/material.dart';
import 'package:vnu_core/modules/home/vcore_home_view_v3.dart';
import 'package:vnu_core/widgets/zalo_chat_bubble.dart';

/// Giữ bubble trong đúng phạm vi Home V3 và chỉ mount khi tab Home đang active.
class HomeWithZaloBubble extends StatelessWidget {
  const HomeWithZaloBubble({
    super.key,
    this.isActive = true,
  });

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const VcoreHomeViewV3(),
        if (isActive)
          const ZaloChatBubble(
            edgeInsets: EdgeInsets.fromLTRB(12, 12, 16, 108),
          ),
      ],
    );
  }
}
