import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VcoreProfileAvatarWidget extends StatelessWidget {
  final String url;
  final double size;

  const VcoreProfileAvatarWidget({
    super.key,
    required this.url,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallSize = size <= 60;
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        Container(
          // width: 110,
          // height: 110,
          decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(size),
              border:
                  Border.all(width: isSmallSize ? 3 : 4, color: Colors.white)),
          clipBehavior: Clip.hardEdge,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(size),
            ),
            clipBehavior: Clip.hardEdge,
            child: CachedNetworkImage(
              imageUrl: url,
              cacheKey: url,
              fit: BoxFit.fill,
            ),
          ),
        ),
        Container(
          width: !isSmallSize ? 16 : 12,
          height: !isSmallSize ? 16 : 12,
          margin: EdgeInsets.only(right: size * 0.082, bottom: size * 0.082),
          decoration: BoxDecoration(
              color: const Color(0xff27AE60),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(width: isSmallSize ? 2 : 3, color: Colors.white)),
        )
      ],
    );
  }
}
