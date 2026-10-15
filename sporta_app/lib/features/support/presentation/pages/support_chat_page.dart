import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../cubit/support_chat_cubit.dart';
import '../widgets/support_message_bubble.dart';

/// دردشة المستخدم مع فريق الدعم — الرسائل تصل فوراً عبر SignalR، والسجل
/// كامل عبر REST حتى لو تعذّر الاتصال الفوري.
class SupportChatPage extends StatelessWidget {
  const SupportChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.appSettings.language.isRtl;
    return BlocProvider(
      create: (_) => getIt<SupportChatCubit>()..load(isArabic: isArabic),
      child: const _SupportChatView(),
    );
  }
}

class _SupportChatView extends StatefulWidget {
  const _SupportChatView();

  @override
  State<_SupportChatView> createState() => _SupportChatViewState();
}

class _SupportChatViewState extends State<_SupportChatView> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// السجل معروض بترتيب زمني، والأحدث في الأسفل — نبقى ملتصقين به.
  void _scrollToBottom() {
    // بعد الإطار: القائمة قد لا تكون رُكّبت بعد عند أول تحميل.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    context.read<SupportChatCubit>().send(
          text,
          isArabic: context.appSettings.language.isRtl,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          BlocBuilder<SupportChatCubit, SupportChatState>(
            buildWhen: (a, b) => a.live != b.live || a.adminTyping != b.adminTyping,
            builder: (context, state) => GradientPageHeader(
              title: context.tr('الدعم الفني'),
              subtitle: state.adminTyping
                  ? context.tr('يكتب الآن…')
                  : state.live
                      ? context.tr('متصل — الردود تصل فوراً')
                      : context.tr('فريق سبورتا يرد عليك هنا'),
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: BlocConsumer<SupportChatCubit, SupportChatState>(
              listenWhen: (a, b) => a.messages.length != b.messages.length,
              listener: (context, state) => _scrollToBottom(),
              builder: (context, state) {
                if (state.status == SupportChatStatus.loading) {
                  return const BrandedLoader();
                }
                if (state.status == SupportChatStatus.failure) {
                  return _ErrorView(
                    message: state.error ?? '',
                    onRetry: () => context.read<SupportChatCubit>().load(),
                  );
                }
                if (state.messages.isEmpty) return const _EmptyView();

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSizes.lg),
                  // صف إضافي في الأعلى لزر "الرسائل الأقدم".
                  itemCount: state.messages.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (state.hasMore && index == 0) {
                      return _LoadOlderButton(
                        loading: state.loadingMore,
                        onTap: () =>
                            context.read<SupportChatCubit>().loadOlder(),
                      );
                    }
                    final msg =
                        state.messages[state.hasMore ? index - 1 : index];
                    return SupportMessageBubble(message: msg);
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _controller,
            onSend: _send,
            onChanged: (_) => context.read<SupportChatCubit>().notifyTyping(),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                maxLength: 4000,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: context.tr('اكتب رسالتك…'),
                  counterText: '',
                  fillColor: AppColors.background,
                ),
              ),
            ),
            SizedBox(width: AppSizes.sm),
            BlocBuilder<SupportChatCubit, SupportChatState>(
              buildWhen: (a, b) => a.sending != b.sending,
              builder: (context, state) => SizedBox(
                width: AppSizes.buttonHeight,
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: state.sending ? null : onSend,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: state.sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: AppSizes.iconSm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadOlderButton extends StatelessWidget {
  const _LoadOlderButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.md),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: onTap,
                child: Text(context.tr('عرض الرسائل الأقدم')),
              ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            SizedBox(height: AppSizes.lg),
            Text(
              context.tr('كيف نقدر نساعدك؟'),
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.sm),
            Text(
              context.tr('اكتب رسالتك وسيرد عليك فريق سبورتا في أقرب وقت.'),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.mutedForeground, size: 40),
            SizedBox(height: AppSizes.md),
            Text(
              message,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.lg),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.tr('إعادة المحاولة')),
            ),
          ],
        ),
      ),
    );
  }
}
