import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/server_time.dart';
import '../../domain/entities/cup_entity.dart';
import '../../../matches/presentation/widgets/pending_result_banner.dart';
import '../../../matches/presentation/widgets/disputed_result_banner.dart';

/// بطاقة مباراة: الطرفان (أو مكانهما المنتظر)، النتيجة، الملعب والموعد،
/// وزر إدخال النتيجة للاعبي الطرفين — تُعتمد بتأكيد لاعب من الفريق الآخر.
/// الفائز يُبرَز بخلفية خضراء كما في التصميم.
class CupFixtureCard extends StatelessWidget {
  const CupFixtureCard({
    super.key,
    required this.fixture,
    required this.saving,
    required this.onSubmit,
    this.myTeam,
    this.onRespond,
    this.onResolve,
    this.onRecord,
    this.eventStart,
    this.showRound = false,
    this.label,
  });

  final CupFixture fixture;

  /// فريق المستخدم في البطولة؛ يُدخل النتيجة إن كان طرفاً في المباراة
  /// وهي قابلة للتسجيل (طرفاها معروفان ولم تُقفل).
  final int? myTeam;
  final bool saving;
  final void Function(int team1Score, int team2Score) onSubmit;

  /// تأكيد/رفض نتيجة مقترحة (للاعب من الفريق الآخر).
  final void Function(bool accept)? onRespond;

  /// للمنظّم فقط: حسم خلاف على النتيجة.
  final void Function(int team1Score, int team2Score)? onResolve;

  /// للمنظّم فقط: تسجيل النتيجة نهائيةً بعد مرور موعد المباراة، أو فوز
  /// بالانسحاب ([walkover]) عند غياب فريق.
  final void Function(int team1Score, int team2Score, bool walkover)? onRecord;

  /// موعد البطولة — بديل موعد المباراة إن لم يُحدَّد لها موعد (كالخادم).
  final DateTime? eventStart;

  /// يعرض اسم الدور/المجموعة فوق البطاقة (في قوائم مختلطة).
  final bool showRound;

