import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/event_chat.dart';
import '../cubit/event_chat_cubit.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/reaction_glyph.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// دردشة أعضاء الحدث: اللاعبون المعتمدون والمنظّم (وصاحب الملعب فقط إن كان
/// منشئاً أو مشاركاً). تصير للقراءة فقط بعد انتهاء الحدث. [matchId] معرّف
/// المباراة الأساسية — للأمريكانو والبطولة `matchId` في كيانهما.
///
/// كواتساب: صور وملفات، رد على رسالة (ضغطة مطوّلة أو سحب جانبي)، إشارة @،
/// وتفاعل برمز واحد لكل عضو.
class EventChatPage extends StatelessWidget {
  const EventChatPage({super.key, required this.matchId});

  final int matchId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EventChatCubit>(
      create: (_) => getIt<EventChatCubit>(param1: matchId)..load(),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  /// الإشارات المختارة في الرسالة الجارية (المعرّف ← الاسم كما كُتب).
  final Map<int, String> _mentions = {};

  /// نص البحث بعد @ عند المؤشر؛ null = لا اقتراحات.
  String? _mentionQuery;

  int get _me => int.tryParse(getIt<AuthCubit>().user?.id ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _input.addListener(_onTextChanged);
    // القائمة معكوسة (الأحدث أسفل)، فنهاية التمرير هي أقدم الرسائل.
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<EventChatCubit>().loadOlder();
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── الإشارة @ ───────────────────────────────────────────────────────────────

  void _onTextChanged() {
    final sel = _input.selection;
    final text = _input.text;
    String? query;
    if (sel.isValid && sel.isCollapsed) {
      final before = text.substring(0, sel.baseOffset);
      final at = before.lastIndexOf('@');
      if (at >= 0 &&
          (at == 0 || before[at - 1] == ' ' || before[at - 1] == '\n')) {
        final q = before.substring(at + 1);
        if (!q.contains('\n') && q.length <= 20) query = q;
      }
    }
    setState(() => _mentionQuery = query);
  }

  void _pickMention(EventChatMember m) {
    final sel = _input.selection;
    final text = _input.text;
    final before = text.substring(0, sel.baseOffset);
    final at = before.lastIndexOf('@');
    final first = m.name.split(' ').first;
    final inserted = '@$first ';
    final next = text.replaceRange(at, sel.baseOffset, inserted);
    _mentions[m.userId] = first;
    _input.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: at + inserted.length),
    );
    setState(() => _mentionQuery = null);
  }

  /// إشارة من قائمة الضغطة المطوّلة: تُلحق «@الاسم » بالحقل.
  void _mentionFromMessage(EventChatMessage m) {
    if (m.senderUserId == null || m.senderUserId == _me) return;
    final first = m.senderName.split(' ').first;
    _mentions[m.senderUserId!] = first;
    final text = _input.text;
    final sep = text.isEmpty || text.endsWith(' ') ? '' : ' ';
    _input.text = '$text$sep@$first ';
    _input.selection = TextSelection.collapsed(offset: _input.text.length);
    _focus.requestFocus();
  }

  // ── الإرسال ─────────────────────────────────────────────────────────────────

