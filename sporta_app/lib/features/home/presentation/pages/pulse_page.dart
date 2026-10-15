import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../matches/presentation/pages/match_detail_page.dart';
import '../../data/pulse_repository.dart';
import '../../domain/pulse_item.dart';
import '../widgets/pulse_section.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';

/// Full community-pulse list — the "عرض الكل" target of the dashboard section.
class PulsePage extends StatefulWidget {
  const PulsePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<PulsePage> createState() => _PulsePageState();
}

class _PulsePageState extends State<PulsePage> {
  final _repo = getIt<PulseRepository>();

  List<PulseItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repo.fetchPulse();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.display;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = trg('تعذّر تحميل النشاط');
        _loading = false;
      });
    }
  }

  void _openMatch(int id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MatchDetailPage(matchId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _header(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding,
              AppSizes.xxxl, AppSizes.pagePadding, AppSizes.xxl),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const DirectionalIcon(
                    rtl: Icons.arrow_forward,
                    ltr: Icons.arrow_back,
                    color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSizes.md),
              Text(context.tr('نبض المجتمع الرياضي'),
                  style: AppTextStyles.heading2.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const SkeletonList();

    if (_error != null) {
      return Center(
        child: Text(_error!,
            style: AppTextStyles.body.copyWith(color: AppColors.secondary)),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monitor_heart_outlined,
                  color: AppColors.mutedForeground, size: 56),
              const SizedBox(height: AppSizes.md),
              Text(context.tr('لا يوجد نشاط في المجتمع بعد'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.mutedForeground)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
      itemBuilder: (_, i) => PulseTile(item: _items[i], onOpenMatch: _openMatch),
    );
  }
}
