import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../../../core/widgets/load_more_listener.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../americano/presentation/pages/americano_detail_page.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../invites/domain/event_invite.dart';
import '../../../invites/presentation/invite_friends.dart';
import '../../domain/entities/match_entity.dart';
import '../cubit/my_events_cubit.dart';
import '../widgets/americano_event_card.dart';
import '../widgets/finished_events_button.dart';
import '../widgets/open_match_card.dart';
import 'match_detail_page.dart';
import 'match_result_entry_page.dart';

/// «عرض الكل»: ما أنشأه المستخدم أو شارك فيه من مباريات / أمريكانو /
/// بطولات — الحالية فقط، الأحدث أولاً، مقسّماً صفحات تُحمَّل بالتمرير.
/// مع [finished] تصير صفحة «المنتهية»: ما انتهى أو أُلغي.
class MyEventsPage extends StatelessWidget {
  const MyEventsPage({super.key, required this.kind, this.finished = false});

  final MyEventsKind kind;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MyEventsCubit>(
      create: (_) =>
          getIt<MyEventsCubit>(param1: kind, param2: finished)..load(),
      child: _View(kind: kind, finished: finished),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.kind, required this.finished});

  final MyEventsKind kind;
  final bool finished;

  String _title(BuildContext context) => finished
      ? finishedEventsTitle(context, kind)
      : switch (kind) {
          MyEventsKind.match => context.tr('مبارياتي'),
          MyEventsKind.americano => context.tr('الأمريكانو الخاص بي'),
          MyEventsKind.tournament => context.tr('بطولاتي'),
        };

  String _empty(BuildContext context) => finished
      ? switch (kind) {
          MyEventsKind.match => context.tr('لا توجد مباريات منتهية'),
          MyEventsKind.americano => context.tr('لا يوجد أمريكانو منتهٍ'),
          MyEventsKind.tournament => context.tr('لا توجد بطولات منتهية'),
        }
      : switch (kind) {
          MyEventsKind.match => context.tr('لا توجد لديك مباريات حالية'),
          MyEventsKind.americano => context.tr('لا يوجد لديك أمريكانو حالي'),
          MyEventsKind.tournament => context.tr('لا توجد لديك بطولات حالية'),
        };

  /// من «عرض الكل» إلى «المنتهية» مباشرة.
  void _openFinished(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MyEventsPage(kind: kind, finished: true),
    ),
  );

  int get _me => int.tryParse(getIt<AuthCubit>().user?.id ?? '') ?? 0;

  Future<void> _openMatch(BuildContext context, MatchEntity m) async {
    final cubit = context.read<MyEventsCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MatchDetailPage(matchId: m.id)),
    );
    cubit.load();
  }

  Future<void> _openEvent(BuildContext context, int id) async {
    final cubit = context.read<MyEventsCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AmericanoDetailPage(
          americanoId: id,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
    cubit.load();
  }

  Future<void> _enterResult(BuildContext context, MatchEntity m) async {
    final cubit = context.read<MyEventsCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchResultEntryPage(
          match: m,
          currentUserId: _me,
          onBack: () => Navigator.of(context).pop(),
          onCompleted: () => Navigator.of(context).pop(),
        ),
      ),
    );
    cubit.load();
  }

  Future<void> _invite(BuildContext context, MatchEntity m) async {
    final cubit = context.read<MyEventsCubit>();
    await inviteFriendsToEvent(
      context,
      kind: InviteKind.match,
      targetId: m.id,
      startsAt: m.scheduledAt,
      maxCount: m.spotsLeft,
    );
    cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientPageHeader(
            title: _title(context),
            onBack: () => Navigator.of(context).pop(),
            trailing: finished
                ? null
                : [
                    TextButton.icon(
                      onPressed: () => _openFinished(context),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: Text(context.tr('المنتهية')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onSecondary,
                        backgroundColor: AppColors.onSecondary.withValues(
                          alpha: 0.12,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ],
          ),
          Expanded(
            child: BlocBuilder<MyEventsCubit, MyEventsState>(
              builder: (context, state) => switch (state.status) {
                MyEventsStatus.initial ||
                MyEventsStatus.loading => const SkeletonList(itemCount: 5),
                MyEventsStatus.failure => _error(context, state.error),
                MyEventsStatus.success => _list(context, state),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(BuildContext context, String? error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSizes.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.destructive,
            size: 48,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            error ?? context.tr('تعذّر التحميل'),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.lg),
          ElevatedButton(
            onPressed: () => context.read<MyEventsCubit>().load(),
            child: Text(context.tr('إعادة المحاولة')),
          ),
        ],
      ),
    ),
  );

  Widget _list(BuildContext context, MyEventsState state) {
    if (state.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                finished ? Icons.history_rounded : Icons.emoji_events_outlined,
                color: AppColors.mutedForeground,
                size: 56,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                _empty(context),
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final cubit = context.read<MyEventsCubit>();
    final count = kind == MyEventsKind.match
        ? state.matches.length
        : state.events.length;
    return LoadMoreListener(
      onLoadMore: cubit.loadMore,
      child: RefreshIndicator(
        onRefresh: cubit.load,
        child: ListView.separated(
          padding: context.safeBottom(
            const EdgeInsets.all(AppSizes.pagePadding),
          ),
          itemCount: count + (state.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.lg),
          itemBuilder: (context, i) {
            if (i >= count) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (kind == MyEventsKind.match) {
              final m = state.matches[i];
              return OpenMatchCard(
                match: m,
                currentUserId: _me,
                onJoin: (m) => _openMatch(context, m),
                onEnterResult: (m) => _enterResult(context, m),
                onInvite: (m) => _invite(context, m),
                onOpenDetails: (m) => _openMatch(context, m),
              );
            }
            final a = state.events[i];
            return AmericanoEventCard(
              event: a,
              currentUserId: _me,
              onOpen: (e) => _openEvent(context, e.id),
              // كلها تخصّني فلا يظهر زر انضمام؛ احتياطاً يفتح التفاصيل.
              onJoin: (e) => _openEvent(context, e.id),
            );
          },
        ),
      ),
    );
  }
}
