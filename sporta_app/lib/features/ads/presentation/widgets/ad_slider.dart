import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../data/ad_repository.dart';
import '../../domain/ad_entity.dart';
import '../pages/ad_detail_page.dart';

/// أماكن ظهور الإعلانات المعروفة — تُرسل كـ `?page=` للسيرفر ويُطابقها حقل
/// `Placements` في لوحة التحكم.
class AdPlacements {
  static const String home = 'home';
  static const String courts = 'courts';
  static const String matches = 'matches';
  static const String coaches = 'coaches';
}

/// بانر إعلانات يُحمّل إعلانات صفحة بعينها بنفسه ويخفي نفسه تمامًا إن لم توجد
/// إعلانات لتلك الصفحة (أو فشل التحميل)، فلا يترك فراغًا في التصميم.
class AdBannerSection extends StatefulWidget {
  const AdBannerSection({
    super.key,
    required this.page,
    this.onNavigate,
    this.padding = const EdgeInsets.only(bottom: AppSizes.xxl),
  });

  /// اسم الصفحة من [AdPlacements].
  final String page;

  /// للتنقّل لتبويب آخر عند الضغط على الإعلان (اختياري).
  final void Function(String page)? onNavigate;

  final EdgeInsetsGeometry padding;

  @override
  State<AdBannerSection> createState() => _AdBannerSectionState();
}

class _AdBannerSectionState extends State<AdBannerSection> {
  List<AdEntity> _ads = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await getIt<AdRepository>().fetchAds(page: widget.page);
      if (!mounted) return;
      setState(() => _ads = items);
    } catch (_) {
      // صامت: البانر اختياري ويختفي إن تعذّر تحميله.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ads.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: widget.padding,
      child: AdSlider(ads: _ads, onNavigate: widget.onNavigate),
    );
  }
}

/// Auto-rotating promo banner driven by `/api/ads`: full-bleed image,
/// bottom-up black gradient so the white text reads, and a circular "enter"
/// icon. Tapping a slide opens [AdDetailPage] for that ad.
class AdSlider extends StatefulWidget {
  const AdSlider({super.key, required this.ads, this.onNavigate});

  final List<AdEntity> ads;
  final void Function(String page)? onNavigate;

  @override
  State<AdSlider> createState() => _AdSliderState();
}

class _AdSliderState extends State<AdSlider> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  // Fallback background colors used while/if an ad image fails to load.
  static const _fallbacks = [
    Color(0xFF0A2540), Color(0xFF166534), Color(0xFF7C2D12),
    Color(0xFF3730A3), Color(0xFF9D174D),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ads.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_index + 1) % widget.ads.length;
        _controller.animateToPage(next,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _open(AdEntity ad) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdDetailPage(ad: ad, onNavigate: widget.onNavigate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.ads.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) =>
                _slide(widget.ads[i], _fallbacks[i % _fallbacks.length]),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.ads.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _index
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _slide(AdEntity s, Color fallback) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: GestureDetector(
          onTap: () => _open(s),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image with a solid-color fallback (so it always looks designed).
              Image.network(
                ApiEndpoints.fileUrl(s.imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(color: fallback),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : ColoredBox(color: fallback),
              ),
              // Bottom-up black gradient so the text reads — only when there
              // is text; an image-only ad shows the picture untouched.
              if (s.title.isNotEmpty || s.subtitle.isNotEmpty)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xE6000000), Color(0x00000000)],
                    stops: [0.0, 0.75],
                  ),
                ),
              ),
              if (s.title.isNotEmpty || s.subtitle.isNotEmpty)
              PositionedDirectional(
                start: AppSizes.lg,
                end: AppSizes.lg,
                bottom: AppSizes.lg,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (s.title.isNotEmpty)
                            Text(s.title,
                                style: AppTextStyles.heading3
                                    .copyWith(color: Colors.white)),
                          if (s.title.isNotEmpty && s.subtitle.isNotEmpty)
                            const SizedBox(height: 2),
                          if (s.subtitle.isNotEmpty)
                            Text(s.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9))),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: DirectionalIcon(
                        rtl: Icons.arrow_back,
                        ltr: Icons.arrow_forward,
                        size: AppSizes.iconMd,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
