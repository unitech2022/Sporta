// Arabic labels for the enum keys the admin API returns on an account.
// Keep the keys in sync with SportaApis/DTOs/AdminDtos.cs (AdminUserDetailDto).

export const roleLabels = {
  player: 'لاعب',
  coach: 'مدرب',
  venue: 'ملعب',
  admin: 'مشرف',
  staff: 'موظف',
};

export const genderLabels = { male: 'ذكر', female: 'أنثى' };

export const languageLabels = { ar: 'العربية', en: 'الإنجليزية' };

/** PlayerLevel 1..7 (SportaApis/Enums/PlayerLevel.cs). */
export const playerLevelLabels = {
  1: 'مبتدئ',
  2: 'ناشئ',
  3: 'متعلم',
  4: 'متوسط',
  5: 'متقدم',
  6: 'محترف',
  7: 'نخبة',
};

export const handLabels = { right: 'يمين', left: 'يسار' };

export const positionLabels = { right: 'يمين', left: 'يسار', both: 'كلاهما' };

export const matchTypeLabels = {
  open: 'مفتوحة',
  social: 'اجتماعية',
  training: 'تدريبية',
  competitive: 'تنافسية',
  american: 'أمريكانو فردي',
  americanteam: 'أمريكانو تيم',
  event: 'حدث / بطولة',
  lesson: 'درس تدريبي',
};

export const playTimeLabels = {
  morning: 'صباحاً',
  afternoon: 'ظهراً',
  evening: 'مساءً',
  any: 'لا فرق',
};

export const experienceLabels = {
  lessThanYear: 'أقل من سنة',
  oneToThree: '1 - 3 سنوات',
  threeToFive: '3 - 5 سنوات',
  moreThanFive: 'أكثر من 5 سنوات',
};

export const residencyLabels = { saudi: 'سعودي', resident: 'مقيم' };

export const dayLabels = {
  sat: 'السبت', sun: 'الأحد', mon: 'الإثنين', tue: 'الثلاثاء',
  wed: 'الأربعاء', thu: 'الخميس', fri: 'الجمعة',
};

export const planLabels = { free: 'مجاني', sportaPlus: 'Sporta Plus' };

// ── حالات السجلات (تصل بأسماء الـ enum كما هي: PascalCase) ──────────────────

export const bookingStatusLabels = {
  Pending: 'معلق', Confirmed: 'مؤكد', Cancelled: 'ملغي', Completed: 'مكتمل',
};

export const matchStatusLabels = {
  Open: 'مفتوحة', Full: 'مكتملة العدد', InProgress: 'جارية',
  Completed: 'منتهية', Cancelled: 'ملغاة', PendingApproval: 'بانتظار الموافقة',
};

export const sessionStatusLabels = {
  Pending: 'بانتظار الموافقة', Confirmed: 'مؤكدة', Rejected: 'مرفوضة',
};

export const matchTypeNameLabels = {
  Open: 'مفتوحة', Social: 'اجتماعية', Training: 'تدريبية', Competitive: 'تنافسية',
  American: 'أمريكانو فردي', AmericanTeam: 'أمريكانو تيم', Event: 'حدث / بطولة',
  Lesson: 'درس تدريبي',
};

export const walletTypeLabels = {
  Deposit: 'إيداع', Refund: 'استرداد', MatchPayment: 'دفع مباراة',
  BookingPayment: 'دفع حجز', CoachPayment: 'دفع جلسة مدرب', Reward: 'مكافأة',
  Subscription: 'اشتراك', Withdrawal: 'سحب رصيد', CoachEarning: 'أرباح مدرب',
  VenueEarning: 'أرباح نادي', CreatorEarning: 'استرداد منشئ مباراة',
  PointsRedemption: 'استبدال نقاط',
};

/** يربط حالة السجل بألوان StatusBadge الجاهزة. */
export const badgeFor = {
  Pending: 'pending', Confirmed: 'active', Cancelled: 'overdue', Completed: 'completed',
  Open: 'upcoming', Full: 'upcoming', InProgress: 'pending', PendingApproval: 'pending',
  Rejected: 'overdue', Failed: 'overdue',
};

/** Loyalty-points transaction types (GET /admin/users/{id}/points). */
export const pointsTypeLabels = {
  BookingConfirmed: 'حجز ملعب',
  MatchCompleted: 'إتمام مباراة',
  CoachSessionConfirmed: 'جلسة مدرب',
  SubscriptionBonus: 'نقاط ترحيبية',
  ProfileBonus: 'مكافأة الملف',
  Redeemed: 'استبدال برصيد',
  AdminAdjustment: 'تعديل إداري',
  Reversal: 'عكس نقاط',
  WithdrawalPenalty: 'خصم انسحاب',
};

/** Formats an ISO date as an Arabic day/month/year, or an em dash when unset. */
export function formatDate(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleDateString('ar', { year: 'numeric', month: 'long', day: 'numeric' });
}

/** Same as formatDate but with the time of day appended. */
export function formatDateTime(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return `${d.toLocaleDateString('ar')} · ${d.toLocaleTimeString('ar', { hour: '2-digit', minute: '2-digit' })}`;
}

export const money = (v) => `${Number(v ?? 0).toFixed(2)} ر.س`;