  Future<void> _send([String? quick]) async {
    final text = quick ?? _input.text;
    if (text.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    // تبقى فقط الإشارات التي ما زال اسمها في النص.
    final mentions = [
      for (final e in _mentions.entries)
        if (text.contains('@${e.value}')) e.key,
    ];
    if (quick == null) _input.clear();
    final error = await context.read<EventChatCubit>().send(
      text,
      mentionedUserIds: mentions,
    );
    if (error != null) {
      if (quick == null) _input.text = text;
      messenger.showSnackBar(SnackBar(content: Text(error)));
    } else {
      if (quick == null) _mentions.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // ── المرفقات ────────────────────────────────────────────────────────────────

  Future<void> _openAttachSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.md,
            AppSizes.lg,
            AppSizes.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                sheet.tr('إرفاق'),
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttachOption(
                    icon: Icons.photo_camera_outlined,
                    label: sheet.tr('الكاميرا'),
                    bg: const Color(0xFFE3F6FA),
                    fg: const Color(0xFF1E9AB0),
                    onTap: () => Navigator.pop(sheet, 'camera'),
                  ),
                  _AttachOption(
                    icon: Icons.photo_library_outlined,
                    label: sheet.tr('الصور'),
                    bg: const Color(0xFFEDE9FE),
                    fg: const Color(0xFF7C3AED),
                    onTap: () => Navigator.pop(sheet, 'gallery'),
                  ),
                  _AttachOption(
                    icon: Icons.description_outlined,
                    label: sheet.tr('ملف'),
                    bg: const Color(0xFFFEE2E2),
                    fg: const Color(0xFFDC2626),
                    onTap: () => Navigator.pop(sheet, 'file'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              Center(
                child: Text(
                  sheet.tr('الحد الأقصى 10 م.ب · صور و PDF ومستندات'),
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'file') {
      await _pickFile();
    } else {
      await _pickImage(
        choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final img = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (img == null || !mounted) return;
      await _confirmAndSend(img.path, img.name, isImage: true);
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('تعذّر فتح الكاميرا أو الصور — تحقق من الأذونات'),
          ),
        ),
      );
    }
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
        'csv',
        'jpg',
        'jpeg',
        'png',
        'webp',
        'heic',
      ],
    );
    final f = res?.files.single;
    if (f == null || f.path == null || !mounted) return;
    if (f.size > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('حجم الملف كبير (الحد 10 ميجا)'))),
      );
      return;
    }
    final ext = f.name.split('.').last.toLowerCase();
    await _confirmAndSend(
      f.path!,
      f.name,
      isImage: const ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext),
      size: f.size,
    );
  }

  /// معاينة قبل الإرسال مع تعليق اختياري — كواتساب.
  Future<void> _confirmAndSend(
    String path,
    String name, {
    required bool isImage,
    int? size,
  }) async {
    final caption = TextEditingController(text: _input.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        contentPadding: const EdgeInsets.all(AppSizes.md),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: Image.file(File(path), fit: BoxFit.cover),
                ),
              )
            else
              ChatFileCard(
                name: name,
                size: size ?? 0,
                onTap: null,
                mine: false,
              ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: caption,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: dialog.tr('أضف تعليقاً (اختياري)'),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(dialog.tr('إلغاء')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialog, true),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(dialog.tr('إرسال')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<EventChatCubit>().sendAttachment(
      path,
      name,
      caption: caption.text,
    );
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    } else {
      if (caption.text.isNotEmpty) _input.clear();
      _scrollToBottom();
    }
  }

  // ── الضغطة المطوّلة ─────────────────────────────────────────────────────────

  Future<void> _onLongPress(EventChatMessage m, EventChatSummary s) async {
    if (m.isSystem || m.isDeleted) return;
    HapticFeedback.mediumImpact();
    final mine = m.senderUserId == _me;
    final canDelete = mine || s.canModerate;
    final myReaction = m.reactionOf(_me);

    final action = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'menu',
      barrierColor: const Color(0x730A2540),
      transitionDuration: const Duration(milliseconds: 160),
      // Material شفاف: بدونه ترسم النصوص بخط أصفر تحتها (لا سلف Material).
      pageBuilder: (dialog, _, _) => Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: mine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // شريط التفاعل السريع.
                  if (s.canWrite)
                    Material(
                      color: Colors.white,
                      elevation: 6,
                      shape: const StadiumBorder(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final e in kChatReactions)
                              InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => Navigator.pop(dialog, 'react:$e'),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: myReaction == e
                                        ? AppColors.primary.withValues(
                                            alpha: 0.15,
                                          )
                                        : null,
                                  ),
                                  child: ReactionGlyph(emoji: e, size: 28),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSizes.sm),
                  IgnorePointer(
                    child: ChatMessageBubble(
                      message: m,
                      mine: mine,
                      showHeader: true,
                      me: _me,
                      members: s.members,
                      elevated: true,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Material(
                    color: Colors.white,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: 220,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (s.canWrite)
                            _MenuItem(
                              icon: Icons.reply_rounded,
                              label: dialog.tr('رد'),
                              onTap: () => Navigator.pop(dialog, 'reply'),
                            ),
                          if (s.canWrite && !mine && m.senderUserId != null)
                            _MenuItem(
                              icon: Icons.alternate_email_rounded,
                              label: dialog.trArgs('إشارة إلى {p0}', {
                                'p0': m.senderName.split(' ').first,
                              }),
                              onTap: () => Navigator.pop(dialog, 'mention'),
                            ),
                          if (m.body.isNotEmpty)
                            _MenuItem(
                              icon: Icons.copy_rounded,
                              label: dialog.tr('نسخ'),
                              onTap: () => Navigator.pop(dialog, 'copy'),
                            ),
                          if (canDelete)
                            _MenuItem(
                              icon: Icons.delete_outline,
                              label: dialog.tr('حذف'),
                              danger: true,
                              onTap: () => Navigator.pop(dialog, 'delete'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    final cubit = context.read<EventChatCubit>();
    final messenger = ScaffoldMessenger.of(context);
    if (action.startsWith('react:')) {
      final error = await cubit.react(m, action.substring(6), _me);
      if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
    } else if (action == 'reply') {
      cubit.startReply(m);
      _focus.requestFocus();
    } else if (action == 'mention') {
      _mentionFromMessage(m);
    } else if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: m.body));
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('نُسخت الرسالة'))),
      );
    } else if (action == 'delete') {
      final error = await cubit.delete(m);
      if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  /// من تفاعل مع الرسالة، بأسماء الأعضاء.
  void _showReactors(EventChatMessage m, EventChatSummary s) {
    final names = {for (final mem in s.members) mem.userId: mem.name};
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheet.tr('التفاعلات'),
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              for (final r in m.reactions)
                for (final uid in r.userIds)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: ReactionGlyph(emoji: r.emoji, size: 24),
                    title: Text(
                      uid == _me
                          ? sheet.tr('أنت')
                          : (names[uid] ?? sheet.tr('عضو سابق')),
                    ),
                    trailing: uid == _me && s.canWrite
                        ? TextButton(
                            onPressed: () {
                              Navigator.pop(sheet);
                              context.read<EventChatCubit>().react(
                                m,
                                r.emoji,
                                _me,
                              );
                            },
                            child: Text(sheet.tr('إزالة')),
                          )
                        : null,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAttachment(EventChatAttachment a) async {
    final url = ApiEndpoints.fileUrl(a.url);
    if (a.isImage) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => _ImageViewer(url: url)));
      return;
    }
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('تعذّر فتح الملف'))));
    }
  }

  // ── البناء ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<EventChatCubit, EventChatState>(
        builder: (context, state) {
          final s = state.summary;
          return Column(
            children: [
              _Header(summary: s, onMembers: () => _showMembers(s)),
              if (s != null) _EventBar(summary: s),
              Expanded(child: _body(state)),
              if (s != null && s.isMember)
                s.canWrite ? _composer(state, s) : _readOnlyBar(context),
            ],
          );
        },
      ),
    );
  }

  Widget _body(EventChatState state) {
    switch (state.status) {
      case EventChatStatus.initial:
      case EventChatStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case EventChatStatus.failure:
        return _centerNote(
          Icons.error_outline,
          state.error ?? context.tr('تعذّر تحميل الدردشة'),
          retry: () => context.read<EventChatCubit>().load(),
        );
      case EventChatStatus.success:
        final s = state.summary!;
        if (!s.isMember) {
          return _centerNote(
            Icons.lock_outline,
            context.tr('الدردشة لأعضاء الحدث فقط'),
          );
        }
        if (state.messages.isEmpty) {
          return _centerNote(
            Icons.forum_outlined,
            s.canWrite
                ? context.tr('ابدأ المحادثة — رسالتك تصل كل أعضاء الحدث')
                : context.tr('لا توجد رسائل'),
          );
        }
        return _messageList(state, s);
    }
  }

  Widget _messageList(EventChatState state, EventChatSummary s) {
    final msgs = state.messages;
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        AppSizes.sm,
      ),
      itemCount: msgs.length + (state.hasOlder ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == msgs.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSizes.md),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final index = msgs.length - 1 - i;
        final m = msgs[index];
        final prev = index > 0 ? msgs[index - 1] : null;
        final newDay = prev == null || !_sameDay(prev.createdAt, m.createdAt);
        // تتابع رسائل الشخص نفسه: الاسم والصورة على الأولى فقط.
        final grouped =
            !newDay &&
            !prev.isSystem &&
            !m.isSystem &&
            prev.senderUserId == m.senderUserId &&
            m.createdAt.difference(prev.createdAt).inMinutes < 5;
        final mine = m.senderUserId == _me;
        return Column(
          children: [
            if (newDay) _DaySeparator(date: m.createdAt),
            if (m.isSystem)
              _SystemLine(text: m.body)
            else
              _SwipeToReply(
                enabled: s.canWrite && !m.isDeleted,
                onReply: () {
                  context.read<EventChatCubit>().startReply(m);
                  _focus.requestFocus();
                },
                child: GestureDetector(
                  onLongPress: () => _onLongPress(m, s),
                  child: ChatMessageBubble(
                    message: m,
                    mine: mine,
                    showHeader: !grouped,
                    me: _me,
                    members: s.members,
                    onOpenAttachment: _openAttachment,
                    onReactionsTap: () => _showReactors(m, s),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _composer(EventChatState state, EventChatSummary s) {
    final quick = [
      context.tr('في الطريق'),
      context.tr('متأخر 10 دقائق'),
      context.tr('من يجيب الكرات؟'),
      context.tr('وصلت الملعب'),
    ];
    final canSend = _input.text.trim().isNotEmpty && !state.sending;
    final query = _mentionQuery?.toLowerCase();
    final suggestions = query == null
        ? const <EventChatMember>[]
        : s.members
              .where(
                (m) => m.userId != _me && m.name.toLowerCase().contains(query),
              )
              .toList();
    final reply = state.replyingTo;

    return Container(
      color: Colors.white,
      padding: context.safeBottom(const EdgeInsets.only(bottom: AppSizes.sm)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.uploading) const LinearProgressIndicator(minHeight: 2),
          // اقتراحات الإشارة عند كتابة @.
          if (suggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg,
                      AppSizes.sm,
                      AppSizes.lg,
                      2,
                    ),
                    child: Text(
                      context.tr('إشارة إلى عضو'),
                      style: AppTextStyles.caption,
                    ),
                  ),
                  for (final m in suggestions)
                    InkWell(
                      onTap: () => _pickMention(m),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg,
                          vertical: AppSizes.sm,
                        ),
                        child: Row(
                          children: [
                            ChatAvatar(
                              name: m.name,
                              url: m.avatarUrl,
                              role: m.role,
                              size: 30,
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Text(
                                m.name,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            if (m.role != 'player')
                              ChatRoleTag(role: m.role, small: true),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // الرسالة المردود عليها.
          if (reply != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md,
                AppSizes.sm,
                AppSizes.md,
                0,
              ),
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 4, 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1FAFC),
                  border: BorderDirectional(
                    start: BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.trArgs('رد على {p0}', {
                              'p0': reply.senderUserId == _me
                                  ? context.tr('نفسك')
                                  : reply.senderName,
                            }),
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF1E9AB0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            chatPreviewText(
                              context,
                              reply.body,
                              reply.attachment?.type,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          context.read<EventChatCubit>().cancelReply(),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (reply == null && suggestions.isEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                itemCount: quick.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
                itemBuilder: (_, i) => ActionChip(
                  label: Text(quick[i]),
                  onPressed: state.sending ? null : () => _send(quick[i]),
                  labelStyle: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF1E9AB0),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCFEFF5)),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: state.sending ? null : _openAttachSheet,
                  tooltip: context.tr('إرفاق'),
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    color: AppColors.mutedForeground,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: context.tr('اكتب رسالة...'),
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                        vertical: AppSizes.md,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      suffixIcon: canSend
                          ? null
                          : IconButton(
                              onPressed: state.sending
                                  ? null
                                  : () => _pickImage(ImageSource.camera),
                              icon: const Icon(
                                Icons.photo_camera_outlined,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Material(
                  color: canSend ? AppColors.primary : AppColors.muted,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: canSend ? _send : null,
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: state.sending
                          ? const Padding(
                              padding: EdgeInsets.all(13),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          // سهم الإرسال يشير لاتجاه الكتابة: يُعكس في العربية.
                          : Transform.flip(
                              flipX:
                                  Directionality.of(context) ==
                                  TextDirection.rtl,
                              child: Icon(
                                Icons.send_rounded,
                                color: canSend
                                    ? Colors.white
                                    : AppColors.mutedForeground,
                                size: 22,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyBar(BuildContext context) => Container(
    width: double.infinity,
    color: Colors.white,
    padding: context.safeBottom(const EdgeInsets.all(AppSizes.lg)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_clock_outlined,
          size: AppSizes.iconSm,
          color: AppColors.mutedForeground,
        ),
        const SizedBox(width: AppSizes.sm),
        Flexible(
          child: Text(
            context.tr('انتهى الحدث — الدردشة للقراءة فقط'),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _centerNote(IconData icon, String text, {VoidCallback? retry}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: AppColors.mutedForeground),
              const SizedBox(height: AppSizes.md),
              Text(
                text,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
              if (retry != null) ...[
                const SizedBox(height: AppSizes.lg),
                OutlinedButton(
                  onPressed: retry,
                  child: Text(context.tr('إعادة المحاولة')),
                ),
              ],
            ],
          ),
        ),
      );

  void _showMembers(EventChatSummary? s) {
    if (s == null || !s.isMember) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      // القائمة قد تطول (بطولة بعشرات اللاعبين): ارتفاع أقصى ثم تمرير داخلي
      // بدل عمود ثابت كان يفيض أسفل الشاشة.
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSizes.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.md,
                AppSizes.lg,
                AppSizes.sm,
              ),
              child: Text(
                sheet.trArgs('أعضاء الدردشة ({p0})', {'p0': s.members.length}),
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg,
                  0,
                  AppSizes.lg,
                  AppSizes.lg,
                ),
                itemCount: s.members.length,
                itemBuilder: (_, i) {
                  final m = s.members[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
                    child: Row(
                      children: [
                        ChatAvatar(
                          name: m.name,
                          url: m.avatarUrl,
                          role: m.role,
                          size: 38,
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Text(
                            m.userId == _me
                                ? '${m.name} (${sheet.tr('أنت')})'
                                : m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        if (m.role != 'player') ChatRoleTag(role: m.role),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── عناصر مساعدة ─────────────────────────────────────────────────────────────

class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    child: Padding(
      padding: const EdgeInsets.all(AppSizes.sm),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: fg, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    ),
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.destructive : AppColors.secondary;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: 12,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(color: color),
              ),
            ),
            Icon(icon, size: 19, color: color),
          ],
        ),
      ),
    );
  }
}

/// سحب الرسالة جانباً للرد عليها — كواتساب.
class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({
    required this.child,
    required this.onReply,
    required this.enabled,
  });

  final Widget child;
  final VoidCallback onReply;
  final bool enabled;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _dx = 0;
  bool _fired = false;
  static const _trigger = 64.0;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        // السحب نحو بداية السطر (يميناً في العربية).
        final delta = rtl ? -d.delta.dx : d.delta.dx;
        setState(() => _dx = (_dx - delta).clamp(0, 90));
        if (!_fired && _dx >= _trigger) {
          _fired = true;
          HapticFeedback.selectionClick();
        }
      },
      onHorizontalDragEnd: (_) {
        if (_fired) widget.onReply();
        setState(() {
          _dx = 0;
          _fired = false;
        });
      },
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          Opacity(
            opacity: (_dx / _trigger).clamp(0, 1),
            child: const Padding(
              padding: EdgeInsetsDirectional.only(start: 6),
              child: Icon(Icons.reply_rounded, color: AppColors.primary),
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: _dx == 0 ? 180 : 0),
            transform: Matrix4.translationValues(rtl ? -_dx : _dx, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// عرض الصورة كاملة مع التكبير.
class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    body: Center(
      child: InteractiveViewer(
        maxScale: 5,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
            size: 64,
          ),
        ),
      ),
    ),
  );
}

// ── الرأس وشريط الحدث ────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.summary, required this.onMembers});

  final EventChatSummary? summary;
  final VoidCallback onMembers;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final shown = s?.members.take(2).toList() ?? const <EventChatMember>[];
    final extra = (s?.members.length ?? 0) - shown.length;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.sm,
            AppSizes.sm,
            AppSizes.sm,
            AppSizes.md,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const DirectionalIcon(
                  rtl: Icons.arrow_forward,
                  ltr: Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              if (shown.isNotEmpty)
                SizedBox(
                  width: 32.0 + (shown.length - 1 + (extra > 0 ? 1 : 0)) * 20,
                  height: 32,
                  child: Stack(
                    children: [
                      for (var i = 0; i < shown.length; i++)
                        PositionedDirectional(
                          start: i * 20.0,
                          child: ChatAvatar(
                            name: shown[i].name,
                            url: shown[i].avatarUrl,
                            role: shown[i].role,
                            size: 32,
                            ring: true,
                          ),
                        ),
                      if (extra > 0)
                        PositionedDirectional(
                          start: shown.length * 20.0,
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.secondary,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '+$extra',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s?.chatTitle ?? context.tr('الدردشة'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    if (s != null && s.isMember)
                      Text(
                        context.trArgs('{p0} أعضاء', {'p0': s.members.length}),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
              ),
              if (s != null && s.isMember)
                IconButton(
                  onPressed: onMembers,
                  tooltip: context.tr('الأعضاء'),
                  icon: const Icon(
                    Icons.people_alt_outlined,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريط الحدث المثبّت: نوعه وملعبه وموعده — الضغط يعيد لصفحة التفاصيل.
class _EventBar extends StatelessWidget {
  const _EventBar({required this.summary});

  final EventChatSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final when =
        '${AppDates.weekday(s.scheduledAt)} ${AppDates.dayMonth(s.scheduledAt)} · ${AppDates.time12(s.scheduledAt)}';
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.sm + 2,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  [
                    s.title,
                    if (s.venueName != null) s.venueName!,
                    when,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const DirectionalIcon(
                rtl: Icons.chevron_left,
                ltr: Icons.chevron_right,
                size: 18,
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = ksaNow();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    final label = diff == 0
        ? context.tr('اليوم')
        : diff == 1
        ? context.tr('أمس')
        : '${AppDates.weekday(date)} ${AppDates.dayMonth(date)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
        ),
      ),
    );
  }
}

class _SystemLine extends StatelessWidget {
  const _SystemLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.xs + 2),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(
          fontSize: 11.5,
          color: AppColors.mutedForeground,
        ),
      ),
    ),
  );
}
