/// Parses an audit timestamp (CreatedAt / UpdatedAt / JoinedAt / ProcessedAt…)
/// that the server sets from `DateTime.UtcNow`.
///
/// EF reads those columns back with Kind=Unspecified, so the API sends them
/// without a trailing `Z` and `DateTime.tryParse` would treat them as device
/// local time — every «منذ …» label came out 3 hours old on a KSA device.
/// An unmarked value is therefore taken as UTC, then converted to local.
///
/// Do NOT use this for event times (scheduledAt, endDate, expiresAt,
/// startTime…): those are naive KSA local time by design (AppClock).
DateTime? parseServerUtc(Object? raw) {
  final s = raw?.toString() ?? '';
  if (s.isEmpty) return null;
  final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);
  return DateTime.tryParse(hasZone ? s : '${s}Z')?.toLocal();
}

/// KSA (Asia/Riyadh) is UTC+3 all year — no daylight saving.
const Duration ksaUtcOffset = Duration(hours: 3);

/// The current wall-clock time in Saudi Arabia, as a naive *local* [DateTime].
///
/// Event times (scheduledAt, startTime, endDate, expiresAt…) are naive KSA
/// local time (server AppClock) and `DateTime.tryParse` turns such a string
/// into a local DateTime carrying those same wall-clock values. Comparing them
/// with `DateTime.now()` is only right on a device set to KSA time; compare
/// with this instead so "started / ended / upcoming" and countdowns are
/// correct on any device time zone.
///
/// Also use it for "today" in date pickers and day lists for KSA venues.
/// (Converting an event time to a real instant — e.g. add-to-calendar — is the
/// inverse: treat the wall-clock as UTC and subtract [ksaUtcOffset].)
DateTime ksaNow() {
  final k = DateTime.now().toUtc().add(ksaUtcOffset);
  return DateTime(
    k.year,
    k.month,
    k.day,
    k.hour,
    k.minute,
    k.second,
    k.millisecond,
    k.microsecond,
  );
}

/// Today's date (midnight) in Saudi Arabia, as a naive local [DateTime].
DateTime ksaToday() {
  final n = ksaNow();
  return DateTime(n.year, n.month, n.day);
}
