import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VcoreProfileAvatarWidget extends StatelessWidget {
  final String url;
  final double size;
  final bool showStatus;

  const VcoreProfileAvatarWidget({
    super.key,
    required this.url,
    required this.size,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmallSize = size <= 60;
    final double borderWidth = isSmallSize ? 3 : 4;
    final double statusSize = isSmallSize ? 12 : 16;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.all(borderWidth),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: ColoredBox(
                  color: const Color(0xFFE5E7EB),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    cacheKey: url,
                    width: size,
                    height: size,

                    // Quan trọng: không dùng BoxFit.fill.
                    fit: BoxFit.cover,
                    alignment: Alignment.center,

                    fadeInDuration: const Duration(milliseconds: 150),

                    placeholder: (_, __) {
                      return const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },

                    errorWidget: (_, __, ___) {
                      return const Center(
                        child: Icon(
                          Icons.person,
                          color: Color(0xFF94A3B8),
                          size: 34,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          if (showStatus)
            Positioned(
              right: size * 0.06,
              bottom: size * 0.06,
              child: Container(
                width: statusSize,
                height: statusSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: isSmallSize ? 2 : 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
