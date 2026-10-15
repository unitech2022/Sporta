import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../state/app_scope.dart';
import '../storage/local_prefs.dart';
import '../utils/server_time.dart';

/// يفتح شاشة «موعد جديد» في تقويم الهاتف معبّأة بالحجز/المباراة، فيكفي أن
/// يضغط المستخدم «إضافة». [startKsa] بتوقيت السعودية بلا منطقة زمنية (كما
/// يرسله الخادم — AppClock)، فيُحوَّل إلى لحظة مطلقة كي يظهر الموعد صحيحاً حتى
/// لو كان الهاتف على منطقة زمنية أخرى. تذكير قبل ساعة.
/// النتيجة: أُضيف، أو ألغاه المستخدم، أو تعذّر (إذن مرفوض/لا تقويم).
enum CalendarAddResult { added, cancelled, failed }

Future<CalendarAddResult> addToPhoneCalendar({
  required String title,
  required DateTime startKsa,
  required int durationMinutes,
  String? location,
  String? description,
}) async {
  if (kIsWeb) return CalendarAddResult.failed;
  final start = DateTime.utc(
    startKsa.year,
    startKsa.month,
    startKsa.day,
    startKsa.hour,
    startKsa.minute,
  ).subtract(ksaUtcOffset);
  final end = start.add(Duration(minutes: durationMinutes));
  try {
    // iOS: قناة أصلية (CalendarBridge.swift) — عرض add_2_calendar لا يظهر في
    // تطبيقات المشاهد. أندرويد: add_2_calendar (شاشة «حدث جديد» في التقويم).
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final saved =
          await _iosChannel.invokeMethod<bool>('addEvent', {
            'title': title,
            'description': description,
            'location': location,
            'start': start.millisecondsSinceEpoch,
            'end': end.millisecondsSinceEpoch,
            'alarmMinutes': 60,
          }) ??
          false;
      return saved ? CalendarAddResult.added : CalendarAddResult.cancelled;
    }
    final launched = await Add2Calendar.addEvent2Cal(
      Event(
        title: title,
        description: description,
        location: location,
        startDate: start.toLocal(),
        endDate: end.toLocal(),
      ),
    );
    // أندرويد يُسلّم الموعد لتطبيق التقويم ولا يُبلغنا بالحفظ — نعتبر فتحه
    // إضافةً (المستخدم ضغط «أضف» بنفسه).
    return launched ? CalendarAddResult.added : CalendarAddResult.failed;
  } catch (_) {
    return CalendarAddResult.failed;
  }
}

const _iosChannel = MethodChannel('sporta/calendar');

/// زرّ «أضف إلى التقويم» بنمطين: كامل العرض (صفحة التفاصيل) أو مدمج (بطاقة).
/// بعد الإضافة يصير «مضاف إلى التقويم ✓» غير قابل للضغط — يُحفظ ذلك محلياً
/// بمفتاح [calendarKey] + وقت الموعد، فلو تغيّر الموعد عاد الزر للإضافة.
class AddToCalendarButton extends StatefulWidget {
  const AddToCalendarButton({
    super.key,
    required this.calendarKey,
    required this.title,
    required this.startKsa,
    required this.durationMinutes,
    this.location,
    this.description,
    this.compact = false,
  });

  /// معرّف ثابت للموعد، مثل `booking-54`.
  final String calendarKey;
  final String title;
  final DateTime startKsa;
  final int durationMinutes;
  final String? location;
  final String? description;
  final bool compact;

  @override
  State<AddToCalendarButton> createState() => _AddToCalendarButtonState();
}

class _AddToCalendarButtonState extends State<AddToCalendarButton> {
  String get _key =>
      '${widget.calendarKey}@${widget.startKsa.toIso8601String()}';

  late bool _added = LocalPrefs.isCalendarAdded(_key);
  bool _busy = false;

  @override
  void didUpdateWidget(covariant AddToCalendarButton old) {
    super.didUpdateWidget(old);
    if (old.calendarKey != widget.calendarKey ||
        old.startKsa != widget.startKsa) {
      _added = LocalPrefs.isCalendarAdded(_key);
    }
  }

  Future<void> _add() async {
    if (_added || _busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final addedText = context.tr('أُضيف الموعد إلى تقويمك');
    final failed = context.tr(
      'تعذّر فتح التقويم — تحقّق من إذن التقويم في الإعدادات',
    );
    setState(() => _busy = true);
    final result = await addToPhoneCalendar(
      title: widget.title,
      startKsa: widget.startKsa,
      durationMinutes: widget.durationMinutes,
      location: widget.location,
      description: widget.description,
    );
    if (result == CalendarAddResult.added) {
      await LocalPrefs.markCalendarAdded(_key);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _added = result == CalendarAddResult.added;
    });
    switch (result) {
      case CalendarAddResult.added:
        messenger.showSnackBar(SnackBar(content: Text(addedText)));
      case CalendarAddResult.failed:
        messenger.showSnackBar(SnackBar(content: Text(failed)));
      case CalendarAddResult.cancelled:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _added ? AppColors.success : AppColors.primary;
    final label = Text(
      context.tr(_added ? 'مضاف إلى التقويم' : 'أضف إلى التقويم'),
    );
    final icon = Icon(
      _added ? Icons.event_available : Icons.calendar_month_outlined,
      size: 20,
    );
    final onPressed = _added || _busy ? null : _add;

    if (widget.compact) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: label,
        style: TextButton.styleFrom(
          foregroundColor: color,
          disabledForegroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
          visualDensity: VisualDensity.compact,
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: label,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          disabledForegroundColor: color,
          backgroundColor: _added
              ? AppColors.success.withValues(alpha: 0.08)
              : null,
          side: BorderSide(color: color.withValues(alpha: _added ? 0.5 : 1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
        ),
      ),
    );
  }
}
