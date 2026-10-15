import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';

/// رُفضت نتيجة مقترحة ولم تُعتمد بعدها نتيجة: خلاف بين الفريقين. المنظّم
/// يحسمه بإدخال النتيجة النهائية مباشرة، والبقية يرون أن الحسم بيده.
class DisputedResultBanner extends StatelessWidget {
  const DisputedResultBanner({
    super.key,
    required this.team1Label,
    required this.team2Label,
    required this.busy,
    this.onResolve,
    this.allowDraw = true,
  });

  final String team1Label;
  final String team2Label;
  final bool busy;

  /// للمنظّم فقط؛ null لغيره.
  final void Function(int team1Score, int team2Score)? onResolve;

  /// البطولة لا تعادل فيها.
  final bool allowDraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.destructive.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gavel_rounded,
                size: AppSizes.iconSm,
                color: AppColors.destructive,
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  context.tr('خلاف على النتيجة — رُفضت النتيجة المقترحة'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            onResolve != null
                ? context.tr(
                    'بصفتك المنظّم يمكنك حسم الخلاف بإدخال النتيجة النهائية',
                  )
                : context.tr(
                    'أدخلوا النتيجة الصحيحة ليؤكدها الفريق الآخر، أو يحسمها المنظّم',
                  ),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          if (onResolve != null) ...[
            const SizedBox(height: AppSizes.sm),
            ElevatedButton.icon(
              onPressed: busy ? null : () => _resolve(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.gavel_rounded, size: 18),
              label: Text(context.tr('حسم النتيجة')),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resolve(BuildContext context) async {
    final result = await showDialog<(int, int)>(
      context: context,
      builder: (_) => _ResolveDialog(
        team1Label: team1Label,
        team2Label: team2Label,
        allowDraw: allowDraw,
      ),
    );
    if (result != null) onResolve?.call(result.$1, result.$2);
  }
}

class _ResolveDialog extends StatefulWidget {
  const _ResolveDialog({
    required this.team1Label,
    required this.team2Label,
    required this.allowDraw,
  });

  final String team1Label;
  final String team2Label;
  final bool allowDraw;

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final _t1 = TextEditingController();
  final _t2 = TextEditingController();
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
    if (!widget.allowDraw && a == b) {
      setState(() => _error = context.tr('لا تعادل في البطولة — حدّد فائزاً'));
      return;
    }
    Navigator.of(context).pop((a, b));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('حسم النتيجة')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              'تُعتمد هذه النتيجة نهائياً دون تأكيد، ويُبلَّغ اللاعبون',
            ),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _row(widget.team1Label, _t1),
          const SizedBox(height: AppSizes.md),
          _row(widget.team2Label, _t2),
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
          child: Text(context.tr('اعتماد النتيجة')),
        ),
      ],
    );
  }

  Widget _row(String label, TextEditingController c) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
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
