import 'package:flutter/material.dart';

import '../network/api_endpoints.dart';

/// صورة شخصية دائرية من الخادم تسقط إلى [child] حين لا صورة أو حين يفشل
/// تحميلها — بدل الدائرة الفارغة التي كانت تتركها `CircleAvatar` وحدها.
///
/// [imageUrl] هو المسار كما يعيده الخادم (يُحوَّل عبر [ApiEndpoints.fileUrl]).
class NetworkCircleAvatar extends StatefulWidget {
  const NetworkCircleAvatar({
    super.key,
    required this.imageUrl,
    this.radius,
    this.backgroundColor,
    this.child,
  });

  final String? imageUrl;
  final double? radius;
  final Color? backgroundColor;

  /// يُعرض بدل الصورة (أحرف أولى أو أيقونة) حين لا صورة أو عند فشل تحميلها.
  final Widget? child;

  @override
  State<NetworkCircleAvatar> createState() => _NetworkCircleAvatarState();
}

class _NetworkCircleAvatarState extends State<NetworkCircleAvatar> {
  bool _failed = false;

  @override
  void didUpdateWidget(NetworkCircleAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl;
    final hasImage = url != null && url.isNotEmpty && !_failed;
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: hasImage ? NetworkImage(ApiEndpoints.fileUrl(url)) : null,
      onBackgroundImageError: hasImage
          ? (_, _) {
              if (mounted) setState(() => _failed = true);
            }
          : null,
      child: hasImage ? null : widget.child,
    );
  }
}

/// للحاويات المزخرفة (تدرّج لوني، إطار، شكل) التي لا تناسبها `CircleAvatar`:
/// يبني [builder] بـ `image` جاهزة لـ `BoxDecoration.image`، أو null حين لا
/// صورة أو بعد فشل تحميلها — فيعرض المستدعي بديله (أحرف/أيقونة) عندها.
class NetworkDecorationImage extends StatefulWidget {
  const NetworkDecorationImage({
    super.key,
    required this.imageUrl,
    required this.builder,
    this.fit = BoxFit.cover,
  });

  /// المسار كما يعيده الخادم (يُحوَّل عبر [ApiEndpoints.fileUrl]).
  final String? imageUrl;
  final BoxFit fit;
  final Widget Function(BuildContext context, DecorationImage? image) builder;

  @override
  State<NetworkDecorationImage> createState() => _NetworkDecorationImageState();
}

class _NetworkDecorationImageState extends State<NetworkDecorationImage> {
  bool _failed = false;

  @override
  void didUpdateWidget(NetworkDecorationImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl;
    final hasImage = url != null && url.isNotEmpty && !_failed;
    return widget.builder(
      context,
      hasImage
          ? DecorationImage(
              image: NetworkImage(ApiEndpoints.fileUrl(url)),
              fit: widget.fit,
              onError: (_, _) {
                if (mounted) setState(() => _failed = true);
              },
            )
          : null,
    );
  }
}