  /// عنوان صريح للبطاقة يتقدّم على [showRound] (مثل «الجولة 2» تحت عنوان مجموعتها).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final f = fixture;
    final mySide = f.sideOf(myTeam);
    final start = f.scheduledAt ?? eventStart;
    // المنظّم يحسم مباراة مرّ موعدها بلا اعتماد؛ الخلاف له شريطه الخاص.
    final organizerRecord =
        onRecord != null &&
        f.isReady &&
        !f.isBye &&
        !f.isCompleted &&
        !f.isDisputed &&
        start != null &&
        !start.isAfter(ksaNow());
    // لا زرّان لإدخال النتيجة إن كان المنظّم طرفاً فيها — يكفي زرّ الاعتماد.
    final editable = mySide != null && f.canScore && !organizerRecord;
    final pending = f.pendingResult;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: f.isCompleted
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label ??
                      (showRound
                          ? (f.isGroup
                                ? '${context.trArgs('المجموعة {p0}', {'p0': f.groupLetter ?? ''})} · ${f.roundName}'
                                : '${f.roundName} · ${f.title}')
                          : f.title),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (f.isBye)
                _chip(context, context.tr('إعفاء'), AppColors.mutedForeground)
              else if (f.isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: AppSizes.iconSm,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          _side(
            context,
            f.team1Name,
            f.team1Players,
            f.team1Placeholder,
            f.team1Score,
            f.isCompleted && f.winnerTeam != null && f.winnerTeam == f.team1,
          ),
          const SizedBox(height: AppSizes.xs),
          _side(
            context,
            f.team2Name,
            f.team2Players,
            f.team2Placeholder,
            f.team2Score,
            f.isCompleted && f.winnerTeam != null && f.winnerTeam == f.team2,
          ),
          if (f.scheduledAt != null || f.courtName != null) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: AppSizes.xs),
                Expanded(
                  child: Text(
                    [
                      if (f.scheduledAt != null)
                        '${AppDates.dayMonth(f.scheduledAt!)} ${AppDates.time12(f.scheduledAt!)}',
                      if (f.courtName != null) f.courtName!,
                    ].join(' · '),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (pending == null && f.isDisputed) ...[
            const SizedBox(height: AppSizes.sm),
            DisputedResultBanner(
              team1Label: f.team1Name,
              team2Label: f.team2Name,
              busy: saving,
              allowDraw: false,
              onResolve: onResolve,
            ),
          ],
          if (pending != null) ...[
            const SizedBox(height: AppSizes.sm),
            PendingResultBanner(
              pending: pending,
              team1Label: f.team1Name,
              team2Label: f.team2Name,
              canRespond: onRespond != null && pending.canRespond(mySide),
              busy: saving,
              onRespond: (accept) => onRespond?.call(accept),
            ),
          ],
          if (organizerRecord) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: saving ? null : () => _recordScore(context),
                      icon: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.edit_outlined, size: 16),
                      label: Text(
                        context.tr('تسجيل النتيجة'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: saving ? null : () => _recordWalkover(context),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: Text(
                        context.tr('فوز بالانسحاب'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (editable) ...[
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: saving ? null : () => _enterScore(context),
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined, size: 16),
                label: Text(
                  context.tr(
                    f.isCompleted || pending != null
                        ? 'تعديل النتيجة'
                        : 'تسجيل النتيجة',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _side(
    BuildContext context,
    String name,
    String players,
    String? placeholder,
    int? score,
    bool winner,
  ) {
    final known = name.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: winner
            ? AppColors.success.withValues(alpha: 0.12)
            : known
            ? AppColors.background
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: winner
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.border,
          style: known ? BorderStyle.solid : BorderStyle.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  known ? name : (placeholder ?? '—'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: known
                        ? AppColors.secondary
                        : AppColors.mutedForeground,
                    fontWeight: winner ? FontWeight.w800 : FontWeight.w700,
                    fontStyle: known ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
                if (known && players.isNotEmpty)
                  Text(
                    players,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          if (score != null)
            Text(
              '$score',
              style: AppTextStyles.body.copyWith(
                color: winner ? AppColors.success : AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    ),
    child: Text(label, style: AppTextStyles.caption.copyWith(color: color)),
  );

  Future<void> _enterScore(BuildContext context) async {
    final result = await showDialog<(int, int)>(
      context: context,
      builder: (_) => _ScoreDialog(fixture: fixture),
    );
    if (result != null) onSubmit(result.$1, result.$2);
  }

  /// المنظّم يُدخل نتيجة الطرفين فتُعتمد نهائيةً.
  Future<void> _recordScore(BuildContext context) async {
    final result = await showDialog<(int, int)>(
      context: context,
      builder: (_) =>
          _ScoreDialog(fixture: fixture, submitLabel: 'اعتماد النتيجة'),
    );
    if (result != null) onRecord?.call(result.$1, result.$2, false);
  }

  /// المنظّم يختار الفريق الفائز إدارياً (غياب الآخر): 6-0 أو 0-6.
  Future<void> _recordWalkover(BuildContext context) async {
    final winner = await showDialog<int>(
      context: context,
      builder: (_) => _WalkoverDialog(fixture: fixture),
    );
    if (winner == 1) onRecord?.call(6, 0, true);
    if (winner == 2) onRecord?.call(0, 6, true);
  }
}

/// حوار الفوز بالانسحاب: اختيار الفريق الفائز (1 أو 2) ثم التأكيد.
class _WalkoverDialog extends StatefulWidget {
  const _WalkoverDialog({required this.fixture});

  final CupFixture fixture;

  @override
  State<_WalkoverDialog> createState() => _WalkoverDialogState();
}

class _WalkoverDialogState extends State<_WalkoverDialog> {
  int? _winner;

  @override
  Widget build(BuildContext context) {
    final f = widget.fixture;
    return AlertDialog(
      title: Text(context.tr('فوز بالانسحاب')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              'اختر الفريق الفائز — يُسجَّل له فوز إداري 6-0 دون نقاط مستوى.',
            ),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          _option(1, f.team1Name, f.team1Players),
          _option(2, f.team2Name, f.team2Players),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('إلغاء')),
        ),
        ElevatedButton(
          onPressed: _winner == null
              ? null
              : () => Navigator.of(context).pop(_winner),
          child: Text(context.tr('تأكيد')),
        ),
      ],
    );
  }

  Widget _option(int side, String name, String players) {
    final selected = _winner == side;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => setState(() => _winner = side),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? AppColors.primary : AppColors.mutedForeground,
      ),
      title: Text(
        name,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: players.isEmpty
          ? null
          : Text(
              players,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
    );
  }
}

/// حوار النتيجة: رقمان، ولا تعادل في البطولة.
class _ScoreDialog extends StatefulWidget {
  const _ScoreDialog({
    required this.fixture,
    this.submitLabel = 'إرسال النتيجة للتأكيد',
  });

  final CupFixture fixture;

  /// مفتاح ترجمة زرّ الحفظ (المنظّم يعتمد مباشرةً).
  final String submitLabel;

  @override
  State<_ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<_ScoreDialog> {
  late final _t1 = TextEditingController(
    text:
        (widget.fixture.pendingResult?.team1Score ?? widget.fixture.team1Score)
            ?.toString() ??
        '',
  );
  late final _t2 = TextEditingController(
    text:
        (widget.fixture.pendingResult?.team2Score ?? widget.fixture.team2Score)
            ?.toString() ??
        '',
  );
  String? _error;

  @override
  void dispose() {
    _t1.dispose();
    _t2.dispose();
    super.dispose();
  }

  void _save() {
    final a = int.tryParse(_t1.text.trim());
    final b = int.tryParse(_t2.text.trim());
    if (a == null || b == null) {
      setState(() => _error = context.tr('أدخل نتيجة الفريقين'));
      return;
    }
    if (a == b) {
      setState(() => _error = context.tr('لا تعادل في البطولة — حدّد فائزاً'));
      return;
    }
    Navigator.of(context).pop((a, b));
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fixture;
    return AlertDialog(
      title: Text(
        f.isGroup
            ? '${context.trArgs('المجموعة {p0}', {'p0': f.groupLetter ?? ''})} · ${f.title}'
            : '${f.roundName} · ${f.title}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(f.team1Name, f.team1Players, _t1),
          const SizedBox(height: AppSizes.md),
          _row(f.team2Name, f.team2Players, _t2),
          if (_error != null) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              _error!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.destructive,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('إلغاء')),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(context.tr(widget.submitLabel)),
        ),
      ],
    );
  }

  Widget _row(String name, String players, TextEditingController c) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (players.isNotEmpty)
              Text(
                players,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(width: AppSizes.md),
      SizedBox(
        width: 64,
        child: TextField(
          controller: c,
          autofocus: c == _t1,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: '0'),
        ),
      ),
    ],
  );
}
