import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/event_chat.dart';
import 'reaction_glyph.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

/// نص المعاينة لرسالة (للاقتباس والرد): النص، أو «📷 صورة» / «📎 ملف».
String chatPreviewText(
  BuildContext context,
  String body,
  String? attachmentType,
) {
  if (body.isNotEmpty) return body;
  return switch (attachmentType) {
    'image' => context.tr('صورة'),
    'file' => context.tr('ملف'),
    _ => context.tr('حُذفت هذه الرسالة'),
  };
}

/// فقاعة رسالة كواتساب: اقتباس الرد، والمرفق (صورة أو بطاقة ملف)، والنص
/// بإبراز الإشارات @، والوقت، وحبّة التفاعلات أسفلها.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.showHeader,
    required this.me,
    required this.members,
    this.onOpenAttachment,
    this.onReactionsTap,
    this.elevated = false,
  });

  final EventChatMessage message;
  final bool mine;

  /// الاسم والصورة على أول رسالة من تتابع رسائل الشخص نفسه.
  final bool showHeader;
  final int me;
  final List<EventChatMember> members;
  final void Function(EventChatAttachment)? onOpenAttachment;
  final VoidCallback? onReactionsTap;

  /// ظلّ — للفقاعة المعروضة في قائمة الضغطة المطوّلة.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final radius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(16),
      topEnd: const Radius.circular(16),
      bottomStart: Radius.circular(mine ? 16 : 4),
      bottomEnd: Radius.circular(mine ? 4 : 16),
    );
    final hasReactions = m.reactions.isNotEmpty;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!mine && showHeader)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    m.senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (m.senderRole == 'organizer' || m.senderRole == 'venue') ...[
                  const SizedBox(width: 6),
                  ChatRoleTag(role: m.senderRole!, small: true),
                ],
              ],
            ),
          ),
        if (m.replyTo != null && !m.isDeleted) _quote(context, m.replyTo!),
        if (m.isDeleted)
          Text(
            context.tr('حُذفت هذه الرسالة'),
            style: AppTextStyles.bodySmall.copyWith(
              fontStyle: FontStyle.italic,
              color: mine ? Colors.white70 : AppColors.mutedForeground,
            ),
          )
        else ...[
          if (m.attachment != null) _attachment(context, m.attachment!),
          if (m.body.isNotEmpty) ...[
            if (m.attachment != null) const SizedBox(height: 4),
            _richBody(context),
          ],
        ],
        const SizedBox(height: 2),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            AppDates.time12(m.createdAt),
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: mine ? Colors.white70 : AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    );

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.74,
      ),
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 5),
      decoration: BoxDecoration(
        color: mine ? AppColors.primary : Colors.white,
        borderRadius: radius,
        border: mine ? null : Border.all(color: AppColors.border),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: content,
    );

    final withReactions = hasReactions
        ? Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                bubble,
                PositionedDirectional(
                  bottom: -14,
                  end: 10,
                  child: _ReactionsPill(
                    message: m,
                    me: me,
                    onTap: onReactionsTap,
                  ),
                ),
              ],
            ),
          )
        : bubble;

    return Padding(
      padding: EdgeInsets.only(top: showHeader ? AppSizes.sm : 2),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: elevated ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (!mine && !elevated) ...[
            showHeader
                ? ChatAvatar(
                    name: m.senderName,
                    url: m.senderAvatarUrl,
                    role: m.senderRole ?? 'player',
                    size: 30,
                  )
                : const SizedBox(width: 30),
            const SizedBox(width: 6),
          ],
          Flexible(child: withReactions),
        ],
      ),
    );
  }

  Widget _quote(BuildContext context, EventChatReply r) {
    final fg = mine ? Colors.white : const Color(0xFF1E9AB0);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: mine
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFF1FAFC),
        borderRadius: BorderRadius.circular(6),
        border: BorderDirectional(start: BorderSide(color: fg, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.senderName,
            maxLines: 1,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            r.isDeleted
                ? context.tr('حُذفت هذه الرسالة')
                : chatPreviewText(context, r.body, r.attachmentType),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11.5,
              color: mine ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachment(BuildContext context, EventChatAttachment a) {
    if (a.isImage) {
      return GestureDetector(
        onTap: onOpenAttachment == null ? null : () => onOpenAttachment!(a),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, minWidth: 160),
            child: Image.network(
              ApiEndpoints.fileUrl(a.url),
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      width: 200,
                      height: 150,
                      color: AppColors.muted,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
              errorBuilder: (_, _, _) => Container(
                width: 200,
                height: 120,
                color: AppColors.muted,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return ChatFileCard(
      name: a.name,
      size: a.size,
      mine: mine,
      onTap: onOpenAttachment == null ? null : () => onOpenAttachment!(a),
    );
  }

  /// النص مع إبراز «@الاسم» للأعضاء المشار إليهم.
  Widget _richBody(BuildContext context) {
    final m = message;
    final base = AppTextStyles.bodySmall.copyWith(
      color: mine ? Colors.white : AppColors.foreground,
      height: 1.45,
    );
    final names = <String>{
      for (final mem in members)
        if (m.mentionedUserIds.contains(mem.userId))
          '@${mem.name.split(' ').first}',
    };
    if (names.isEmpty) return Text(m.body, style: base);

    final pattern = RegExp(names.map(RegExp.escape).join('|'));
    final spans = <TextSpan>[];
    var last = 0;
    for (final match in pattern.allMatches(m.body)) {
      if (match.start > last)
        spans.add(TextSpan(text: m.body.substring(last, match.start)));
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: mine ? Colors.white : const Color(0xFF1E9AB0),
            decoration: mine ? TextDecoration.underline : null,
            decorationColor: Colors.white,
          ),
        ),
      );
      last = match.end;
    }
    if (last < m.body.length) spans.add(TextSpan(text: m.body.substring(last)));
    return Text.rich(TextSpan(style: base, children: spans));
  }
}

/// بطاقة ملف داخل الفقاعة: نوعه واسمه وحجمه وزر تنزيل.
class ChatFileCard extends StatelessWidget {
  const ChatFileCard({
    super.key,
    required this.name,
    required this.size,
    required this.mine,
    required this.onTap,
  });

  final String name;
  final int size;
  final bool mine;
  final VoidCallback? onTap;

  static String formatSize(int bytes) {
    if (bytes >= 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    final ext = name.contains('.')
        ? name.split('.').last.toUpperCase()
        : 'FILE';
    final badge = switch (ext) {
      'PDF' => (const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
      'DOC' || 'DOCX' => (const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
      'XLS' ||
      'XLSX' ||
      'CSV' => (const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: mine
              ? Colors.white.withValues(alpha: 0.18)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: mine ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badge.$1,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ext.length > 4 ? ext.substring(0, 4) : ext,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: badge.$2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: mine ? Colors.white : AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    formatSize(size),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: mine ? Colors.white70 : AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download_rounded,
              size: 20,
              color: mine ? Colors.white : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionsPill extends StatelessWidget {
  const _ReactionsPill({required this.message, required this.me, this.onTap});

  final EventChatMessage message;
  final int me;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final total = message.reactions.fold<int>(
      0,
      (s, r) => s + r.userIds.length,
    );
    final mineReacted = message.reactionOf(me) != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: mineReacted ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in message.reactions.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: ReactionGlyph(emoji: r.emoji, size: 14),
              ),
            if (total > 1) ...[
              const SizedBox(width: 3),
              Text(
                '$total',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// شارة الدور: ذهبية للمنظّم، برتقالية للملعب.
class ChatRoleTag extends StatelessWidget {
  const ChatRoleTag({super.key, required this.role, this.small = false});

  final String role;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final venue = role == 'venue';
    final fg = venue ? const Color(0xFF9A3412) : const Color(0xFF8A6A00);
    final bg = venue ? const Color(0xFFFFEDD5) : const Color(0xFFFBF0CC);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        venue ? context.tr('الملعب') : context.tr('المنظّم'),
        style: AppTextStyles.caption.copyWith(
          fontSize: small ? 10 : 11,
          color: fg,
        ),
      ),
    );
  }
}

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.name,
    required this.url,
    required this.role,
    required this.size,
    this.ring = false,
  });

  final String name;
  final String? url;
  final String role;
  final double size;

  /// حلقة بلون الرأس — للصور المتراكبة فيه.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (role) {
      'organizer' => (const Color(0xFFFBF0CC), const Color(0xFF8A6A00)),
      'venue' => (const Color(0xFFFFEDD5), const Color(0xFF9A3412)),
      _ => (const Color(0xFFE3F6FA), const Color(0xFF1E9AB0)),
    };
    final initial = name.trim().isEmpty ? '؟' : name.trim().characters.first;
    // الأيقونة/الحرف بديل أيضاً حين يفشل تحميل الصورة.
    return NetworkDecorationImage(
      imageUrl: url,
      builder: (_, image) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border:
              ring ? Border.all(color: AppColors.secondary, width: 2) : null,
          image: image,
        ),
        alignment: Alignment.center,
        child: image != null
            ? null
            : role == 'venue'
            ? Icon(Icons.stadium_outlined, size: size * 0.5, color: fg)
            : Text(
                initial,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.4,
                ),
              ),
      ),
    );
  }
}
